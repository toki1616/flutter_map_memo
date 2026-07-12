import '../entities/map_camera_state.dart';

abstract class MapCameraRepository {
  Future<MapCameraState?> getLastCamera();
  Future<void> saveCamera(MapCameraState cameraState);
}