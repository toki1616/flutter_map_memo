import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../../../core/constants/app_constants.dart';
import '../../../core/data/services/android_saf_storage_service.dart';
import '../models/track_log_model.dart';

/// {rootPath}/save_data/map_data/track_log/ 以下の
/// track_YYYYMMDD_HHmmss.json への読み書きを担うデータソース
///
/// タスクキル対策:
///   ポイントが追加されるたびに即座にファイルへ書き込む設計にする。
///   （メモリ上のみで保持していると、タスクキル時にデータが消える）
abstract class TrackLocalDataSource {
  /// 全トラックログファイルを読み込む
  Future<List<TrackLogModel>> loadAll(String rootPath);

  /// トラックログを保存する（新規・更新どちらも）
  /// ファイル名: {id}.json
  Future<void> save(String rootPath, TrackLogModel model);

  /// IDに対応するファイルを削除する
  Future<void> delete(String rootPath, String id);

  // 機能: 指定日数より古いトラックログファイルを削除する。
  // 状態: 自動削除を停止中のため未使用。
  // Future<void> deleteOlderThan(String rootPath, int days);
}

class TrackLocalDataSourceImpl implements TrackLocalDataSource {
  Directory _trackDir(String rootPath) => Directory(
    p.join(
      rootPath,
      AppConstants.saveDataFolderName,
      AppConstants.mapDataFolderName,
      AppConstants.trackLogFolderName,
    ),
  );

  File _trackFile(String rootPath, String id) =>
      File(p.join(_trackDir(rootPath).path, '$id.json'));

  String _trackRelativeDirectory() => p.join(
    AppConstants.saveDataFolderName,
    AppConstants.mapDataFolderName,
    AppConstants.trackLogFolderName,
  );

  String _trackRelativePath(String id) =>
      p.join(_trackRelativeDirectory(), '$id.json');

  @override
  Future<List<TrackLogModel>> loadAll(String rootPath) async {
    if (AndroidSafStorageService.isSafUri(rootPath)) {
      final entries = await AndroidSafStorageService.listEntries(
        rootPath,
        _trackRelativeDirectory(),
      );
      final models = <TrackLogModel>[];
      for (final entry in entries.where(
        (entry) => !entry.isDirectory && entry.name.endsWith('.json'),
      )) {
        try {
          final content = await AndroidSafStorageService.readFile(
            rootPath,
            p.join(_trackRelativeDirectory(), entry.name),
          );
          if (content != null) {
            models.add(TrackLogModel.fromJson(jsonDecode(content)));
          }
        } catch (_) {
          // 壊れたファイルはスキップ
        }
      }
      models.sort((a, b) => b.startedAt.compareTo(a.startedAt));
      return models;
    }
    final dir = _trackDir(rootPath);
    if (!await dir.exists()) return [];

    final models = <TrackLogModel>[];
    await for (final entity in dir.list()) {
      if (entity is File && entity.path.endsWith('.json')) {
        try {
          final content = await entity.readAsString();
          final json = jsonDecode(content) as Map<String, dynamic>;
          models.add(TrackLogModel.fromJson(json));
        } catch (_) {
          // 壊れたファイルはスキップ
        }
      }
    }

    // 開始時刻の新しい順に並べる
    models.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return models;
  }

  @override
  Future<void> save(String rootPath, TrackLogModel model) async {
    final content = const JsonEncoder.withIndent('  ').convert(model.toJson());
    if (AndroidSafStorageService.isSafUri(rootPath)) {
      await AndroidSafStorageService.writeFile(
        rootPath,
        _trackRelativePath(model.id),
        content,
      );
      return;
    }
    final dir = _trackDir(rootPath);
    if (!await dir.exists()) await dir.create(recursive: true);

    final file = _trackFile(rootPath, model.id);
    await file.writeAsString(content);
  }

  @override
  Future<void> delete(String rootPath, String id) async {
    if (AndroidSafStorageService.isSafUri(rootPath)) {
      await AndroidSafStorageService.deleteFile(
        rootPath,
        _trackRelativePath(id),
      );
      return;
    }
    final file = _trackFile(rootPath, id);
    if (await file.exists()) await file.delete();
  }

  /*
   * 機能: startedAt が指定日数より前のトラックログファイルを削除する。
   * 状態: 自動削除を停止中。再導入する場合は、SAF URI と通常パスの両方を扱う。
  @override
  Future<void> deleteOlderThan(String rootPath, int days) async {
    final threshold = DateTime.now().subtract(Duration(days: days));
    if (AndroidSafStorageService.isSafUri(rootPath)) {
      final entries = await AndroidSafStorageService.listEntries(rootPath, _trackRelativeDirectory());
      for (final entry in entries.where(
        (entry) => !entry.isDirectory && entry.name.endsWith('.json'),
      )) {
        final relativePath = p.join(_trackRelativeDirectory(), entry.name);
        final content = await AndroidSafStorageService.readFile(rootPath, relativePath);
        if (content == null) continue;
        final model = TrackLogModel.fromJson(jsonDecode(content));
        if (DateTime.parse(model.startedAt).isBefore(threshold)) {
          await AndroidSafStorageService.deleteFile(rootPath, relativePath);
        }
      }
      return;
    }
    final dir = _trackDir(rootPath);
    if (!await dir.exists()) return;
    await for (final entity in dir.list()) {
      if (entity is File && entity.path.endsWith('.json')) {
        final model = TrackLogModel.fromJson(
          jsonDecode(await entity.readAsString()) as Map<String, dynamic>,
        );
        if (DateTime.parse(model.startedAt).isBefore(threshold)) {
          await entity.delete();
        }
      }
    }
  }
  */
}
