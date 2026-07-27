import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/text_scale_config.dart';
import 'setting_storage_provider.dart';

// アプリ全体の文字やボタンのサイズ設定を管理するためのプロバイダーファイル
// 状態の変更を検知すると、自動的に settingStorageProvider を経由して「設定ファイル.json」へ書き込み保存を実行する構造
class TextScaleNotifier extends StateNotifier<TextScaleType> {
  final Ref _ref;

  TextScaleNotifier(this._ref) : super(TextScaleType.standard) {
    // ➔ 【自動読込】起動時にストレージに保存されている最新の値を反映
    final savedData = _ref.read(settingStorageProvider).valueOrNull;
    if (savedData != null) {
      state = savedData.textScaleType;
    }
  }

  void updateScale(TextScaleType newType) {
    state = newType;
    // ➔ 【自動保存】状態が変わったら、ストレージ書き込みプロバイダーを呼び出して保存
    _ref.read(settingStorageProvider.notifier).saveTextScale(newType);
  }
}

final textScaleProvider = StateNotifierProvider<TextScaleNotifier, TextScaleType>((ref) {
  // アプリ起動直後など、ストレージ側の読み込みが完了したタイミングで同期させるためにwatchしておく
  ref.watch(settingStorageProvider);
  return TextScaleNotifier(ref);
});