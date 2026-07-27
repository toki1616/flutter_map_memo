import '../../domain/entities/track_log.dart';

/// TrackPoint の JSON シリアライズ/デシリアライズ
class TrackPointModel {
  final double latitude;
  final double longitude;
  final double accuracy;
  final String timestamp;
  final double? altitude;
  final double? altitudeAccuracy;
  final double? heading;
  final double? headingAccuracy;
  final double? speed;
  final double? speedAccuracy;
  final int? floor;

  const TrackPointModel({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
    this.altitude,
    this.altitudeAccuracy,
    this.heading,
    this.headingAccuracy,
    this.speed,
    this.speedAccuracy,
    this.floor,
  });

  factory TrackPointModel.fromJson(Map<String, dynamic> json) =>
      TrackPointModel(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        accuracy: (json['accuracy'] as num).toDouble(),
        timestamp: json['timestamp'] as String,
        altitude: (json['altitude'] as num?)?.toDouble(),
        altitudeAccuracy: (json['altitudeAccuracy'] as num?)?.toDouble(),
        heading: (json['heading'] as num?)?.toDouble(),
        headingAccuracy: (json['headingAccuracy'] as num?)?.toDouble(),
        speed: (json['speed'] as num?)?.toDouble(),
        speedAccuracy: (json['speedAccuracy'] as num?)?.toDouble(),
        floor: json['floor'] as int?,
      );

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'accuracy': accuracy,
    'timestamp': timestamp,
    if (altitude != null) 'altitude': altitude,
    if (altitudeAccuracy != null) 'altitudeAccuracy': altitudeAccuracy,
    if (heading != null) 'heading': heading,
    if (headingAccuracy != null) 'headingAccuracy': headingAccuracy,
    if (speed != null) 'speed': speed,
    if (speedAccuracy != null) 'speedAccuracy': speedAccuracy,
    if (floor != null) 'floor': floor,
  };

  factory TrackPointModel.fromEntity(TrackPoint p) => TrackPointModel(
    latitude: p.latitude,
    longitude: p.longitude,
    accuracy: p.accuracy,
    timestamp: p.timestamp.toIso8601String(),
    altitude: p.altitude,
    altitudeAccuracy: p.altitudeAccuracy,
    heading: p.heading,
    headingAccuracy: p.headingAccuracy,
    speed: p.speed,
    speedAccuracy: p.speedAccuracy,
    floor: p.floor,
  );

  TrackPoint toEntity() => TrackPoint(
    latitude: latitude,
    longitude: longitude,
    accuracy: accuracy,
    timestamp: DateTime.parse(timestamp),
    altitude: altitude,
    altitudeAccuracy: altitudeAccuracy,
    heading: heading,
    headingAccuracy: headingAccuracy,
    speed: speed,
    speedAccuracy: speedAccuracy,
    floor: floor,
  );
}

/// TrackLog の JSON シリアライズ/デシリアライズ
class TrackLogModel {
  final String id;
  final String startedAt;
  final String? endedAt;
  final List<TrackPointModel> points;

  const TrackLogModel({
    required this.id,
    required this.startedAt,
    this.endedAt,
    required this.points,
  });

  factory TrackLogModel.fromJson(Map<String, dynamic> json) => TrackLogModel(
    id: json['id'] as String,
    startedAt: json['startedAt'] as String,
    endedAt: json['endedAt'] as String?,
    points: (json['points'] as List<dynamic>)
        .map((e) => TrackPointModel.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'startedAt': startedAt,
    if (endedAt != null) 'endedAt': endedAt,
    'points': points.map((p) => p.toJson()).toList(),
  };

  factory TrackLogModel.fromEntity(TrackLog log) => TrackLogModel(
    id: log.id,
    startedAt: log.startedAt.toIso8601String(),
    endedAt: log.endedAt?.toIso8601String(),
    points: log.points.map(TrackPointModel.fromEntity).toList(),
  );

  TrackLog toEntity() => TrackLog(
    id: id,
    startedAt: DateTime.parse(startedAt),
    endedAt: endedAt != null ? DateTime.parse(endedAt!) : null,
    points: points.map((p) => p.toEntity()).toList(),
  );
}
