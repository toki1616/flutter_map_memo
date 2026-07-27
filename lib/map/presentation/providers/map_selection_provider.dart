import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/map_url_config.dart';
import 'map_url_source_provider.dart';

// ユーザーが現在どのマップ画面を表示しているかという選択状態を管理するRiverpodのプロバイダーファイル
// プルダウン等で選択が切り替わった際に新しいマップ設定を保持し、画面の再描画を制御
class MapSelectionNotifier extends StateNotifier<MapUrlConfig?> {
  MapSelectionNotifier() : super(null);

  void selectMap(MapUrlConfig config) {
    state = config;
  }
}

final mapSelectionProvider = StateNotifierProvider<MapSelectionNotifier, MapUrlConfig?>((ref) {
  final notifier = MapSelectionNotifier();

  ref.listen(mapUrlSourceProvider, (previous, next) {
    next.whenData((sources) {
      if (notifier.state == null && sources.isNotEmpty) {
        notifier.selectMap(sources.first);
      }
    });
  });

  return notifier;
});