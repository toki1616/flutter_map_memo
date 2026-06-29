import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/map_url_config.dart';
import '../../domain/usecases/fetch_map_url_sources.dart';
import '../../../core/usecases/usecase.dart';

// ユースケースを実行し、アプリ内で利用可能なURL指定のマップ設定一覧を保持・提供するRiverpodのプロバイダーファイル
// 将来的にデータソースがローカル画像などに拡張された際も、UIに影響を与えずにデータを管理
final fetchMapUrlSourcesProvider = Provider((ref) => FetchMapUrlSources());

final mapUrlSourceProvider = FutureProvider<List<MapUrlConfig>>((ref) async {
  final useCase = ref.watch(fetchMapUrlSourcesProvider);

  try {
    final sources = await useCase.call(const NoParams());
    if (sources.isEmpty) {
      return [
        MapUrlConfig(
          id: 'osm_standard',
          name: 'OpenStreetMap',
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        )
      ];
    }
    return sources;
  } catch (error) {
    return [
      MapUrlConfig(
        id: 'osm_standard',
        name: 'OpenStreetMap',
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      )
    ];
  }
});