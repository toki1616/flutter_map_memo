import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../folder/presentation/providers/folder_provider.dart';
import '../../../location/domain/entities/location_data.dart';
import '../../../location/presentation/providers/location_provider.dart';
import '../../../pin/presentation/widgets/pin_marker_layer.dart';
import '../../../setting/presentation/providers/text_scale_provider.dart';
import '../../../track/domain/entities/track_log.dart';
import '../../../track/presentation/providers/track_provider.dart';
import '../providers/map_camera_provider.dart';
import '../providers/map_fab_provider.dart';
import '../providers/map_selection_provider.dart';
import '../providers/map_url_source_provider.dart';
import '../widgets/coordinate_display.dart';
import '../widgets/crosshair_painter.dart';
import '../widgets/map_fab_buttons.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mapSourcesAsync = ref.watch(mapUrlSourceProvider);
    final currentUrlMap = ref.watch(mapSelectionProvider);
    final folderAsync = ref.watch(folderProvider);
    final scale = ref.watch(textScaleProvider).scale;
    final textTheme = Theme.of(context).textTheme;

    final locationAsync = ref.watch(locationStreamProvider);
    final currentLocation = locationAsync.valueOrNull;

    // 保存済みトラックログ一覧
    final trackLogsAsync = ref.watch(trackListProvider);
    final trackLogs = trackLogsAsync.valueOrNull ?? [];

    // 現在記録中のトラックログ（リアルタイム表示用）
    final currentTrackLog = ref.watch(mapFabProvider.notifier).currentTrackLog;

    // 追従モード: GPS 更新のたびに地図を移動
    ref.listen(followLocationTargetProvider, (_, latLng) {
      if (latLng == null) return;
      _mapController.move(latLng, _mapController.camera.zoom);
    });

    return mapSourcesAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => const Scaffold(
          body: Center(child: Text('マップの読み込みに失敗しました'))),
      data: (availableUrlMaps) {
        if (availableUrlMaps.isEmpty || currentUrlMap == null) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final folder = folderAsync.valueOrNull;

        return Scaffold(
          appBar: AppBar(
            title: const Text('フィールドマップ'),
            actions: [
              DropdownButton<String>(
                value: currentUrlMap.id,
                dropdownColor: Theme.of(context).colorScheme.surface,
                style: textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface),
                underline: const SizedBox(),
                items: availableUrlMaps.map((map) {
                  return DropdownMenuItem<String>(
                    value: map.id,
                    child: Text(map.name, style: textTheme.bodyMedium),
                  );
                }).toList(),
                onChanged: (String? selectedId) {
                  if (selectedId != null) {
                    final selected = availableUrlMaps
                        .firstWhere((m) => m.id == selectedId);
                    ref.read(mapSelectionProvider.notifier).selectMap(selected);
                  }
                },
              ),
              const SizedBox(width: 16),
            ],
          ),
          body: Stack(
            children: [
              // ── 地図本体 ─────────────────────────────────────────────────
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: LatLng(
                    ref.read(mapCameraProvider).latitude,
                    ref.read(mapCameraProvider).longitude,
                  ),
                  initialZoom: ref.read(mapCameraProvider).zoom,
                  minZoom: AppConstants.minZoom,
                  maxZoom: AppConstants.maxZoom,
                  onPositionChanged: (camera, hasGesture) {
                    ref.read(mapCameraProvider.notifier).updateCamera(
                          camera.center.latitude,
                          camera.center.longitude,
                          camera.zoom,
                        );
                    if (hasGesture) {
                      ref
                          .read(mapFabProvider.notifier)
                          .stopFollowingIfNeeded(hasGesture);
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: currentUrlMap.urlTemplate,
                    userAgentPackageName: 'com.example.map_app',
                    tileProvider: FMTCTileProvider(
                      stores: const {
                        'custom_url_map_cache':
                            BrowseStoreStrategy.readUpdateCreate,
                      },
                    ),
                  ),
                  if (currentUrlMap.attribution != null)
                    RichAttributionWidget(
                      attributions: [
                        TextSourceAttribution(
                          currentUrlMap.attribution!,
                          prependCopyright: false,
                        ),
                      ],
                    ),
                  Scalebar(
                    alignment: Alignment.topLeft,
                    padding: EdgeInsets.only(
                        top: 16 * scale, left: 16 * scale),
                    textStyle: TextStyle(
                      color: Colors.black,
                      fontSize: 12 * scale,
                      fontWeight: FontWeight.bold,
                    ),
                    lineColor: Colors.black,
                    strokeWidth: 2,
                  ),

                  // ── 保存済みトラックログの表示 ──────────────────────────
                  if (trackLogs.isNotEmpty)
                    PolylineLayer(
                      polylines: trackLogs
                          .where((log) => log.points.length >= 2)
                          .map((log) => Polyline(
                                points: log.points
                                    .map((p) =>
                                        LatLng(p.latitude, p.longitude))
                                    .toList(),
                                color: Colors.blue.withValues(alpha: 0.6),
                                strokeWidth: 3,
                              ))
                          .toList(),
                    ),

                  // ── 現在記録中のトラック（リアルタイム表示）──────────────
                  if (currentTrackLog != null &&
                      currentTrackLog.points.length >= 2)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: currentTrackLog.points
                              .map((p) => LatLng(p.latitude, p.longitude))
                              .toList(),
                          color: Colors.red,
                          strokeWidth: 4,
                        ),
                      ],
                    ),

                  // 現在地マーカー
                  if (currentLocation != null)
                    _CurrentLocationLayer(location: currentLocation),

                  // ピンマーカーレイヤー
                  if (folder != null) const PinMarkerLayer(),
                ],
              ),

              // ── クロスヘア ───────────────────────────────────────────────
              Center(
                child: IgnorePointer(
                  child: CustomPaint(
                    size: Size(32 * scale, 32 * scale),
                    painter: CrosshairPainter(),
                  ),
                ),
              ),

              // ── 座標表示（右上）─────────────────────────────────────────
              SafeArea(
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: EdgeInsets.only(
                        top: 16 * scale, right: 16 * scale),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [CoordinateDisplay()],
                    ),
                  ),
                ),
              ),

              // ── 記録中バナー ─────────────────────────────────────────────
              if (ref.watch(mapFabProvider).isTracking)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: Container(
                      color: Colors.red.withValues(alpha: 0.85),
                      padding: EdgeInsets.symmetric(
                          vertical: 4 * scale, horizontal: 12 * scale),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.fiber_manual_record,
                              color: Colors.white, size: 14 * scale),
                          SizedBox(width: 6 * scale),
                          Text(
                            '記録中'
                            '${currentTrackLog != null ? '  ${currentTrackLog.points.length}pt  '
                                '${currentTrackLog.totalDistanceKm.toStringAsFixed(2)}km' : ''}',
                            style: textTheme.bodyMedium
                                ?.copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // ── フォルダ未選択バナー ─────────────────────────────────────
              if (folder == null)
                Positioned(
                  bottom: 120 * scale,
                  left: 16,
                  right: 80,
                  child: Card(
                    color: AppTheme.accent.withValues(alpha: 0.92),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          const Icon(Icons.folder_open_outlined,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '設定画面でマップフォルダを選択するとピンを追加できます',
                              style: textTheme.bodyMedium
                                  ?.copyWith(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // ── FAB 群（右下）───────────────────────────────────────────
              SafeArea(
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: EdgeInsets.only(
                        bottom: 16 * scale, right: 16 * scale),
                    child: MapFabButtons(mapController: _mapController),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── 現在地マーカーレイヤー ─────────────────────────────────────────────────

class _CurrentLocationLayer extends StatelessWidget {
  final LocationData location;
  const _CurrentLocationLayer({required this.location});

  @override
  Widget build(BuildContext context) {
    final point = LatLng(location.latitude, location.longitude);
    return Stack(
      children: [
        CircleLayer(
          circles: [
            CircleMarker(
              point: point,
              radius: location.accuracy,
              useRadiusInMeter: true,
              color: Colors.blue.withValues(alpha: 0.15),
              borderColor: Colors.blue.withValues(alpha: 0.4),
              borderStrokeWidth: 1,
            ),
          ],
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: point,
              width: 20,
              height: 20,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.4),
                      blurRadius: 6,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
