import '../../domain/entities/track_log.dart';
import '../../domain/repositories/track_repository.dart';
import '../datasources/track_local_datasource.dart';
import '../models/track_log_model.dart';

class TrackRepositoryImpl implements TrackRepository {
  final TrackLocalDataSource _dataSource;
  TrackRepositoryImpl(this._dataSource);

  @override
  Future<List<TrackLog>> loadAll(String rootPath) async {
    final models = await _dataSource.loadAll(rootPath);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> save(String rootPath, TrackLog log) async {
    await _dataSource.save(rootPath, TrackLogModel.fromEntity(log));
  }

  @override
  Future<void> delete(String rootPath, String id) async {
    await _dataSource.delete(rootPath, id);
  }

  // 機能: DataSource の古いログ削除処理へ委譲する。
  // 状態: 自動削除を停止中のため未使用。
  // @override
  // Future<void> deleteOlderThan(String rootPath, int days) async {
  //   await _dataSource.deleteOlderThan(rootPath, days);
  // }
}
