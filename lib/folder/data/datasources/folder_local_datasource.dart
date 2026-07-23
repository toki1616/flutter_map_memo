import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import '../../../core/constants/app_constants.dart';
import '../../../core/data/services/android_saf_storage_service.dart';
import 'ios_directory_service.dart';

/// フォルダパスの永続化とマップ名スキャンを担うデータソース
///
/// パスの保存先: Documents/save_data/setting/settings.json の "folderPath" キー
/// SharedPreferences は使わない
///
/// iOS と Android でアクセス権の仕組みが根本的に異なるため OS ごとに実装を分岐する
///
/// ┌─────────┬──────────────────────────────────────────────────────────┐
/// │  iOS    │ セキュリティスコープブックマークで永続化（AppDelegate.swift）  │
/// │         │ settings.json にはブックマーク復元後のパスを参照用として保存   │
/// ├─────────┼──────────────────────────────────────────────────────────┤
/// │ Android │ settings.json の "folderPath" に絶対パスを直接保存          │
/// └─────────┴──────────────────────────────────────────────────────────┘
abstract class FolderLocalDataSource {
  Future<String?> pickFolderPath();
  Future<String?> restoreFolderPath();
  Future<void> saveFolderPath(String path);
  Future<void> clearFolderPath();
  Future<bool> folderExists(String rootPath);
  Future<List<String>> scanLocalMapNames(String rootPath);
}

// ─────────────────────────────────────────────────────────────────────────
// iOS 実装
// ─────────────────────────────────────────────────────────────────────────

class IosFolderLocalDataSource implements FolderLocalDataSource {
  /// 取得したパスを settings.json にも記録するコールバック
  final Future<void> Function(String path) onPathResolved;
  final Future<void> Function() onPathCleared;

  IosFolderLocalDataSource({
    required this.onPathResolved,
    required this.onPathCleared,
  });

  @override
  Future<String?> pickFolderPath() async {
    final path = await IosDirectoryService.pickAndSaveDirectory();
    if (path != null) await onPathResolved(path);
    return path;
  }

  @override
  Future<String?> restoreFolderPath() async {
    // ブックマーク経由でアクセス権ごと復元し、最新パスを返す
    final path = await IosDirectoryService.restoreDirectoryAccess();
    if (path != null) await onPathResolved(path);
    return path;
  }

  @override
  Future<void> saveFolderPath(String path) async {
    // iOS はブックマーク保存が AppDelegate で完結するため何もしない
  }

  @override
  Future<void> clearFolderPath() async {
    await IosDirectoryService.stopDirectoryAccess();
    await onPathCleared();
  }

  @override
  Future<bool> folderExists(String rootPath) => Directory(rootPath).exists();

  @override
  Future<List<String>> scanLocalMapNames(String rootPath) =>
      _scanMapNames(rootPath);
}

// ─────────────────────────────────────────────────────────────────────────
// Android 実装
// ─────────────────────────────────────────────────────────────────────────

class AndroidFolderLocalDataSource implements FolderLocalDataSource {
  final Future<void> Function(String path) onPathSaved;
  final Future<void> Function() onPathCleared;

  AndroidFolderLocalDataSource({
    required this.onPathSaved,
    required this.onPathCleared,
  });

  @override
  Future<String?> pickFolderPath() async {
    final result = await AndroidSafStorageService.pickDirectory();
    if (result != null) await onPathSaved(result);
    return result;
  }

  @override
  Future<String?> restoreFolderPath() async {
    // Android は settings.json から FolderProvider が直接読み出すため
    // このメソッドは使わない（常に null を返す）
    return null;
  }

  @override
  Future<void> saveFolderPath(String path) async {
    await onPathSaved(path);
  }

  @override
  Future<void> clearFolderPath() async {
    await onPathCleared();
  }

  @override
  Future<bool> folderExists(String rootPath) {
    if (AndroidSafStorageService.isSafUri(rootPath)) {
      return AndroidSafStorageService.existsDirectory(rootPath);
    }
    return Directory(rootPath).exists();
  }

  @override
  Future<List<String>> scanLocalMapNames(String rootPath) async {
    if (!AndroidSafStorageService.isSafUri(rootPath)) {
      return _scanMapNames(rootPath);
    }
    final entries = await AndroidSafStorageService.listEntries(
      rootPath,
      AppConstants.mapFolderName,
    );
    return entries
        .where((entry) => entry.isDirectory)
        .map((entry) => entry.name)
        .toList()
      ..sort();
  }
}

/// Android / iOS 以外のデスクトップ環境用実装。
class StandardFolderLocalDataSource implements FolderLocalDataSource {
  final Future<void> Function(String path) onPathSaved;
  final Future<void> Function() onPathCleared;

  StandardFolderLocalDataSource({
    required this.onPathSaved,
    required this.onPathCleared,
  });

  @override
  Future<String?> pickFolderPath() async {
    final path = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'マップフォルダを選択',
    );
    if (path != null) await onPathSaved(path);
    return path;
  }

  @override
  Future<String?> restoreFolderPath() async => null;

  @override
  Future<void> saveFolderPath(String path) => onPathSaved(path);

  @override
  Future<void> clearFolderPath() => onPathCleared();

  @override
  Future<bool> folderExists(String rootPath) => Directory(rootPath).exists();

  @override
  Future<List<String>> scanLocalMapNames(String rootPath) =>
      _scanMapNames(rootPath);
}

// ─────────────────────────────────────────────────────────────────────────
// ファクトリ関数：実行 OS に応じた実装を返す
// ─────────────────────────────────────────────────────────────────────────

FolderLocalDataSource createFolderLocalDataSource({
  required Future<void> Function(String path) onPathSaved,
  required Future<void> Function() onPathCleared,
}) {
  if (Platform.isIOS) {
    return IosFolderLocalDataSource(
      onPathResolved: onPathSaved,
      onPathCleared: onPathCleared,
    );
  } else if (Platform.isAndroid) {
    return AndroidFolderLocalDataSource(
      onPathSaved: onPathSaved,
      onPathCleared: onPathCleared,
    );
  }
  return StandardFolderLocalDataSource(
    onPathSaved: onPathSaved,
    onPathCleared: onPathCleared,
  );
}

// ─────────────────────────────────────────────────────────────────────────
// 共通ユーティリティ
// ─────────────────────────────────────────────────────────────────────────

Future<List<String>> _scanMapNames(String rootPath) async {
  final mapDir = Directory(p.join(rootPath, AppConstants.mapFolderName));
  if (!await mapDir.exists()) return [];
  final names = <String>[];
  await for (final entity in mapDir.list()) {
    if (entity is Directory) names.add(p.basename(entity.path));
  }
  names.sort();
  return names;
}
