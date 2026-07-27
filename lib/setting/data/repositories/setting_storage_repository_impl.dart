import '../../domain/entities/setting_storage_data.dart';
import '../../domain/repositories/setting_storage_repository.dart';
import '../datasources/setting_storage_datasource.dart';

// ドメイン層で定義されたSettingStorageRepositoryの実体を定義するリポジトリ実装ファイル
// 低レイヤーの保存データソースを隠蔽しながら設定情報永続化のビジネスロジックを結合
class SettingStorageRepositoryImpl implements SettingStorageRepository {
  final SettingStorageDataSource _dataSource;

  SettingStorageRepositoryImpl(this._dataSource);

  @override
  Future<SettingStorageData> getSettingData() {
    return _dataSource.loadSettingData();
  }

  @override
  Future<void> saveSettingData(SettingStorageData data) {
    return _dataSource.saveSettingData(data);
  }
}