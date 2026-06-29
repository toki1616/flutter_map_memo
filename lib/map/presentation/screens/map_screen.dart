import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_constants.dart';
import '../../../setting/presentation/providers/text_scale_provider.dart';
import '../providers/map_camera_provider.dart';
import '../providers/map_selection_provider.dart';
import '../providers/map_url_source_provider.dart';

import '../widgets/coordinate_display.dart';
import '../widgets/crosshair_painter.dart';
import '../widgets/map_fab_buttons.dart';

/// flutter_mapパッケージを使用して実際に地図を画面に描画するUIファイル
/// mapCameraProviderと連携し、ユーザーの地図操作（スクロール・ズーム）による位置変化をリアルタイムにプロバイダーへ同期
/// Stack構造を利用して、地図の前面に画面中央の十字照準（Crosshair）および最新の緯度経度を示すCoordinateDisplayをレイヤー表示する設計
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  // ➔ コントローラーをStateクラス内で遅延初期化（late）として管理
  // 画面のリビルドや親の再生成が発生しても、このStateオブジェクトが存続する限りインスタンスは完全に永続化されます
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    // メモリリークを防ぐため、画面破棄時にコントローラーも適切に解放
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // AsyncValue<List<MapUrlConfig>> として取得されるマップソースを監視
    final mapSourcesAsync = ref.watch(mapUrlSourceProvider);
    // 現在選択されているマップ設定（MapUrlConfig?）を監視
    final currentUrlMap = ref.watch(mapSelectionProvider);

    // 表示サイズ設定を監視し、テキストテーマを取得
    final textScaleType = ref.watch(textScaleProvider);
    final textTheme = Theme.of(context).textTheme;

    // 非同期データ（mapSourcesAsync）の状態（ローディング、エラー、データ成功）に応じてUIを分岐処理
    return mapSourcesAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => const Scaffold(
        body: Center(child: Text('マップの読み込みに失敗しました')),
      ),
      data: (availableUrlMaps) {
        // マップリストが空、または選択中のマップがまだ未定（null）の場合はローディング表示でガード
        if (availableUrlMaps.isEmpty || currentUrlMap == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('フィールドマップ'),
            actions: [
              DropdownButton<String>(
                value: currentUrlMap.id,
                dropdownColor: Theme.of(context).colorScheme.surface,
                style: textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface),
                underline: const SizedBox(),
                items: availableUrlMaps.map((map) {
                  return DropdownMenuItem<String>(
                    value: map.id,
                    child: Text(
                      map.name,
                      style: textTheme.bodyMedium,
                    ),
                  );
                }).toList(),
                onChanged: (String? selectedId) {
                  if (selectedId != null) {
                    final selectedMap = availableUrlMaps.firstWhere((m) => m.id == selectedId);
                    ref.read(mapSelectionProvider.notifier).selectMap(selectedMap);
                  }
                },
              ),
              const SizedBox(width: 16),
            ],
          ),
          body: Stack(
            children: [
              // 地図本体レイヤー
              FlutterMap(
                // 永続化されたコントローラーを安全にセット
                mapController: _mapController,
                options: MapOptions(
                  // 初期位置と初期ズームをプロバイダーの保持データから取得
                  initialCenter: LatLng(
                    ref.read(mapCameraProvider).latitude,
                    ref.read(mapCameraProvider).longitude,
                  ),
                  initialZoom: ref.read(mapCameraProvider).zoom,
                  minZoom: AppConstants.minZoom,
                  maxZoom: AppConstants.maxZoom,

                  // ユーザーが地図を動かした瞬間に、中心座標とズームレベルをプロバイダーへ即座に書き込み
                  onPositionChanged: (camera, hasGesture) {
                    ref.read(mapCameraProvider.notifier).updateCamera(
                      camera.center.latitude,
                      camera.center.longitude,
                      camera.zoom,
                    );
                  },
                ),
                children: [
                  // URL Map Layer
                  TileLayer(
                    urlTemplate: currentUrlMap.urlTemplate,
                    userAgentPackageName: 'com.example.map_app',
                    tileProvider: FMTCTileProvider(
                      stores: const {
                        'custom_url_map_cache': BrowseStoreStrategy.readUpdateCreate,
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

                  // 縮尺バー（Scalebar）
                  Scalebar(
                    alignment: Alignment.topLeft,
                    padding: EdgeInsets.only(
                      top: 16 * textScaleType.scale,
                      left: 16 * textScaleType.scale,
                    ),
                    textStyle: TextStyle(
                      color: Colors.black,
                      // テーマ全体の拡大倍率（textScaleType.scale）を適用して動的にスケール
                      fontSize: 12 * textScaleType.scale,
                      fontWeight: FontWeight.bold,
                    ),
                    lineColor: Colors.black,
                    strokeWidth: 2,
                  ),
                ],
              ),

              // 画面中央の十字レイヤー
              Center(
                child: IgnorePointer(
                  child: CustomPaint(
                    size: Size(32 * textScaleType.scale, 32 * textScaleType.scale),
                    painter: CrosshairPainter(),
                  ),
                ),
              ),

              // 緯度経度・ズーム表示ウィジェット
              SafeArea(
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: 16 * textScaleType.scale,
                      right: 16 * textScaleType.scale,
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        CoordinateDisplay(),
                      ],
                    ),
                  ),
                ),
              ),

              // 右下にフローティング配置するズームイン・ズームアウトボタン
              SafeArea(
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: 16 * textScaleType.scale,
                      right: 16 * textScaleType.scale,
                    ),
                    child: MapFabButtons(mapController: _mapController), // コントローラーをアタッチ
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