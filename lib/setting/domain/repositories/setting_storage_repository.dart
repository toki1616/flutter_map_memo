import '../entities/setting_storage_data.dart';

// 各種設定の「保存・読み込み業務」に関する抽象的なルールを定義するリポジトリファイル
// 永続化ストレージへのデータ保存タスクとデータ取得タスクのインターフェースを規定
abstract class SettingStorageRepository {
  Future<SettingStorageData> getSettingData();
  Future<void> saveSettingData(SettingStorageData data);
}