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
/// 【Clean Architecture における役割】
/// UI 層として mapFabProvider と mapCameraProvider のみを参照する。
/// folder / location / pin の各 feature への直接依存はゼロ。
/// ビジネスロジック（ピン追加・追従制御）は mapFabProvider に委譲する。
///
/// 上から順に:
///   1. ピン追加ボタン   （isFolderSelected = true のみ表示）
///   2. 現在地追従ボタン （currentLocation != null のみ表示）
///   3. ズームイン
///   4. ズームアウト
class MapFabButtons extends ConsumerWidget {
  final MapController mapController;

  const MapFabButtons({
    super.key,
    required this.mapController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 参照するのは map feature 内の Provider のみ
    final fabState = ref.watch(mapFabProvider);
    final mapCamera = ref.watch(mapCameraProvider);
    final currentCenter = LatLng(mapCamera.latitude, mapCamera.longitude);
    final currentZoom = mapCamera.zoom;

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
                ? const Color(0xFFD4A017)  // accent
                : const Color(0xFF2D6A4F), // primary
            tooltip: fabState.isPinAddMode ? '中央の位置にピンを追加' : 'ピン追加モード',
            onPressed: () {
              if (fabState.isPinAddMode) {
                // モード ON → ボトムシートを開いてピン追加
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
                // モード OFF → ON にする
                ref.read(mapFabProvider.notifier).enablePinAddMode();
              }
            },
          ),
          const SizedBox(height: 10),
        ],

        // ── 2. 現在地追従ボタン ───────────────────────────────────────────
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
            baseHeight: 48.0,
            onPressed: () {
              if (fabState.isFollowingLocation) {
                ref.read(mapFabProvider.notifier).disableFollowing();
              } else {
                // 追従 ON + 現在地へ即時移動
                ref.read(mapFabProvider.notifier).enableFollowing();
                final loc = fabState.currentLocation!;
                mapController.move(loc, mapController.camera.zoom);
              }
            },
          ),
          const SizedBox(height: 10),
        ],

        // ── 3. ズームイン ────────────────────────────────────────────────
        AppFloatingButton(
          heroTag: 'zoomIn',
          icon: const Icon(Icons.add, color: Colors.black),
          backgroundColor: Colors.white,
          onPressed: () {
            try {
              if (currentZoom < AppConstants.maxZoom) {
                mapController.move(currentCenter, currentZoom + 1);
              }
            } catch (_) {}
          },
        ),
        const SizedBox(height: 10),

        // ── 4. ズームアウト ──────────────────────────────────────────────
        AppFloatingButton(
          heroTag: 'zoomOut',
          icon: const Icon(Icons.remove, color: Colors.black),
          backgroundColor: Colors.white,
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
