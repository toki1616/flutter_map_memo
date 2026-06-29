import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_constants.dart';
import '../providers/map_selection_provider.dart';
import '../providers/map_url_source_provider.dart';

/// flutter_mapパッケージを使用して実際に地図を画面に描画するUIファイル
/// プロバイダーから現在の選択マップやマップソース一覧、コア層の定数からズーム値を読み込み、自動キャッシュ機能を持った地図層を構築して表示
class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapSourcesAsync = ref.watch(mapUrlSourceProvider);
    final currentUrlMap = ref.watch(mapSelectionProvider);

    return mapSourcesAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => const Scaffold(
        body: Center(child: Text('マップの読み込みに失敗しました')),
      ),
      data: (availableUrlMaps) {
        if (currentUrlMap == null) {
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
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                items: availableUrlMaps.map((map) {
                  return DropdownMenuItem<String>(
                    value: map.id,
                    child: Text(map.name),
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
            ],
          ),
        );
      },
    );
  }
}