import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/setting_storage_datasource.dart';
import '../../data/repositories/setting_storage_repository_impl.dart';
import '../../domain/entities/orientation_config.dart';
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
    final data =
        await ref.read(settingStorageRepositoryProvider).getSettingData();
    // 起動時に保存済みの画面向き設定を即時適用する
    _applyOrientation(data.orientationType);
    return data;
  }

  /// 設定データをファイルへ書き込み、状態を更新する内部メソッド
  Future<void> _save(SettingStorageData data) async {
    try {
      await ref.read(settingStorageRepositoryProvider).saveSettingData(data);
      state = AsyncData(data);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  // ── 公開メソッド ────────────────────────────────────────────────────────

  /// 文字サイズ設定を保存する
  Future<void> saveTextScale(TextScaleType newScaleType) async {
    final current = state.valueOrNull ?? const SettingStorageData();
    await _save(current.copyWith(textScaleType: newScaleType));
  }

  /// フォルダパスを保存する
  Future<void> saveFolderPath(String path) async {
    final current = state.valueOrNull ?? const SettingStorageData();
    await _save(current.copyWith(folderPath: path));
  }

  /// フォルダパスを削除する
  Future<void> clearFolderPath() async {
    final current = state.valueOrNull ?? const SettingStorageData();
    await _save(current.copyWith(folderPath: null));
  }

  /// 画面向き設定を保存し、即時適用する
  Future<void> saveOrientation(OrientationType newType) async {
    final current = state.valueOrNull ?? const SettingStorageData();
    _applyOrientation(newType);
    await _save(current.copyWith(orientationType: newType));
  }

  /// SystemChrome で画面向きを実際に適用する
  void _applyOrientation(OrientationType type) {
    SystemChrome.setPreferredOrientations(type.orientations);
  }
}

final settingStorageProvider =
    AsyncNotifierProvider<SettingStorageNotifier, SettingStorageData>(
  SettingStorageNotifier.new,
);
