import '../entities/pin_data.dart';

/// ピンデータの CRUD ルールを定義するリポジトリインターフェース
/// 保存先: {rootPath}/save_data/map_data/pin.json
abstract class PinRepository {
  Future<List<PinData>> loadPins(String rootPath);
  Future<void> addPin(String rootPath, PinData pin);
  Future<void> updatePin(String rootPath, PinData pin);
  Future<void> deletePin(String rootPath, String pinId);
}
