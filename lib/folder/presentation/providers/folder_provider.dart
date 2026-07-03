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
/// 【iOS ローディング無限ループの原因と対策】
///
/// 問題:
///   build() が ref.watch(settingStorageProvider.future) を使っていると、
///   pickFolder() → onPathResolved → saveFolderPath() → settingStorageProvider 更新
///   → build() 再実行 → AsyncLoading に戻る → 永遠にローディング
///
/// 対策:
///   build() では ref.watch ではなく ref.read で settingStorageProvider を
///   一度だけ読み、その後は watch しない。
///   これにより settingStorageProvider が更新されても build() が再実行されない。
class FolderNotifier extends AsyncNotifier<FolderSelection?> {
  @override
  Future<FolderSelection?> build() async {
    // ⚠️ ref.watch ではなく ref.read を使う
    // watch にすると saveFolderPath() 後に build() が再実行されて
    // AsyncLoading ループが発生するため
    final settings = await ref.read(settingStorageProvider.future);

    return ref
        .read(loadSavedFolderUseCaseProvider)
        .call(const NoParams(), savedPath: settings.folderPath);
  }

  /// OS 標準ダイアログでフォルダを選択する
  ///
  /// iOS の場合:
  ///   AppDelegate.swift → UIDocumentPickerViewController を表示
  ///   → 選択後ブックマーク保存 → パス取得 → onPathResolved → saveFolderPath()
  ///   → settingStorageProvider 更新
  ///   ※ build() は ref.read を使っているため再実行されず
  ///      ここで state = AsyncData(result) を明示的にセットして完了させる
  Future<void> pickFolder() async {
    state = const AsyncLoading();
    try {
      final result = await ref
          .read(pickFolderUseCaseProvider)
          .call(const NoParams());
      // キャンセル時は null → AsyncData(null) にして Loading を解除する
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
