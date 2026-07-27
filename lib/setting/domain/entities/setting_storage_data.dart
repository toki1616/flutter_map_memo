import 'package:equatable/equatable.dart';
import 'orientation_config.dart';
import 'text_scale_config.dart';
import 'track_setting_config.dart';

/// ローカルに永続化保存される設定データのドメインエンティティ
/// 保存先: Documents/save_data/setting/settings.json
class SettingStorageData extends Equatable {
  final TextScaleType textScaleType;
  final String? folderPath;
  final OrientationType orientationType;

  /// GPS ポイントの記録間隔
  final TrackIntervalType trackIntervalType;

  /// マップへのトラック表示期間（この日数以内のログを表示）
  final TrackDisplayDaysType trackDisplayDaysType;

  /*
   * 機能: 自動削除するまでの日数を settings.json に保存する。
   * 状態: 自動削除を停止中のため、設定データには保持しない。
  final TrackRetentionDaysType trackRetentionDaysType;
  */

  const SettingStorageData({
    this.textScaleType = TextScaleType.standard,
    this.folderPath,
    this.orientationType = OrientationType.auto,
    this.trackIntervalType = TrackIntervalType.sec10,
    this.trackDisplayDaysType = TrackDisplayDaysType.week1,
    // this.trackRetentionDaysType = TrackRetentionDaysType.month1,
  });

  // track_provider から日数の int 値を直接使えるよう getter を用意
  int get trackDisplayDays => trackDisplayDaysType.days;
  // int get trackRetentionDays => trackRetentionDaysType.days;
  int get trackIntervalSeconds => trackIntervalType.intervalSeconds;

  SettingStorageData copyWith({
    TextScaleType? textScaleType,
    Object? folderPath = _sentinel,
    OrientationType? orientationType,
    TrackIntervalType? trackIntervalType,
    TrackDisplayDaysType? trackDisplayDaysType,
    // TrackRetentionDaysType? trackRetentionDaysType,
  }) => SettingStorageData(
    textScaleType: textScaleType ?? this.textScaleType,
    folderPath: folderPath == _sentinel
        ? this.folderPath
        : folderPath as String?,
    orientationType: orientationType ?? this.orientationType,
    trackIntervalType: trackIntervalType ?? this.trackIntervalType,
    trackDisplayDaysType: trackDisplayDaysType ?? this.trackDisplayDaysType,
    // trackRetentionDaysType:
    //     trackRetentionDaysType ?? this.trackRetentionDaysType,
  );

  Map<String, dynamic> toJson() => {
    'textScaleType': textScaleType.name,
    if (folderPath != null) 'folderPath': folderPath,
    'orientationType': orientationType.name,
    'trackIntervalType': trackIntervalType.name,
    'trackDisplayDaysType': trackDisplayDaysType.name,
    // 'trackRetentionDaysType': trackRetentionDaysType.name,
  };

  factory SettingStorageData.fromJson(Map<String, dynamic> json) {
    T _find<T extends Enum>(List<T> values, String? name, T fallback) =>
        values.firstWhere((e) => e.name == name, orElse: () => fallback);

    return SettingStorageData(
      textScaleType: _find(
        TextScaleType.values,
        json['textScaleType'] as String?,
        TextScaleType.standard,
      ),
      folderPath: json['folderPath'] as String?,
      orientationType: _find(
        OrientationType.values,
        json['orientationType'] as String?,
        OrientationType.auto,
      ),
      trackIntervalType: _find(
        TrackIntervalType.values,
        json['trackIntervalType'] as String?,
        TrackIntervalType.sec10,
      ),
      trackDisplayDaysType: _find(
        TrackDisplayDaysType.values,
        json['trackDisplayDaysType'] as String?,
        TrackDisplayDaysType.week1,
      ),
      // trackRetentionDaysType: _find(
      //   TrackRetentionDaysType.values,
      //   json['trackRetentionDaysType'] as String?,
      //   TrackRetentionDaysType.month1,
      // ),
    );
  }

  @override
  List<Object?> get props => [
    textScaleType,
    folderPath,
    orientationType,
    trackIntervalType,
    trackDisplayDaysType,
    // trackRetentionDaysType,
  ];
}

const _sentinel = Object();
