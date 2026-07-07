import 'package:equatable/equatable.dart';
import 'orientation_config.dart';
import 'text_scale_config.dart';

/// ローカルに永続化保存される設定データのドメインエンティティ
/// 保存先: Documents/save_data/setting/settings.json
///
/// フィールド:
///   textScaleType   : 文字・ボタンの表示サイズ倍率
///   folderPath      : ユーザーが選択したマップフォルダの絶対パス（未選択時は null）
///   orientationType : 画面の向き設定（縦・横・自動）
class SettingStorageData extends Equatable {
  final TextScaleType textScaleType;
  final String? folderPath;
  final OrientationType orientationType;

  const SettingStorageData({
    this.textScaleType = TextScaleType.standard,
    this.folderPath,
    this.orientationType = OrientationType.auto,
  });

  SettingStorageData copyWith({
    TextScaleType? textScaleType,
    Object? folderPath = _sentinel,
    OrientationType? orientationType,
  }) =>
      SettingStorageData(
        textScaleType: textScaleType ?? this.textScaleType,
        folderPath:
            folderPath == _sentinel ? this.folderPath : folderPath as String?,
        orientationType: orientationType ?? this.orientationType,
      );

  Map<String, dynamic> toJson() => {
        'textScaleType': textScaleType.name,
        if (folderPath != null) 'folderPath': folderPath,
        'orientationType': orientationType.name,
      };

  factory SettingStorageData.fromJson(Map<String, dynamic> json) {
    final scaleName = json['textScaleType'] as String?;
    final textScale = TextScaleType.values.firstWhere(
      (e) => e.name == scaleName,
      orElse: () => TextScaleType.standard,
    );

    final orientationName = json['orientationType'] as String?;
    final orientation = OrientationType.values.firstWhere(
      (e) => e.name == orientationName,
      orElse: () => OrientationType.auto,
    );

    return SettingStorageData(
      textScaleType: textScale,
      folderPath: json['folderPath'] as String?,
      orientationType: orientation,
    );
  }

  @override
  List<Object?> get props => [textScaleType, folderPath, orientationType];
}

const _sentinel = Object();
