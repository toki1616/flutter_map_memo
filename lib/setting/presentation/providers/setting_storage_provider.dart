import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/setting_storage_datasource.dart';
import '../../data/repositories/setting_storage_repository_impl.dart';
import '../../domain/entities/setting_storage_data.dart';
import '../../domain/entities/text_scale_config.dart';
import '../../domain/repositories/setting_storage_repository.dart';

// 各種設定データのファイル保存・読み込み（同期処理）のみを担当するプロバイダー群ファイル
// 画面から渡された新しい設定値をリポジトリ経由でファイルへ書き込み、永続化ストレージと状態の同期を管理
final settingStorageDataSourceProvider = Provider<SettingStorageDataSource>((ref) {
  return SettingStorageDataSourceImpl();
});

final settingStorageRepositoryProvider = Provider<SettingStorageRepository>((ref) {
  final dataSource = ref.watch(settingStorageDataSourceProvider);
  return SettingStorageRepositoryImpl(dataSource);
});

class SettingStorageNotifier extends AsyncNotifier<SettingStorageData> {
  @override
  Future<SettingStorageData> build() async {
    // アプリ起動時にローカルの「設定ファイル.json」から保存されている設定データをロード
    return ref.read(settingStorageRepositoryProvider).getSettingData();
  }

  // 純粋に設定データをファイルへ物理書き込みし、プロバイダーの保存状態を更新する処理
  Future<void> executeSave(SettingStorageData data) async {
    state = const AsyncLoading();
    try {
      await ref.read(settingStorageRepositoryProvider).saveSettingData(data);
      state = AsyncData(data);
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  // UIや他のプロバイダーから呼び出し、文字サイズ倍率設定の書き込み（保存）を実行するメソッド
  Future<void> saveTextScale(TextScaleType newScaleType) async {
    final currentData = state.valueOrNull ?? const SettingStorageData();
    final updatedData = currentData.copyWith(textScaleType: newScaleType);
    await executeSave(updatedData);
  }
}

final settingStorageProvider = AsyncNotifierProvider<SettingStorageNotifier, SettingStorageData>(
  SettingStorageNotifier.new,
);