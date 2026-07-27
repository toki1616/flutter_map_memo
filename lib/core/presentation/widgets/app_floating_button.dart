import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../setting/presentation/providers/text_scale_provider.dart';

class AppFloatingButton extends ConsumerWidget {
  final String heroTag;
  final Widget icon;   // アイコンウィジェット
  final String? label; // 文字がある場合は横長ボタン（Extended）になる
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final String? tooltip;
  final double baseHeight; // 基本の高さ

  const AppFloatingButton({
    super.key,
    required this.heroTag,
    required this.icon,
    this.label,
    required this.onPressed,
    this.backgroundColor,
    this.tooltip,
    this.baseHeight = 56.0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uiScale = ref.watch(textScaleProvider).scale;
    final double scaledHeight = baseHeight * uiScale;
    final double scaledIconSize = 24.0 * uiScale;

    // アイコンのサイズを一括適用するためのテーマ
    final iconTheme = IconThemeData(size: scaledIconSize);

    return SizedBox(
      height: scaledHeight,
      // ラベルがある場合：Extended (横長)
      child: label != null
          ? FloatingActionButton.extended(
        heroTag: heroTag,
        onPressed: onPressed,
        backgroundColor: backgroundColor,
        tooltip: tooltip,
        // Extended の場合は icon: プロパティを使う
        icon: IconTheme(data: iconTheme, child: icon),
        label: Text(
          label!,
          style: TextStyle(fontSize: 14),
        ),
      )
          : SizedBox(
        width: scaledHeight, // 丸ボタンの場合は横幅も固定
        // ラベルがない場合：通常 (丸)
        child: FloatingActionButton(
          heroTag: heroTag,
          onPressed: onPressed,
          backgroundColor: backgroundColor,
          tooltip: tooltip,
          // 通常版は icon: ではなく child: を使う
          child: IconTheme(data: iconTheme, child: icon),
        ),
      ),
    );
  }
}