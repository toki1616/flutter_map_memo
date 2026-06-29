import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_constants.dart';
import '../../../setting/presentation/providers/text_scale_provider.dart';
import '../providers/map_selection_provider.dart';
import '../providers/map_url_source_provider.dart';

/// flutter_mapパッケージを使用して実際に地図を画面に描画するUIファイル
/// プロバイダーから現在の選択マップやマップソース一覧を読み込み、アプリ全体の表示サイズ設定と連動してヘッダーのドロップダウンメニューの大きさも自動調節
class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // AsyncValue<List<MapUrlConfig>> として取得されるマップソースを監視
    final mapSourcesAsync = ref.watch(mapUrlSourceProvider);
    // 現在選択されているマップ設定（MapUrlConfig?）を監視
    final currentUrlMap = ref.watch(mapSelectionProvider);

    // 表示サイズ設定を監視し、テキストテーマを取得
    ref.watch(textScaleProvider);
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
          body: FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(35.681236, 139.767125),
              initialZoom: AppConstants.defaultZoom,
              minZoom: AppConstants.minZoom,
              maxZoom: AppConstants.maxZoom,
            ),
            children: [
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
            ],
          ),
        );
      },
    );
  }
}