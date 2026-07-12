import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../../../core/constants/app_constants.dart';
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

  /// 指定日数より古いファイルを一括削除する
  Future<void> deleteOlderThan(String rootPath, int days);
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

  @override
  Future<List<TrackLogModel>> loadAll(String rootPath) async {
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
    final dir = _trackDir(rootPath);
    if (!await dir.exists()) await dir.create(recursive: true);

    final file = _trackFile(rootPath, model.id);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(model.toJson()),
    );
  }

  @override
  Future<void> delete(String rootPath, String id) async {
    final file = _trackFile(rootPath, id);
    if (await file.exists()) await file.delete();
  }

  @override
  Future<void> deleteOlderThan(String rootPath, int days) async {
    final dir = _trackDir(rootPath);
    if (!await dir.exists()) return;

    final threshold = DateTime.now().subtract(Duration(days: days));
    await for (final entity in dir.list()) {
      if (entity is File && entity.path.endsWith('.json')) {
        try {
          final content = await entity.readAsString();
          final json = jsonDecode(content) as Map<String, dynamic>;
          final model = TrackLogModel.fromJson(json);
          final startedAt = DateTime.parse(model.startedAt);
          if (startedAt.isBefore(threshold)) {
            await entity.delete();
          }
        } catch (_) {}
      }
    }
  }
}
