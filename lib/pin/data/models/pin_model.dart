import '../../domain/entities/pin_data.dart';

/// ピンデータの JSON シリアライズ／デシリアライズを担うモデルクラス
class PinModel {
  final String id;
  final double latitude;
  final double longitude;
  final String title;
  final String memo;
  final String colorHex;
  final String createdAt;
  final String updatedAt;

  const PinModel({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.title,
    required this.memo,
    required this.colorHex,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PinModel.fromJson(Map<String, dynamic> json) => PinModel(
        id: json['id'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        title: json['title'] as String? ?? '',
        memo: json['memo'] as String? ?? '',
        colorHex: json['colorHex'] as String? ?? '#E63946',
        createdAt: json['createdAt'] as String,
        updatedAt: json['updatedAt'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'latitude': latitude,
        'longitude': longitude,
        'title': title,
        'memo': memo,
        'colorHex': colorHex,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  factory PinModel.fromEntity(PinData pin) => PinModel(
        id: pin.id,
        latitude: pin.latitude,
        longitude: pin.longitude,
        title: pin.title,
        memo: pin.memo,
        colorHex: pin.colorHex,
        createdAt: pin.createdAt.toIso8601String(),
        updatedAt: pin.updatedAt.toIso8601String(),
      );

  PinData toEntity() => PinData(
        id: id,
        latitude: latitude,
        longitude: longitude,
        title: title,
        memo: memo,
        colorHex: colorHex,
        createdAt: DateTime.parse(createdAt),
        updatedAt: DateTime.parse(updatedAt),
      );
}
