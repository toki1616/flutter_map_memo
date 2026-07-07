import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../folder/presentation/providers/folder_provider.dart';
import '../../../location/presentation/providers/location_provider.dart';
import '../../../pin/presentation/providers/pin_provider.dart';
import '../../domain/entities/map_fab_state.dart';
import '../../domain/usecases/add_pin_from_center_usecase.dart';

// ── DI ───────────────────────────────────────────────────────────────────

/// AddPinFromCenterUseCase の DI
/// pinRepositoryProvider は pin_provider.dart で定義済み
/// folderRepositoryProvider は folder_provider.dart で定義済み
final addPinFromCenterUseCaseProvider =
    Provider<AddPinFromCenterUseCase>((ref) {
  return AddPinFromCenterUseCase(
    pinRepository: ref.watch(pinRepositoryProvider),
    folderRepository: ref.watch(folderRepositoryProvider),
  );
});

// ── Notifier ──────────────────────────────────────────────────────────────

/// マップ画面のFABボタン群の状態を一元管理する Notifier
///
/// 他 feature（folder / location / pin）への依存をここに集約することで、
/// UI 層（MapFabButtons）は mapFabProvider だけを watch すればよい設計にする。
///
/// 責務:
///   - folderProvider を監視してフォルダ選択状態を同期する
///   - locationStreamProvider を監視して現在地を同期する
///   - ピン追加モード / 追従モードの ON/OFF を管理する
///   - ピン追加の実行（AddPinFromCenterUseCase を呼ぶ）
///
/// 【重要】build() 内では state を参照しない
///   Notifier.build() の初回実行時は state が未初期化のため
///   state を参照すると LateInitializationError になる。
///   isPinAddMode / isFollowingLocation は内部変数で管理し、
///   build() は外部 Provider の値のみで状態を組み立てる。
class MapFabNotifier extends Notifier<MapFabState> {
  // build() の再実行をまたいでモードを保持する内部変数
  bool _isPinAddMode = false;
  bool _isFollowingLocation = false;

  @override
  MapFabState build() {
    // folderProvider を監視してフォルダ選択状態を同期
    final folder = ref.watch(folderProvider).valueOrNull;

    // locationStreamProvider を監視して現在地を同期
    final locationAsync = ref.watch(locationStreamProvider);
    final loc = locationAsync.valueOrNull;
    final currentLatLng =
        loc != null ? LatLng(loc.latitude, loc.longitude) : null;

    // 現在地が取得できなくなった場合は追従モードを自動 OFF
    if (currentLatLng == null) {
      _isFollowingLocation = false;
    }

    // state を参照せず内部変数から状態を組み立てる
    return MapFabState(
      isFolderSelected: folder != null,
      currentLocation: currentLatLng,
      isPinAddMode: _isPinAddMode,
      isFollowingLocation: _isFollowingLocation,
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

  /// マップ中央座標にピンを追加する
  /// 追加後は pinProvider を invalidate して一覧を最新化する
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

  /// 手動ドラッグを検知した時に呼ぶ（map_screen.dart の onPositionChanged から）
  void stopFollowingIfNeeded(bool hasGesture) {
    if (hasGesture && state.isFollowingLocation) {
      disableFollowing();
    }
  }
}

final mapFabProvider = NotifierProvider<MapFabNotifier, MapFabState>(() {
  return MapFabNotifier();
});

// ── 追従時の移動先座標を map_screen.dart へ伝える Provider ────────────────

/// 追従モードが ON かつ現在地がある場合に LatLng を emit する
/// map_screen.dart がこれを listen して mapController.move() を呼ぶ
final followLocationTargetProvider = Provider<LatLng?>((ref) {
  final fabState = ref.watch(mapFabProvider);
  if (!fabState.isFollowingLocation) return null;
  return fabState.currentLocation;
});
