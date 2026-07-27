import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../domain/entities/map_camera_state.dart';

abstract class MapCameraStorageDataSource {
  Future<MapCameraState?> loadCameraStorage();
  Future<void> saveCameraStorage(MapCameraState cameraState);
}

class MapCameraStorageDataSourceImpl implements MapCameraStorageDataSource {
  /// 保存先パス: Documents/save_data/cache/map_camera.json
  Future<File> _getStorageFile() async {
    final docDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory(p.join(docDir.path, 'save_data', 'cache'));
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return File(p.join(cacheDir.path, 'map_camera.json'));
  }

  @override
  Future<MapCameraState?> loadCameraStorage() async {
    try {
      final file = await _getStorageFile();
      if (!await file.exists()) return null;

      final jsonString = await file.readAsString();
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);

      return MapCameraState(
        latitude: (jsonMap['latitude'] as num).toDouble(),
        longitude: (jsonMap['longitude'] as num).toDouble(),
        zoom: (jsonMap['zoom'] as num).toDouble(),
      );
    } catch (e) {
      print('【MapCameraStorage】ストレージ読み込み失敗: $e');
      return null;
    }
  }

  @override
  Future<void> saveCameraStorage(MapCameraState cameraState) async {
    try {
      final file = await _getStorageFile();
      final jsonMap = {
        'latitude': cameraState.latitude,
        'longitude': cameraState.longitude,
        'zoom': cameraState.zoom,
      };
      await file.writeAsString(jsonEncode(jsonMap));
    } catch (e) {
      print('【MapCameraStorage】ストレージ書き込み失敗: $e');
    }
  }
}