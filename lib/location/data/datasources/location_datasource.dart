import 'dart:io';
import 'package:geolocator/geolocator.dart';
import '../../domain/entities/location_data.dart';

/// geolocator パッケージを使って位置情報を取得するデータソース
/// iOS / Android の設定の差異をここで吸収する
abstract class LocationDataSource {
  Future<bool> requestPermission();
  Future<LocationData?> getCurrentLocation();
  Stream<LocationData?> watchLocation();
}

class LocationDataSourceImpl implements LocationDataSource {
  /// 位置情報サービスの有効確認 → 権限確認 → 権限リクエストを順に実行する
  @override
  Future<bool> requestPermission() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 現在地を一度だけ取得する（精度: high）
  @override
  Future<LocationData?> getCurrentLocation() async {
    try {
      final granted = await requestPermission();
      if (!granted) return null;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: _buildLocationSettings(),
      );
      return _toLocationData(position);
    } catch (_) {
      return null;
    }
  }

  /// 現在地を継続監視する Stream
  @override
  Stream<LocationData?> watchLocation() async* {
    try {
      final granted = await requestPermission();
      if (!granted) {
        yield null;
        return;
      }

      yield* Geolocator.getPositionStream(
        locationSettings: _buildLocationSettings(),
      ).map(_toLocationData);
    } catch (_) {
      yield null;
    }
  }

  // ── 内部ヘルパー ─────────────────────────────────────────────────────────

  LocationData _toLocationData(Position position) => LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
      );

  /// iOS / Android ごとに最適な位置情報設定を返す
  LocationSettings _buildLocationSettings() {
    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // 5m 移動で更新
      );
    } else if (Platform.isIOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
        activityType: ActivityType.fitness,
        pauseLocationUpdatesAutomatically: false,
      );
    } else {
      return const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      );
    }
  }
}
