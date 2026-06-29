import 'dart:convert';
import 'dart:io';
import '../../../core/utils/app_path_utils.dart';
import '../../domain/entities/setting_storage_data.dart';

// 設定ファイル.jsonに対して各種設定データの物理的な保存と読み込みのみを実行するデータソースファイル
// パスユーティリティからファイルパスを解決し、ディスクへの低レベルなI/O書き込み処理に特化
abstract class SettingStorageDataSource {
  Future<SettingStorageData> loadSettingData();
  Future<void> saveSettingData(SettingStorageData data);
}

class SettingStorageDataSourceImpl implements SettingStorageDataSource {
  @override
  Future<SettingStorageData> loadSettingData() async {
    try {
      final path = await AppPathUtils.getSettingsFilePath();
      final file = File(path);
      if (!await file.exists()) return const SettingStorageData();

      final content = await file.readAsString();
      return SettingStorageData.fromJson(json.decode(content) as Map<String, dynamic>);
    } catch (_) {
      return const SettingStorageData();
    }
  }

  @override
  Future<void> saveSettingData(SettingStorageData data) async {
    final path = await AppPathUtils.getSettingsFilePath();
    final file = File(path);

    await file.parent.create(recursive: true);

    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(data.toJson()),
    );
  }
}