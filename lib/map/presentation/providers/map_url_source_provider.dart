import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/map_url_config.dart';
import '../../domain/usecases/fetch_map_url_sources.dart';
import '../../../core/usecases/usecase.dart';

final fetchMapUrlSourcesProvider = Provider((ref) => FetchMapUrlSources());

final mapUrlSourceProvider = FutureProvider<List<MapUrlConfig>>((ref) async {
  final useCase = ref.watch(fetchMapUrlSourcesProvider);

  // デフォルトのバックアップマップ
  final defaultOSM = [
    MapUrlConfig(
      id: 'osm_standard',
      name: 'OpenStreetMap',
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    )
  ];

  try {
    // 💡 1.5秒待ってもユースケースから応答がない場合はタイムアウトさせてデフォルトを返す
    final sources = await useCase
        .call(const NoParams())
        .timeout(const Duration(milliseconds: 1500));

    if (sources.isEmpty) {
      return defaultOSM;
    }
    return sources;
  } catch (error) {
    print('【mapUrlSourceProvider】読み込みエラーまたはタイムアウト: $error');
    return defaultOSM;
  }
});