import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../setting/presentation/providers/text_scale_provider.dart';
import '../providers/map_camera_provider.dart';

// マップの中央座標（Center）と端末の現在地（My Location）の緯度経度を画面上にオーバーレイ表示するUIウィジェットファイル
// textScaleProviderから現在の文字サイズタイプ（TextScaleType）を監視し、全体の拡大倍率に連動して枠サイズや余白、文字が破綻なくスケールする設計
class CoordinateDisplay extends ConsumerWidget {
  const CoordinateDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapCamera = ref.watch(mapCameraProvider);

    // TODO: スマホの現在地
    // final currentLocation = ref.watch(locationStreamProvider).valueOrNull;
    const currentLocation = null; // 現在は仮として null を置いています

    // textScaleProvider から列挙型（TextScaleType）を取得し、拡大倍率（scale）を取り出す
    final textScaleType = ref.watch(textScaleProvider);
    final scale = textScaleType.scale;

    // 現在のテーマに設定されているテキストスタイルを取得（フォントサイズはTheme側で自動スケールされます）
    final textTheme = Theme.of(context).textTheme;
    // 黒背景の上に白文字で綺麗に表示するため、ベーススタイルを調整
    final baseStyle = textTheme.bodyMedium?.copyWith(color: Colors.white);

    return Container(
      // padding もスケールさせることで、文字が大きくなっても余白を維持
      padding: EdgeInsets.all(8 * scale),
      constraints: BoxConstraints(
        // maxWidth を広げないと、文字が大きくなった時に不自然に改行されるのを防止
        maxWidth: 220 * scale,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6 * scale),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Center\n"
                "Lat: ${mapCamera.latitude.toStringAsFixed(6)}\n"
                "Lng: ${mapCamera.longitude.toStringAsFixed(6)}\n"
                "Zoom: ${mapCamera.zoom.toStringAsFixed(1)}",
            style: baseStyle,
          ),

          // 行間も倍率に合わせて動的に拡張
          SizedBox(height: 10 * scale),

          if (currentLocation != null)
            Text(
              "My Location\n"
                  "Lat: \${currentLocation.latitude.toStringAsFixed(6)}\n"
                  "Lng: \${currentLocation.longitude.toStringAsFixed(6)}",
              style: baseStyle,
            )
          else
            Text(
              "My Location\n取得中...",
              style: baseStyle,
            ),
        ],
      ),
    );
  }
}