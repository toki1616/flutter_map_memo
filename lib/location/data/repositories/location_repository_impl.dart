import '../../domain/entities/location_data.dart';
import '../../domain/repositories/location_repository.dart';
import '../datasources/location_datasource.dart';

/// LocationRepository の実装クラス
/// LocationDataSource に処理を委譲する
class LocationRepositoryImpl implements LocationRepository {
  final LocationDataSource _dataSource;
  LocationRepositoryImpl(this._dataSource);

  @override
  Future<bool> requestPermission() => _dataSource.requestPermission();

  @override
  Future<LocationData?> getCurrentLocation() =>
      _dataSource.getCurrentLocation();

  @override
  Stream<LocationData?> watchLocation() => _dataSource.watchLocation();
}
