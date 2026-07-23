import 'dart:io';
import 'package:path/path.dart' as p;
import '../../domain/entities/folder_selection.dart';
import '../../domain/repositories/folder_repository.dart';
import '../datasources/folder_local_datasource.dart';

class FolderRepositoryImpl implements FolderRepository {
  final FolderLocalDataSource _dataSource;
  FolderRepositoryImpl(this._dataSource);

  @override
  Future<FolderSelection?> pickFolder() async {
    final path = await _dataSource.pickFolderPath();
    if (path == null) return null;
    return _buildSelection(path);
  }

  @override
  Future<FolderSelection?> loadSavedFolder({String? savedPath}) async {
    String? path;
    if (Platform.isIOS) {
      // iOS: ブックマーク復元 → 最新パスを取得
      path = await _dataSource.restoreFolderPath();
    } else {
      // Android: settings.json から渡されたパスをそのまま使う
      path = savedPath;
    }

    if (path == null) return null;

    // フォルダが移動・削除されていたらクリアして null を返す
    if (!await _dataSource.folderExists(path)) {
      await _dataSource.clearFolderPath();
      return null;
    }

    return _buildSelection(path);
  }

  @override
  Future<void> saveFolderPath(String path) => _dataSource.saveFolderPath(path);

  @override
  Future<void> clearFolderPath() => _dataSource.clearFolderPath();

  Future<FolderSelection> _buildSelection(String path) async {
    final mapNames = await _dataSource.scanLocalMapNames(path);
    return FolderSelection(
      path: path,
      name: p.basename(path),
      localMapNames: mapNames,
    );
  }
}
