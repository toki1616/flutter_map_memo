import 'package:equatable/equatable.dart';

/// 端末の現在地情報を保持するドメインエンティティ
/// latitude  : 緯度
/// longitude : 経度
/// accuracy  : 水平 GPS 精度（メートル）
class LocationData extends Equatable {
  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime timestamp;
  final double altitude;
  final double altitudeAccuracy;
  final double heading;
  final double headingAccuracy;
  final double speed;
  final double speedAccuracy;
  final int? floor;

  const LocationData({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
    required this.altitude,
    required this.altitudeAccuracy,
    required this.heading,
    required this.headingAccuracy,
    required this.speed,
    required this.speedAccuracy,
    this.floor,
  });

  @override
  List<Object?> get props => [
    latitude,
    longitude,
    accuracy,
    timestamp,
    altitude,
    altitudeAccuracy,
    heading,
    headingAccuracy,
    speed,
    speedAccuracy,
    floor,
  ];
}
