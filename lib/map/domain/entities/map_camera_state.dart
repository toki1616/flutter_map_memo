import 'package:equatable/equatable.dart';

/// 次回起動時用に最後に表示していた地図のカメラ状態を保持するドメインモデル
class MapCameraState extends Equatable {
  final double latitude;
  final double longitude;
  final double zoom;

  const MapCameraState({
    required this.latitude,
    required this.longitude,
    required this.zoom,
  });

  MapCameraState copyWith({
    double? latitude,
    double? longitude,
    double? zoom,
  }) {
    return MapCameraState(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      zoom: zoom ?? this.zoom,
    );
  }

  @override
  List<Object?> get props => [latitude, longitude, zoom];
}