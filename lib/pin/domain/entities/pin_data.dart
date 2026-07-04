import 'package:equatable/equatable.dart';

/// マップ上に置かれるピンのドメインエンティティ
/// colorHex: '#RRGGBB' 形式
class PinData extends Equatable {
  final String id;
  final double latitude;
  final double longitude;
  final String title;
  final String memo;
  final String colorHex;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PinData({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.title,
    this.memo = '',
    this.colorHex = '#E63946',
    required this.createdAt,
    required this.updatedAt,
  });

  PinData copyWith({
    String? title,
    String? memo,
    String? colorHex,
    double? latitude,
    double? longitude,
  }) =>
      PinData(
        id: id,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        title: title ?? this.title,
        memo: memo ?? this.memo,
        colorHex: colorHex ?? this.colorHex,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );

  @override
  List<Object?> get props =>
      [id, latitude, longitude, title, memo, colorHex, createdAt, updatedAt];
}
