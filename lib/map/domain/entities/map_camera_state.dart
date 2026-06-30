import 'package:equatable/equatable.dart';

/// Flutterマップの現在のカメラ状態（中心座標とズームレベル）のデータを一つに集約して保持するドメインエンティティファイル
/// 不変（Immutable）なクラスとして定義し、地図が動くたびの細かな状態の変更検知を効率化
class MapCameraState extends Equatable {
  final double latitude;
  final double longitude;
  final double zoom;

  const MapCameraState({
    // アプリの初期表示位置を指定
    this.latitude = 35.681236,
    this.longitude = 139.767125,
    this.zoom = 13.0,
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