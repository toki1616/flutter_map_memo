import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/setting_storage_datasource.dart';
import '../../data/repositories/setting_storage_repository_impl.dart';
import '../../domain/entities/orientation_config.dart';
import '../../domain/entities/setting_storage_data.dart';
import '../../domain/entities/text_scale_config.dart';
import '../../domain/entities/track_setting_config.dart';
import '../../domain/repositories/setting_storage_repository.dart';

// ── DI ───────────────────────────────────────────────────────────────────

final settingStorageDataSourceProvider = Provider<SettingStorageDataSource>(
  (ref) => SettingStorageDataSourceImpl(),
);

final settingStorageRepositoryProvider = Provider<SettingStorageRepository>(
  (ref) =>
      SettingStorageRepositoryImpl(ref.watch(settingStorageDataSourceProvider)),
);

// ── Notifier ──────────────────────────────────────────────────────────────

class SettingStorageNotifier extends AsyncNotifier<SettingStorageData> {
  @override
  Future<SettingStorageData> build() async {
    final data = await ref
        .read(settingStorageRepositoryProvider)
        .getSettingData();
    _applyOrientation(data.orientationType);
    return data;
  }

  Future<void> _save(SettingStorageData data) async {
    try {
      await ref.read(settingStorageRepositoryProvider).saveSettingData(data);
      state = AsyncData(data);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  // ── 各設定の保存メソッド ────────────────────────────────────────────────

  Future<void> saveTextScale(TextScaleType newType) async {
    final current = state.valueOrNull ?? const SettingStorageData();
    await _save(current.copyWith(textScaleType: newType));
  }

  Future<void> saveFolderPath(String path) async {
    final current = state.valueOrNull ?? const SettingStorageData();
    await _save(current.copyWith(folderPath: path));
  }

  Future<void> clearFolderPath() async {
    final current = state.valueOrNull ?? const SettingStorageData();
    await _save(current.copyWith(folderPath: null));
  }

  Future<void> saveOrientation(OrientationType newType) async {
    final current = state.valueOrNull ?? const SettingStorageData();
    _applyOrientation(newType);
    await _save(current.copyWith(orientationType: newType));
  }

  Future<void> saveTrackInterval(TrackIntervalType newType) async {
    final current = state.valueOrNull ?? const SettingStorageData();
    await _save(current.copyWith(trackIntervalType: newType));
  }

  Future<void> saveTrackDisplayDays(TrackDisplayDaysType newType) async {
    final current = state.valueOrNull ?? const SettingStorageData();
    await _save(current.copyWith(trackDisplayDaysType: newType));
  }

  // 機能: 選択した保存期間を settings.json に書き込む。
  // 状態: 自動削除を停止中のため、この更新 API は無効化している。
  // Future<void> saveTrackRetentionDays(TrackRetentionDaysType newType) async {
  //   final current = state.valueOrNull ?? const SettingStorageData();
  //   await _save(current.copyWith(trackRetentionDaysType: newType));
  // }

  void _applyOrientation(OrientationType type) {
    SystemChrome.setPreferredOrientations(type.orientations);
  }
}

final settingStorageProvider =
    AsyncNotifierProvider<SettingStorageNotifier, SettingStorageData>(
      SettingStorageNotifier.new,
    );
