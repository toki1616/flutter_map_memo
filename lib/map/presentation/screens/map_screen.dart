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
import '../../../pin/presentation/widgets/add_pin_bottom_sheet.dart';
import '../../../pin/presentation/widgets/pin_marker_layer.dart';
import '../../../setting/presentation/providers/text_scale_provider.dart';

import '../providers/map_camera_provider.dart';
import '../providers/map_selection_provider.dart';
import '../providers/map_url_source_provider.dart';

import '../widgets/coordinate_display.dart';
import '../widgets/crosshair_painter.dart';
import '../widgets/map_fab_buttons.dart';

/// マップ画面
/// - URL タイル表示（flutter_map_tile_caching キャッシュ付き）
/// - ピンマーカー表示（PinMarkerLayer）
/// - 現在地マーカー表示（location/ の locationStreamProvider を参照）
/// - ピン追加 FAB（マップ中央座標に追加）
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  late final MapController _mapController;

  /// ピン追加モードフラグ
  /// false: 通常モード
  /// true : 「地図を動かして位置を決め、ボタンを押してピン追加」モード
  bool _pinAddMode = false;

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
    final textScaleType = ref.watch(textScaleProvider);
    final textTheme = Theme.of(context).textTheme;
    final scale = textScaleType.scale;

    // location/ の StreamProvider を参照して現在地を取得
    final locationAsync = ref.watch(locationStreamProvider);
    final currentLocation = locationAsync.valueOrNull;

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
              // 💡 現在地へ移動ボタン（取得済みのときのみ表示）
              if (currentLocation != null)
                IconButton(
                  icon: const Icon(Icons.my_location),
                  tooltip: '現在地へ移動',
                  onPressed: () {
                    _mapController.move(
                      LatLng(currentLocation.latitude,
                          currentLocation.longitude),
                      _mapController.camera.zoom,
                    );
                  },
                ),
              // マップソース切替ドロップダウン
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
                    ref
                        .read(mapSelectionProvider.notifier)
                        .selectMap(selected);
                  }
                },
              ),
              const SizedBox(width: 16),
            ],
          ),
          body: Stack(
            children: [
              // ── 地図本体 ───────────────────────────────────────────────
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
                  },
                ),
                children: [
                  // URL タイルレイヤー（オンラインキャッシュ付き）
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
                  // 縮尺バー
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

                  // 💡 現在地マーカー（location/ の LocationData エンティティを使用）
                  if (currentLocation != null)
                    _CurrentLocationLayer(location: currentLocation),

                  // ピンマーカーレイヤー（フォルダ選択済みのみ）
                  if (folder != null) const PinMarkerLayer(),
                ],
              ),

              // ── クロスヘア（常時中央表示）──────────────────────────────
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

              // ── フォルダ未選択バナー ────────────────────────────────────
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

              // ── ピン追加モードのガイドバナー ────────────────────────────
              if (_pinAddMode)
                Positioned(
                  top: 12,
                  left: 16,
                  right: 16,
                  child: SafeArea(
                    child: GestureDetector(
                      onTap: () => setState(() => _pinAddMode = false),
                      child: Card(
                        color: AppTheme.primary.withValues(alpha: 0.92),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          child: Row(
                            children: [
                              const Icon(Icons.touch_app_outlined,
                                  color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '地図を動かして中央（十字）の位置に合わせ、'
                                      'ピンボタンを押して追加',
                                  style: textTheme.bodyMedium
                                      ?.copyWith(color: Colors.white),
                                ),
                              ),
                              const Icon(Icons.close,
                                  color: Colors.white70, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // ── FAB群（右下）────────────────────────────────────────────
              SafeArea(
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: EdgeInsets.only(
                        bottom: 16 * scale, right: 16 * scale),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // ピン追加 FAB（フォルダ選択済みのみ表示）
                        if (folder != null) ...[
                          _PinAddFab(
                            scale: scale,
                            isActive: _pinAddMode,
                            onTap: () {
                              if (_pinAddMode) {
                                // アクティブ状態でタップ → 現在の中央座標でボトムシートを開く
                                final cam = ref.read(mapCameraProvider);
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  builder: (_) => Padding(
                                    padding:
                                    MediaQuery.of(context).viewInsets,
                                    child: AddPinBottomSheet(
                                      position: LatLng(
                                          cam.latitude, cam.longitude),
                                    ),
                                  ),
                                ).then((_) {
                                  if (mounted) {
                                    setState(() => _pinAddMode = false);
                                  }
                                });
                              } else {
                                // 非アクティブ → モード ON
                                setState(() => _pinAddMode = true);
                              }
                            },
                          ),
                          SizedBox(height: 10 * scale),
                        ],
                        // ズームイン・アウトボタン
                        MapFabButtons(mapController: _mapController),
                      ],
                    ),
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

/// 💡 現在地を青い点 + 精度円で表示する
/// location/ の LocationData エンティティを受け取り描画する
class _CurrentLocationLayer extends StatelessWidget {
  final LocationData location;
  const _CurrentLocationLayer({required this.location});

  @override
  Widget build(BuildContext context) {
    final point = LatLng(location.latitude, location.longitude);

    return Stack(
      children: [
        // 精度を示す薄い青円（半径 = accuracy メートル）
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
        // 現在地を示す青い点マーカー
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

// ── ピン追加 FAB ──────────────────────────────────────────────────────────

class _PinAddFab extends StatelessWidget {
  final double scale;
  final bool isActive;
  final VoidCallback onTap;

  const _PinAddFab({
    required this.scale,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56 * scale,
      height: 56 * scale,
      child: FloatingActionButton(
        heroTag: 'pinAdd',
        onPressed: onTap,
        backgroundColor: isActive ? AppTheme.accent : AppTheme.primary,
        tooltip: isActive ? '中央の位置にピンを追加' : 'ピン追加モード',
        child: Icon(
          isActive
              ? Icons.add_location
              : Icons.add_location_alt_outlined,
          color: Colors.white,
          size: 24 * scale,
        ),
      ),
    );
  }
}