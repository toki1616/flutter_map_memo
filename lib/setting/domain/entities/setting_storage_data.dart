import 'package:equatable/equatable.dart';
import 'text_scale_config.dart';

/// ローカルに永続化保存される設定データのドメインエンティティ
/// 保存先: Documents/save_data/setting/settings.json
///
/// フィールド:
///   textScaleType : 文字・ボタンの表示サイズ倍率
///   folderPath    : ユーザーが選択したマップフォルダの絶対パス（未選択時は null）
///                   iOS  : ブックマーク復元後の最新パスを参照用として保持
///                   Android: これが唯一の永続化手段
class SettingStorageData extends Equatable {
  final TextScaleType textScaleType;
  final String? folderPath;

  const SettingStorageData({
    this.textScaleType = TextScaleType.standard,
    this.folderPath,
  });

  SettingStorageData copyWith({
    TextScaleType? textScaleType,
    // null を「クリア」として使えるよう Object? で受ける
    Object? folderPath = _sentinel,
  }) =>
      SettingStorageData(
        textScaleType: textScaleType ?? this.textScaleType,
        folderPath:
            folderPath == _sentinel ? this.folderPath : folderPath as String?,
      );

  Map<String, dynamic> toJson() => {
        'textScaleType': textScaleType.name,
        // null のときはキーを書かない（既存ファイルとの互換性を保つ）
        if (folderPath != null) 'folderPath': folderPath,
      };

  factory SettingStorageData.fromJson(Map<String, dynamic> json) {
    final scaleName = json['textScaleType'] as String?;
    final type = TextScaleType.values.firstWhere(
      (e) => e.name == scaleName,
      orElse: () => TextScaleType.standard,
    );
    return SettingStorageData(
      textScaleType: type,
      folderPath: json['folderPath'] as String?,
    );
  }

  @override
  List<Object?> get props => [textScaleType, folderPath];
}

// copyWith で null を明示的に渡せるようにするための番兵オブジェクト
const _sentinel = Object();
