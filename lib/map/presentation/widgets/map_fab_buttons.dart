import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/presentation/widgets/app_floating_button.dart';
import '../../../pin/presentation/widgets/add_pin_bottom_sheet.dart';
import '../providers/map_camera_provider.dart';
import '../providers/map_fab_provider.dart';

/// 地図画面の右下にフローティング表示するボタン群
///
/// 上から順に:
///   1. ピン追加ボタン   （isFolderSelected = true のみ表示）
///   2. トラック記録ボタン（isFolderSelected = true のみ表示）
///   3. 現在地追従ボタン （currentLocation != null のみ表示）
///   4. ズームイン
///   5. ズームアウト
class MapFabButtons extends ConsumerWidget {
  final MapController mapController;

  const MapFabButtons({
    super.key,
    required this.mapController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fabState = ref.watch(mapFabProvider);
    final mapCamera = ref.watch(mapCameraProvider);
    final currentCenter = LatLng(mapCamera.latitude, mapCamera.longitude);
    final currentZoom = mapCamera.zoom;

    // 全てのボタンで共通して使用するサイズ変数
    const double buttonSize = 56.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [

        // ── 1. ピン追加ボタン ─────────────────────────────────────────────
        if (fabState.isFolderSelected) ...[
          AppFloatingButton(
            heroTag: 'pinAdd',
            icon: Icon(
              fabState.isPinAddMode
                  ? Icons.add_location
                  : Icons.add_location_alt_outlined,
              color: Colors.white,
            ),
            backgroundColor: fabState.isPinAddMode
                ? const Color(0xFFD4A017)
                : const Color(0xFF2D6A4F),
            tooltip: fabState.isPinAddMode ? '中央の位置にピンを追加' : 'ピン追加モード',
            baseHeight: buttonSize,
            onPressed: () {
              if (fabState.isPinAddMode) {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => Padding(
                    padding: MediaQuery.of(context).viewInsets,
                    child: AddPinBottomSheet(
                      position: currentCenter,
                      onSave: ({
                        required String title,
                        required String memo,
                        required String colorHex,
                      }) async {
                        await ref
                            .read(mapFabProvider.notifier)
                            .addPinAtCenter(
                          position: currentCenter,
                          title: title,
                          memo: memo,
                          colorHex: colorHex,
                        );
                      },
                    ),
                  ),
                ).then((_) {
                  ref.read(mapFabProvider.notifier).disablePinAddMode();
                });
              } else {
                ref.read(mapFabProvider.notifier).enablePinAddMode();
              }
            },
          ),
          const SizedBox(height: 10),
        ],

        // ── 2. トラック記録ボタン ─────────────────────────────────────────
        if (fabState.isFolderSelected) ...[
          AppFloatingButton(
            heroTag: 'trackRecord',
            icon: Icon(
              fabState.isTracking
                  ? Icons.stop_circle_outlined
                  : Icons.fiber_manual_record,
              color: Colors.white,
            ),
            backgroundColor:
            fabState.isTracking ? Colors.red[700] : Colors.red,
            tooltip: fabState.isTracking ? '記録を停止' : '移動記録を開始',
            baseHeight: buttonSize,
            onPressed: () async {
              if (fabState.isTracking) {
                await ref.read(mapFabProvider.notifier).stopTracking();
              } else {
                await ref.read(mapFabProvider.notifier).startTracking();
              }
            },
          ),
          const SizedBox(height: 10),
        ],

        // ── 3. 現在地追従ボタン ───────────────────────────────────────────
        if (fabState.currentLocation != null) ...[
          AppFloatingButton(
            heroTag: 'followLocation',
            icon: Icon(
              fabState.isFollowingLocation
                  ? Icons.my_location
                  : Icons.location_searching,
              color: fabState.isFollowingLocation
                  ? Colors.white
                  : Colors.grey[600],
            ),
            backgroundColor:
            fabState.isFollowingLocation ? Colors.blue : Colors.white,
            tooltip: fabState.isFollowingLocation ? '追従を解除' : '現在地に追従',
            baseHeight: buttonSize,
            onPressed: () {
              if (fabState.isFollowingLocation) {
                ref.read(mapFabProvider.notifier).disableFollowing();
              } else {
                ref.read(mapFabProvider.notifier).enableFollowing();
                final loc = fabState.currentLocation!;
                mapController.move(loc, mapController.camera.zoom);
              }
            },
          ),
          const SizedBox(height: 10),
        ],

        // ── 4. ズームイン ────────────────────────────────────────────────
        AppFloatingButton(
          heroTag: 'zoomIn',
          icon: const Icon(Icons.add, color: Colors.black),
          backgroundColor: Colors.white,
          baseHeight: buttonSize,
          onPressed: () {
            try {
              if (currentZoom < AppConstants.maxZoom) {
                mapController.move(currentCenter, currentZoom + 1);
              }
            } catch (_) {}
          },
        ),
        const SizedBox(height: 10),

        // ── 5. ズームアウト ──────────────────────────────────────────────
        AppFloatingButton(
          heroTag: 'zoomOut',
          icon: const Icon(Icons.remove, color: Colors.black),
          backgroundColor: Colors.white,
          baseHeight: buttonSize,
          onPressed: () {
            try {
              if (currentZoom > AppConstants.minZoom) {
                mapController.move(currentCenter, currentZoom - 1);
              }
            } catch (_) {}
          },
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}