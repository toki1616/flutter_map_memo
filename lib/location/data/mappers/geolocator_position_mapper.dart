import 'package:geolocator/geolocator.dart';

import '../../domain/entities/location_data.dart';

/// geolocator の外部モデルをアプリのドメインエンティティへ変換する。
///
/// 位置情報の属性追加・変更はこの mapper に集約し、Position への依存を
/// データ層の外へ漏らさない。
extension GeolocatorPositionMapper on Position {
  LocationData toLocationData() {
    return LocationData(
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      timestamp: timestamp,
      altitude: altitude,
      altitudeAccuracy: altitudeAccuracy,
      heading: heading,
      headingAccuracy: headingAccuracy,
      speed: speed,
      speedAccuracy: speedAccuracy,
      floor: floor,
    );
  }
}
