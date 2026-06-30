import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_constants.dart';
import '../providers/map_camera_provider.dart';

import '../../../core/presentation/widgets/app_floating_button.dart';

/// 地図画面の右下にフローティング表示する、ズームイン・ズームアウト制御専用のUIボタン群ウィジェットファイル
class MapFabButtons extends ConsumerWidget {
  final MapController mapController;

  const MapFabButtons({
    super.key,
    required this.mapController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 現在の地図の中心座標とズームレベルをプロバイダーから安全に取得
    final mapCameraState = ref.watch(mapCameraProvider);
    final currentCenter = LatLng(mapCameraState.latitude, mapCameraState.longitude);
    final currentZoom = mapCameraState.zoom;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        /// ------------------------------------------------------------
        /// 縦並びのボタン群（ズームイン・アウト）
        /// ------------------------------------------------------------
        AppFloatingButton(
          heroTag: "zoomIn",
          icon: const Icon(Icons.add, color: Colors.black),
          backgroundColor: Colors.white,
          onPressed: () {
            try {
              if (currentZoom < AppConstants.maxZoom) {
                mapController.move(
                  currentCenter,
                  currentZoom + 1,
                );

                // ズーム移動直後にレイヤーを強制リロード（プロジェクトのProviderが定義されている場合有効化）
                // ref.read(mapForceRefreshProvider.notifier).state++;
              }
            } catch (_) {
              // コントローラーのアタッチが間に合っていない場合のエラーを安全にガード
            }
          },
        ),
        const SizedBox(height: 10),

        AppFloatingButton(
          heroTag: "zoomOut",
          icon: const Icon(Icons.remove, color: Colors.black),
          backgroundColor: Colors.white,
          onPressed: () {
            try {
              if (currentZoom > AppConstants.minZoom) {
                mapController.move(
                  currentCenter,
                  currentZoom - 1,
                );

                // ズーム移動直後にレイヤーを強制リロード（プロジェクトのProviderが定義されている場合有効化）
                // ref.read(mapForceRefreshProvider.notifier).state++;
              }
            } catch (_) {
              // コントローラーのアタッチが間に合っていない場合のエラーを安全にガード
            }
          },
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}