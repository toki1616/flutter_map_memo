import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../folder/presentation/providers/folder_provider.dart';
import '../../../setting/presentation/providers/setting_storage_provider.dart';
import '../../data/datasources/track_local_datasource.dart';
import '../../data/repositories/track_repository_impl.dart';
import '../../domain/entities/track_log.dart';
import '../../domain/repositories/track_repository.dart';
import '../../domain/usecases/track_usecases.dart';

// ── DI ───────────────────────────────────────────────────────────────────

final trackLocalDataSourceProvider = Provider<TrackLocalDataSource>(
  (ref) => TrackLocalDataSourceImpl(),
);

final trackRepositoryProvider = Provider<TrackRepository>(
  (ref) => TrackRepositoryImpl(ref.watch(trackLocalDataSourceProvider)),
);

final loadAllTracksUseCaseProvider = Provider(
  (ref) => LoadAllTracksUseCase(ref.watch(trackRepositoryProvider)),
);
final saveTrackUseCaseProvider = Provider(
  (ref) => SaveTrackUseCase(ref.watch(trackRepositoryProvider)),
);
final deleteTrackUseCaseProvider = Provider(
  (ref) => DeleteTrackUseCase(ref.watch(trackRepositoryProvider)),
);
// 機能: 指定日数より古いログを削除する UseCase を DI する。
// 状態: 自動削除を停止中のため未使用。
// final deleteOldTracksUseCaseProvider = Provider(
//   (ref) => DeleteOldTracksUseCase(ref.watch(trackRepositoryProvider)),
// );

// ── 保存済みトラックログ一覧 ───────────────────────────────────────────────

class TrackListNotifier extends AsyncNotifier<List<TrackLog>> {
  @override
  Future<List<TrackLog>> build() async {
    final folder = ref.watch(folderProvider).valueOrNull;
    if (folder == null) return [];

    // 設定の表示期間フィルタを適用して読み込む
    final settings = ref.watch(settingStorageProvider).valueOrNull;
    final displayDays = settings?.trackDisplayDays;

    final logs = await ref
        .read(loadAllTracksUseCaseProvider)
        .call(TrackRootPathParams(folder.path));

    if (displayDays == null || displayDays <= 0) return logs;

    final threshold = DateTime.now().subtract(Duration(days: displayDays));
    return logs.where((l) => l.startedAt.isAfter(threshold)).toList();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    final folder = ref.read(folderProvider).valueOrNull;
    if (folder == null) {
      state = const AsyncData([]);
      return;
    }
    final logs = await ref
        .read(loadAllTracksUseCaseProvider)
        .call(TrackRootPathParams(folder.path));
    state = AsyncData(logs);
  }

  Future<void> deleteTrack(String id) async {
    final folder = ref.read(folderProvider).valueOrNull;
    if (folder == null) return;
    await ref
        .read(deleteTrackUseCaseProvider)
        .call(DeleteTrackParams(rootPath: folder.path, id: id));
    state = AsyncData(
      (state.valueOrNull ?? []).where((l) => l.id != id).toList(),
    );
  }

  // 機能: 設定の日数より古いログを削除して、一覧を再読み込みする。
  // 状態: 自動削除を停止中。ログは一覧画面でユーザーが明示的に削除する。
  // Future<void> deleteOldLogs() async {
  //   final folder = ref.read(folderProvider).valueOrNull;
  //   if (folder == null) return;
  //   final settings = ref.read(settingStorageProvider).valueOrNull;
  //   final days = settings?.trackRetentionDays;
  //   if (days == null || days <= 0) return;
  //   await ref
  //       .read(deleteOldTracksUseCaseProvider)
  //       .call(DeleteOldTracksParams(rootPath: folder.path, days: days));
  //   await reload();
  // }
}

final trackListProvider =
    AsyncNotifierProvider<TrackListNotifier, List<TrackLog>>(
      TrackListNotifier.new,
    );

/// 地図に表示するトラックを管理する。
///
/// null の間は従来どおり全トラックを表示し、一覧画面から「地図に表示」を
/// 実行した後は、指定された ID のトラックだけを表示する。
class TrackMapDisplayNotifier extends StateNotifier<Set<String>?> {
  TrackMapDisplayNotifier() : super(null);

  void showOnly(Iterable<String> ids) {
    state = ids.toSet();
  }

  void removeIds(Iterable<String> ids) {
    if (state == null) return;
    final updated = {...state!}..removeAll(ids);
    state = updated;
  }
}

final trackMapDisplayProvider =
    StateNotifierProvider<TrackMapDisplayNotifier, Set<String>?>(
      (ref) => TrackMapDisplayNotifier(),
    );
