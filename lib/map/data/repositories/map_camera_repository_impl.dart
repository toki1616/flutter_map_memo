import '../../domain/entities/map_camera_state.dart';
import '../../domain/repositories/map_camera_repository.dart';
import '../datasources/map_camera_storage_datasource.dart';

class MapCameraRepositoryImpl implements MapCameraRepository {
  final MapCameraStorageDataSource _dataSource;
  MapCameraRepositoryImpl(this._dataSource);

  @override
  Future<MapCameraState?> getLastCamera() => _dataSource.loadCameraStorage();

  @override
  Future<void> saveCamera(MapCameraState cameraState) => _dataSource.saveCameraStorage(cameraState);
}