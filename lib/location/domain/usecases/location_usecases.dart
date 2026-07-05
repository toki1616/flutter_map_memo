import '../../../core/usecases/usecase.dart';
import '../entities/location_data.dart';
import '../repositories/location_repository.dart';

/// 位置情報の権限確認・リクエストを行うユースケース
class RequestLocationPermissionUseCase implements UseCase<bool, NoParams> {
  final LocationRepository _repository;
  RequestLocationPermissionUseCase(this._repository);

  @override
  Future<bool> call(NoParams params) => _repository.requestPermission();
}

/// 現在地を一度だけ取得するユースケース
class GetCurrentLocationUseCase implements UseCase<LocationData?, NoParams> {
  final LocationRepository _repository;
  GetCurrentLocationUseCase(this._repository);

  @override
  Future<LocationData?> call(NoParams params) =>
      _repository.getCurrentLocation();
}

/// 現在地を継続監視する Stream を返すユースケース
class WatchLocationUseCase {
  final LocationRepository _repository;
  WatchLocationUseCase(this._repository);

  Stream<LocationData?> call() => _repository.watchLocation();
}
