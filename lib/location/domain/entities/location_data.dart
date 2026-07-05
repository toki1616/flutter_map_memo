import 'package:equatable/equatable.dart';

/// 端末の現在地情報を保持するドメインエンティティ
/// latitude  : 緯度
/// longitude : 経度
/// accuracy  : GPS精度（メートル）
class LocationData extends Equatable {
  final double latitude;
  final double longitude;
  final double accuracy;

  const LocationData({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
  });

  @override
  List<Object> get props => [latitude, longitude, accuracy];
}
