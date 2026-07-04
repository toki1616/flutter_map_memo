import '../entities/location_data.dart';

/// 位置情報の取得ルールを定義するリポジトリインターフェース
abstract class LocationRepository {
  /// 位置情報サービスが有効かつ権限があるか確認・リクエストする
  /// 利用可能なら true、権限拒否や無効なら false を返す
  Future<bool> requestPermission();

  /// 現在地を一度だけ取得する
  Future<LocationData?> getCurrentLocation();

  /// 現在地をリアルタイムで監視する Stream
  /// 権限がない場合は空ストリームを返す
  Stream<LocationData?> watchLocation();
}
