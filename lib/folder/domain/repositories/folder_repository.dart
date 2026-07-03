import '../entities/folder_selection.dart';

/// フォルダ選択・パス永続化・マップ名スキャンのビジネスルールを定義するリポジトリインターフェース
abstract class FolderRepository {
  /// OS 標準のフォルダ選択ダイアログを表示する
  /// 選択後は自動的に settings.json に保存される
  /// キャンセル時は null を返す
  Future<FolderSelection?> pickFolder();

  /// 前回選択したフォルダを復元する
  /// [savedPath] : settings.json から読み出したパス
  ///   iOS    : null を渡す（ブックマーク復元が内部で走るため）
  ///   Android: settings.json の folderPath を渡す
  Future<FolderSelection?> loadSavedFolder({String? savedPath});

  /// フォルダパスを settings.json に保存する（Android 用補助）
  Future<void> saveFolderPath(String path);

  /// 保存済みフォルダパスをクリアする
  Future<void> clearFolderPath();
}
