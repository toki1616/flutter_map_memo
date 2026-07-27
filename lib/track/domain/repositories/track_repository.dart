import '../entities/track_log.dart';

/// トラックログの永続化ルールを定義するリポジトリインターフェース
/// 保存先: {rootPath}/save_data/map_data/track_log/track_YYYYMMDD_HHmmss.json
abstract class TrackRepository {
  /// 全トラックログを読み込む
  Future<List<TrackLog>> loadAll(String rootPath);

  /// トラックログを保存する（新規・更新どちらも同じメソッド）
  Future<void> save(String rootPath, TrackLog log);

  /// IDに対応するトラックログを削除する
  Future<void> delete(String rootPath, String id);

  // 機能: 指定日数より古いトラックログを一括削除する。
  // 状態: 自動削除を停止中のため未使用。
  // Future<void> deleteOlderThan(String rootPath, int days);
}
