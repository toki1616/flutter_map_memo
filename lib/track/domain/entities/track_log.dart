import 'dart:math' as math;
import 'package:equatable/equatable.dart';

/// 1ポイントの位置情報
class TrackPoint extends Equatable {
  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime timestamp;

  const TrackPoint({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
  });

  @override
  List<Object> get props => [latitude, longitude, accuracy, timestamp];
}

/// 1回の移動記録セッション全体を表すドメインエンティティ
///
/// 保存先:
///   {rootPath}/save_data/map_data/track_log/track_20260302_162501.json
///
/// id はセッション開始時刻から自動生成する（ファイル名にもなる）
class TrackLog extends Equatable {
  /// ファイル名（拡張子なし）例: track_20260302_162501
  final String id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final List<TrackPoint> points;

  const TrackLog({
    required this.id,
    required this.startedAt,
    this.endedAt,
    required this.points,
  });

  bool get isRecording => endedAt == null;

  /// 総距離（km）ハーバーサイン公式
  double get totalDistanceKm {
    if (points.length < 2) return 0;
    double total = 0;
    for (int i = 1; i < points.length; i++) {
      total += _haversineKm(points[i - 1], points[i]);
    }
    return total;
  }

  double _haversineKm(TrackPoint a, TrackPoint b) {
    const r = 6371.0;
    final dLat = _toRad(b.latitude - a.latitude);
    final dLon = _toRad(b.longitude - a.longitude);
    final h = math.pow(math.sin(dLat / 2), 2) +
        math.cos(_toRad(a.latitude)) *
            math.cos(_toRad(b.latitude)) *
            math.pow(math.sin(dLon / 2), 2);
    return 2 * r * math.asin(math.sqrt(h.toDouble()));
  }

  double _toRad(double deg) => deg * math.pi / 180;

  TrackLog copyWith({DateTime? endedAt, List<TrackPoint>? points}) => TrackLog(
        id: id,
        startedAt: startedAt,
        endedAt: endedAt ?? this.endedAt,
        points: points ?? this.points,
      );

  @override
  List<Object?> get props => [id, startedAt, endedAt, points];
}

/// セッション開始時刻から id（ファイル名）を生成する
String generateTrackId(DateTime startedAt) {
  final y = startedAt.year.toString().padLeft(4, '0');
  final mo = startedAt.month.toString().padLeft(2, '0');
  final d = startedAt.day.toString().padLeft(2, '0');
  final h = startedAt.hour.toString().padLeft(2, '0');
  final mi = startedAt.minute.toString().padLeft(2, '0');
  final s = startedAt.second.toString().padLeft(2, '0');
  return 'track_${y}${mo}${d}_${h}${mi}${s}';
}
