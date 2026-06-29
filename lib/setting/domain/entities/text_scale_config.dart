import 'package:flutter/foundation.dart';

// アプリ全体の文字やボタンの表示サイズと拡大倍率を紐付けて一元管理する列挙型ファイル
// 画面に表示する文言と実際の倍率をペアで定義し、選択肢の追加や倍率の調整を一箇所で容易に行えるように
enum TextScaleType {
  standard('標準', 1.0),
  large('大きく', 1.3),
  extraLarge('とても大きく', 1.6);

  final String label;
  final double scale;
  const TextScaleType(this.label, this.scale);
}