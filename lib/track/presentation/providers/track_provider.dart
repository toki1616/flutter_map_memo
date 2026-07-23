import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../folder/presentation/providers/folder_provider.dart';
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

    // 一覧は全ログを保持する。地図表示時の期間フィルタは MapScreen が適用する。
    return ref
        .read(loadAllTracksUseCaseProvider)
        .call(TrackRootPathParams(folder.path));
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

/// 一覧画面でチェックされたトラック ID。
/// 削除や「地図に表示」の操作対象としてアプリ起動中は保持する。
class TrackListSelectionNotifier extends StateNotifier<Set<String>> {
  TrackListSelectionNotifier() : super({});

  void setSelected(String id, bool selected) {
    final updated = {...state};
    if (selected) {
      updated.add(id);
    } else {
      updated.remove(id);
    }
    state = updated;
  }

  void clear() => state = {};

  void removeIds(Iterable<String> ids) {
    state = {...state}..removeAll(ids);
  }
}

final trackListSelectionProvider =
    StateNotifierProvider<TrackListSelectionNotifier, Set<String>>((ref) {
      final notifier = TrackListSelectionNotifier();
      // データセット切替後に、前フォルダのログ ID を選択対象として残さない。
      ref.listen(folderProvider, (_, __) => notifier.clear());
      return notifier;
    });

/// 地図のトラック表示条件。
///
/// [settingsPeriod] は設定の表示期間に従い、[selectedOnly] は一覧で明示的に
/// 「地図に表示」したログだけを表示する。一覧のチェック状態とは独立させる。
enum TrackMapFilterMode { settingsPeriod, selectedOnly }

class TrackMapFilter {
  final TrackMapFilterMode mode;
  final Set<String> selectedIds;

  const TrackMapFilter.settingsPeriod()
    : mode = TrackMapFilterMode.settingsPeriod,
      selectedIds = const {};

  const TrackMapFilter.selectedOnly(Set<String> ids)
    : mode = TrackMapFilterMode.selectedOnly,
      selectedIds = ids;
}

class TrackMapFilterNotifier extends StateNotifier<TrackMapFilter> {
  TrackMapFilterNotifier() : super(const TrackMapFilter.settingsPeriod());

  void showSettingsPeriod() => state = const TrackMapFilter.settingsPeriod();

  void showSelected(Iterable<String> ids) {
    final selectedIds = ids.toSet();
    state = selectedIds.isEmpty
        ? const TrackMapFilter.settingsPeriod()
        : TrackMapFilter.selectedOnly(selectedIds);
  }

  void removeDeletedIds(Iterable<String> ids) {
    if (state.mode != TrackMapFilterMode.selectedOnly) return;
    final remaining = {...state.selectedIds}..removeAll(ids);
    showSelected(remaining);
  }
}

final trackMapFilterProvider =
    StateNotifierProvider<TrackMapFilterNotifier, TrackMapFilter>((ref) {
      final notifier = TrackMapFilterNotifier();
      // データセット切替後は、前フォルダの選択ログではなく期間設定表示へ戻す。
      ref.listen(folderProvider, (_, __) => notifier.showSettingsPeriod());
      return notifier;
    });
