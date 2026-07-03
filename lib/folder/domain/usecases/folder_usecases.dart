import '../../../core/usecases/usecase.dart';
import '../entities/folder_selection.dart';
import '../repositories/folder_repository.dart';

/// OS 標準ダイアログでフォルダを選択し、settings.json に保存するユースケース
class PickFolderUseCase implements UseCase<FolderSelection?, NoParams> {
  final FolderRepository _repository;
  PickFolderUseCase(this._repository);

  @override
  Future<FolderSelection?> call(NoParams params) {
    return _repository.pickFolder();
  }
}

/// 前回のフォルダ選択を復元するユースケース
/// [savedPath] : settings.json から読み出したパス（Android 用）
///               iOS は null を渡す（ブックマーク復元が内部で走る）
class LoadSavedFolderUseCase implements UseCase<FolderSelection?, NoParams> {
  final FolderRepository _repository;
  LoadSavedFolderUseCase(this._repository);

  @override
  Future<FolderSelection?> call(NoParams params, {String? savedPath}) {
    return _repository.loadSavedFolder(savedPath: savedPath);
  }
}

/// フォルダ選択をリセットするユースケース
class ClearFolderUseCase implements UseCase<void, NoParams> {
  final FolderRepository _repository;
  ClearFolderUseCase(this._repository);

  @override
  Future<void> call(NoParams params) {
    return _repository.clearFolderPath();
  }
}
