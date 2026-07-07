import 'package:flutter/services.dart';

/// アプリ全体の画面向き設定を管理する列挙型
/// label: 設定画面に表示する文言
/// orientations: SystemChrome に渡す向きのリスト
enum OrientationType {
  auto('自動回転', [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]),
  portrait('縦画面', [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]),
  landscape('横画面', [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  final String label;
  final List<DeviceOrientation> orientations;
  const OrientationType(this.label, this.orientations);
}
