import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/usecases/usecase.dart';
import '../../../setting/presentation/providers/setting_storage_provider.dart';
import '../../data/datasources/folder_local_datasource.dart';
import '../../data/repositories/folder_repository_impl.dart';
import '../../domain/entities/folder_selection.dart';
import '../../domain/repositories/folder_repository.dart';
import '../../domain/usecases/folder_usecases.dart';

// ── DI ───────────────────────────────────────────────────────────────────

final folderLocalDataSourceProvider = Provider<FolderLocalDataSource>((ref) {
  // settings.json への書き込み・削除を settingStorageProvider 経由で行う
  return createFolderLocalDataSource(
    onPathSaved: (path) async {
      await ref.read(settingStorageProvider.notifier).saveFolderPath(path);
    },
    onPathCleared: () async {
      await ref.read(settingStorageProvider.notifier).clearFolderPath();
    },
  );
});

final folderRepositoryProvider = Provider<FolderRepository>(
  (ref) => FolderRepositoryImpl(ref.watch(folderLocalDataSourceProvider)),
);

final pickFolderUseCaseProvider = Provider(
  (ref) => PickFolderUseCase(ref.watch(folderRepositoryProvider)),
);
final loadSavedFolderUseCaseProvider = Provider(
  (ref) => LoadSavedFolderUseCase(ref.watch(folderRepositoryProvider)),
);
final clearFolderUseCaseProvider = Provider(
  (ref) => ClearFolderUseCase(ref.watch(folderRepositoryProvider)),
);

// ── State ─────────────────────────────────────────────────────────────────

/// 選択中フォルダの状態を管理する AsyncNotifier
///
/// 起動時の復元フロー:
///   iOS    : IosDirectoryService.restoreDirectoryAccess()
///            → ブックマークからアクセス権を取得 → 最新パスを返す
///   Android: settingStorageProvider の folderPath を読み出す
///            → そのパスが実在すれば FolderSelection を組み立てる
class FolderNotifier extends AsyncNotifier<FolderSelection?> {
  @override
  Future<FolderSelection?> build() async {
    // settingStorageProvider のロードが完了するまで待つ
    final settings = await ref.watch(settingStorageProvider.future);

    // Android は settings.json の folderPath を savedPath として渡す
    // iOS は null を渡す（内部でブックマーク復元が走る）
    return ref
        .read(loadSavedFolderUseCaseProvider)
        .call(const NoParams(), savedPath: settings.folderPath);
  }

  /// OS 標準ダイアログでフォルダを選択する
  /// 選択後は自動的に settings.json に保存される
  Future<void> pickFolder() async {
    state = const AsyncLoading();
    try {
      final result = await ref
          .read(pickFolderUseCaseProvider)
          .call(const NoParams());
      state = AsyncData(result);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// フォルダ選択をリセットする
  Future<void> clear() async {
    await ref.read(clearFolderUseCaseProvider).call(const NoParams());
    state = const AsyncData(null);
  }
}

final folderProvider =
    AsyncNotifierProvider<FolderNotifier, FolderSelection?>(FolderNotifier.new);
