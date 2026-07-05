import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../location/presentation/providers/location_provider.dart';
import '../../../setting/presentation/providers/text_scale_provider.dart';
import '../providers/map_camera_provider.dart';

/// マップ中央座標（Center）と端末の現在地（My Location）を
/// 画面右上にオーバーレイ表示するウィジェット
///
/// - Center      : mapCameraProvider から取得（地図操作でリアルタイム更新）
/// - My Location : locationStreamProvider から取得（GPS でリアルタイム更新）
class CoordinateDisplay extends ConsumerWidget {
  const CoordinateDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapCamera = ref.watch(mapCameraProvider);
    final locationAsync = ref.watch(locationStreamProvider);

    final scale = ref.watch(textScaleProvider).scale;
    final textTheme = Theme.of(context).textTheme;
    final baseStyle = textTheme.bodyMedium?.copyWith(
      color: Colors.white,
      height: 1.5,
    );
    final labelStyle = baseStyle?.copyWith(
      fontWeight: FontWeight.w600,
      fontSize: (textTheme.bodyMedium?.fontSize ?? 14) * scale * 0.85,
      color: Colors.white70,
    );

    return Container(
      padding: EdgeInsets.all(8 * scale),
      constraints: BoxConstraints(maxWidth: 220 * scale),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(6 * scale),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── マップ中央座標 ──────────────────────────────────────────────
          Text('Center', style: labelStyle),
          Text(
            'Lat: ${mapCamera.latitude.toStringAsFixed(6)}\n'
            'Lng: ${mapCamera.longitude.toStringAsFixed(6)}\n'
            'Zoom: ${mapCamera.zoom.toStringAsFixed(1)}',
            style: baseStyle,
          ),

          SizedBox(height: 8 * scale),
          Divider(color: Colors.white24, height: 1, thickness: 1),
          SizedBox(height: 8 * scale),

          // ── 現在地 ─────────────────────────────────────────────────────
          Text('My Location', style: labelStyle),
          locationAsync.when(
            loading: () => Text('取得中...', style: baseStyle),
            error: (_, __) => Text(
              '取得エラー',
              style: baseStyle?.copyWith(color: Colors.redAccent),
            ),
            data: (location) => location == null
                ? Text(
                    '権限なし / 無効',
                    style: baseStyle?.copyWith(color: Colors.orange),
                  )
                : Text(
                    'Lat: ${location.latitude.toStringAsFixed(6)}\n'
                    'Lng: ${location.longitude.toStringAsFixed(6)}\n'
                    '精度: ±${location.accuracy.toStringAsFixed(0)}m',
                    style: baseStyle,
                  ),
          ),
        ],
      ),
    );
  }
}
