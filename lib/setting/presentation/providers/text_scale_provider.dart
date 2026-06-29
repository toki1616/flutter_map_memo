import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/text_scale_config.dart';

// アプリ全体の文字やボタンのサイズ設定を管理するためのプロバイダーファイル
// 状態として倍率の数値を直接持つのではなく、設定用として定義した列挙型（TextScaleType）を保持することでUI側での状態管理を簡潔に
class TextScaleNotifier extends StateNotifier<TextScaleType> {
  TextScaleNotifier() : super(TextScaleType.standard);

  void updateScale(TextScaleType newType) {
    state = newType;
  }
}

final textScaleProvider = StateNotifierProvider<TextScaleNotifier, TextScaleType>((ref) {
  return TextScaleNotifier();
});