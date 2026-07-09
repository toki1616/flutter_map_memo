import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../folder/presentation/providers/folder_provider.dart';
import '../../../location/domain/entities/location_data.dart';
import '../../../location/presentation/providers/location_provider.dart';
import '../../../pin/presentation/providers/pin_provider.dart';
import '../../../setting/presentation/providers/setting_storage_provider.dart';
import '../../../track/domain/entities/track_log.dart';
import '../../../track/domain/usecases/track_usecases.dart';
import '../../../track/presentation/providers/track_provider.dart';
import '../../domain/entities/map_fab_state.dart';
import '../../domain/usecases/add_pin_from_center_usecase.dart';

// ── DI ───────────────────────────────────────────────────────────────────

final addPinFromCenterUseCaseProvider = Provider<AddPinFromCenterUseCase>(
  (ref) => AddPinFromCenterUseCase(
    pinRepository: ref.watch(pinRepositoryProvider),
    folderRepository: ref.watch(folderRepositoryProvider),
  ),
);

// ── Notifier ──────────────────────────────────────────────────────────────

/// マップ画面のFABボタン群の状態を一元管理する Notifier
///
/// トラック記録の責務:
///   - 記録開始: _currentTrackLog を生成してファイルに初回保存
///   - ポイント追加: GPS 更新のたびに _currentTrackLog を更新してファイルに即時保存
///     （タスクキル対策: 毎回ファイルに書き込む）
///   - 記録停止: endedAt をセットして最終保存し _currentTrackLog をクリア
class MapFabNotifier extends Notifier<MapFabState> {
  bool _isPinAddMode = false;
  bool _isFollowingLocation = false;
  bool _isTracking = false;

  /// 現在記録中のトラックログ（記録中のみ非 null）
  TrackLog? _currentTrackLog;

  @override
  MapFabState build() {
    final folder = ref.watch(folderProvider).valueOrNull;
    final locationAsync = ref.watch(locationStreamProvider);
    final loc = locationAsync.valueOrNull;
    final currentLatLng =
        loc != null ? LatLng(loc.latitude, loc.longitude) : null;

    if (currentLatLng == null) {
      _isFollowingLocation = false;
    }

    // GPS 更新時にトラックポイントを追加して即時保存
    if (_isTracking && loc != null && folder != null) {
      _appendTrackPoint(loc, folder.path);
    }

    return MapFabState(
      isFolderSelected: folder != null,
      currentLocation: currentLatLng,
      isPinAddMode: _isPinAddMode,
      isFollowingLocation: _isFollowingLocation,
      isTracking: _isTracking,
    );
  }

  // ── ピン追加モード ─────────────────────────────────────────────────────

  void enablePinAddMode() {
    _isPinAddMode = true;
    state = state.copyWith(isPinAddMode: true);
  }

  void disablePinAddMode() {
    _isPinAddMode = false;
    state = state.copyWith(isPinAddMode: false);
  }

  Future<void> addPinAtCenter({
    required LatLng position,
    required String title,
    String memo = '',
    String colorHex = '#E63946',
  }) async {
    await ref.read(addPinFromCenterUseCaseProvider).call(
          AddPinFromCenterParams(
            position: position,
            title: title,
            memo: memo,
            colorHex: colorHex,
          ),
        );
    ref.invalidate(pinProvider);
    disablePinAddMode();
  }

  // ── 現在地追従モード ───────────────────────────────────────────────────

  void enableFollowing() {
    _isFollowingLocation = true;
    state = state.copyWith(isFollowingLocation: true);
  }

  void disableFollowing() {
    _isFollowingLocation = false;
    state = state.copyWith(isFollowingLocation: false);
  }

  void stopFollowingIfNeeded(bool hasGesture) {
    if (hasGesture && state.isFollowingLocation) disableFollowing();
  }

  // ── トラック記録 ───────────────────────────────────────────────────────

  /// 記録を開始する
  /// セッション開始時刻から id を生成してファイルに初回保存する
  Future<void> startTracking() async {
    final folder = ref.read(folderProvider).valueOrNull;
    if (folder == null) return;

    final now = DateTime.now();
    final id = generateTrackId(now);
    _currentTrackLog = TrackLog(
      id: id,
      startedAt: now,
      points: const [],
    );

    // 初回保存（空ポイントでもファイルを作る）
    await ref.read(saveTrackUseCaseProvider).call(
          SaveTrackParams(rootPath: folder.path, log: _currentTrackLog!),
        );

    _isTracking = true;
    state = state.copyWith(isTracking: true);

    // 一覧を再読み込み
    ref.read(trackListProvider.notifier).reload();
  }

  /// 記録を停止する
  Future<void> stopTracking() async {
    if (_currentTrackLog == null) return;
    final folder = ref.read(folderProvider).valueOrNull;
    if (folder == null) return;

    final finished = _currentTrackLog!.copyWith(endedAt: DateTime.now());
    await ref.read(saveTrackUseCaseProvider).call(
          SaveTrackParams(rootPath: folder.path, log: finished),
        );

    _currentTrackLog = null;
    _isTracking = false;
    state = state.copyWith(isTracking: false);

    ref.read(trackListProvider.notifier).reload();
  }

  /// GPS 更新のたびにポイントを追記してファイルに即時保存する
  /// build() から呼ばれる（GPS 更新ごとに build が再実行される）
  void _appendTrackPoint(LocationData loc, String rootPath) async {
    if (_currentTrackLog == null) return;

    // 設定の記録間隔を確認
    final settings = ref.read(settingStorageProvider).valueOrNull;
    final intervalSec = settings?.trackIntervalSeconds ?? 10;

    final points = _currentTrackLog!.points;
    if (points.isNotEmpty) {
      final lastTime = points.last.timestamp;
      final elapsed = DateTime.now().difference(lastTime).inSeconds;
      if (elapsed < intervalSec) return; // 間隔未満なら追加しない
    }

    final newPoint = TrackPoint(
      latitude: loc.latitude,
      longitude: loc.longitude,
      accuracy: loc.accuracy,
      timestamp: DateTime.now(),
    );

    _currentTrackLog = _currentTrackLog!.copyWith(
      points: [..._currentTrackLog!.points, newPoint],
    );

    // タスクキル対策: ポイント追加のたびにファイルへ即時書き込み
    await ref.read(saveTrackUseCaseProvider).call(
          SaveTrackParams(rootPath: rootPath, log: _currentTrackLog!),
        );
  }

  /// 現在記録中のトラックログを返す（map_screen でのリアルタイム表示用）
  TrackLog? get currentTrackLog => _currentTrackLog;
}

final mapFabProvider = NotifierProvider<MapFabNotifier, MapFabState>(() {
  return MapFabNotifier();
});

// ── 追従時の移動先 Provider ───────────────────────────────────────────────

final followLocationTargetProvider = Provider<LatLng?>((ref) {
  final fabState = ref.watch(mapFabProvider);
  if (!fabState.isFollowingLocation) return null;
  return fabState.currentLocation;
});
