import 'package:equatable/equatable.dart';
import 'text_scale_config.dart';

// ローカルに永続化保存される設定データそのものを定義するドメインエンティティファイル
// 将来的な設定項目の増加を見据えて抽象的なデータ構造とし、現在は一括文字サイズ設定のみを保持
class SettingStorageData extends Equatable {
  final TextScaleType textScaleType;

  const SettingStorageData({
    this.textScaleType = TextScaleType.standard,
  });

  SettingStorageData copyWith({
    TextScaleType? textScaleType,
  }) =>
      SettingStorageData(
        textScaleType: textScaleType ?? this.textScaleType,
      );

  Map<String, dynamic> toJson() => {
    'textScaleType': textScaleType.name,
  };

  factory SettingStorageData.fromJson(Map<String, dynamic> json) {
    final scaleName = json['textScaleType'] as String?;
    final type = TextScaleType.values.firstWhere(
          (e) => e.name == scaleName,
      orElse: () => TextScaleType.standard,
    );
    return SettingStorageData(textScaleType: type);
  }

  @override
  List<Object?> get props => [textScaleType];
}