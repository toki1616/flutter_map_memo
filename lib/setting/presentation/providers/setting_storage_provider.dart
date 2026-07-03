import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/setting_storage_datasource.dart';
import '../../data/repositories/setting_storage_repository_impl.dart';
import '../../domain/entities/setting_storage_data.dart';
import '../../domain/entities/text_scale_config.dart';
import '../../domain/repositories/setting_storage_repository.dart';

// ── DI ───────────────────────────────────────────────────────────────────

final settingStorageDataSourceProvider = Provider<SettingStorageDataSource>(
  (ref) => SettingStorageDataSourceImpl(),
);

final settingStorageRepositoryProvider = Provider<SettingStorageRepository>(
  (ref) => SettingStorageRepositoryImpl(
    ref.watch(settingStorageDataSourceProvider),
  ),
);

// ── Notifier ──────────────────────────────────────────────────────────────

/// 設定データのファイル保存・読み込みを担当する AsyncNotifier
/// Documents/save_data/setting/settings.json を唯一の保存先として管理する
class SettingStorageNotifier extends AsyncNotifier<SettingStorageData> {
  @override
  Future<SettingStorageData> build() async {
    // アプリ起動時に settings.json を読み込む
    return ref.read(settingStorageRepositoryProvider).getSettingData();
  }

  /// 設定データをファイルへ書き込み、状態を更新する内部メソッド
  /// AsyncLoading を挟まないことで textScaleProvider 等の不要な再生成を防ぐ
  Future<void> _save(SettingStorageData data) async {
    try {
      await ref.read(settingStorageRepositoryProvider).saveSettingData(data);
      state = AsyncData(data);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  // ── 公開メソッド ────────────────────────────────────────────────────────

  /// 文字サイズ設定を settings.json に保存する
  Future<void> saveTextScale(TextScaleType newScaleType) async {
    final current = state.valueOrNull ?? const SettingStorageData();
    await _save(current.copyWith(textScaleType: newScaleType));
  }

  /// フォルダパスを settings.json に保存する
  ///
  /// 呼び出し元:
  ///   - IosFolderLocalDataSource.onPathResolved   （iOS: フォルダ選択後 / 起動時復元後）
  ///   - AndroidFolderLocalDataSource.onPathSaved  （Android: フォルダ選択後）
  ///
  /// 保存後の settings.json イメージ:
  ///   {
  ///     "textScaleType": "standard",
  ///     "folderPath": "/path/to/selected/folder"
  ///   }
  Future<void> saveFolderPath(String path) async {
    final current = state.valueOrNull ?? const SettingStorageData();
    await _save(current.copyWith(folderPath: path));
  }

  /// フォルダパスを settings.json から削除する
  ///
  /// 呼び出し元:
  ///   - IosFolderLocalDataSource.onPathCleared   （iOS: フォルダリセット時）
  ///   - AndroidFolderLocalDataSource.onPathCleared（Android: フォルダリセット時）
  Future<void> clearFolderPath() async {
    final current = state.valueOrNull ?? const SettingStorageData();
    // folderPath に null を渡してクリア（_sentinel 番兵で null と未指定を区別）
    await _save(current.copyWith(folderPath: null));
  }
}

final settingStorageProvider =
    AsyncNotifierProvider<SettingStorageNotifier, SettingStorageData>(
  SettingStorageNotifier.new,
);
