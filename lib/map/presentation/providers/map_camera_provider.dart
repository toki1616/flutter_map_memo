import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/map_camera_storage_datasource.dart';
import '../../data/repositories/map_camera_repository_impl.dart';
import '../../domain/entities/map_camera_state.dart';
import '../../domain/repositories/map_camera_repository.dart';

// ── DI ───────────────────────────────────────────────────────────────────

final mapCameraStorageDataSourceProvider = Provider<MapCameraStorageDataSource>(
  (ref) => MapCameraStorageDataSourceImpl(),
);

final mapCameraRepositoryProvider = Provider<MapCameraRepository>(
  (ref) => MapCameraRepositoryImpl(ref.watch(mapCameraStorageDataSourceProvider)),
);

// ── StateNotifier ─────────────────────────────────────────────────────────

class MapCameraNotifier extends StateNotifier<MapCameraState> {
  final MapCameraRepository _repository;

  // 初期起動時（キャッシュがまだ無いとき）のデフォルト位置（東京駅周辺）
  static const double _defaultLat = 35.681236;
  static const double _defaultLng = 139.767125;
  static const double _defaultZoom = 12.0;

  MapCameraNotifier(this._repository)
      : super(const MapCameraState(
          latitude: _defaultLat,
          longitude: _defaultLng,
          zoom: _defaultZoom,
        )) {
    // 💡 起動時に専用のストレージファイルからカメラ位置を自動で復元
    _loadSavedCamera();
  }

  /// ストレージファイルからカメラ状態を読み出す
  Future<void> _loadSavedCamera() async {
    final cached = await _repository.getLastCamera();
    if (cached != null) {
      state = cached;
    }
  }

  /// 画面が動かされたときに呼び出され、状態更新と専用ファイルへの自動保存を行う
  void updateCamera(double latitude, double longitude, double zoom) {
    final updated = state.copyWith(
      latitude: latitude,
      longitude: longitude,
      zoom: zoom,
    );

    state = updated;

    // 非同期で位置情報ストレージにのみ書き込みを実施（settings.jsonは触らない）
    _repository.saveCamera(updated);
  }
}

final mapCameraProvider =
    StateNotifierProvider<MapCameraNotifier, MapCameraState>((ref) {
  return MapCameraNotifier(ref.watch(mapCameraRepositoryProvider));
});
