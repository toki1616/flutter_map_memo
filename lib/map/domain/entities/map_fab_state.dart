import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

/// マップ画面のFABボタン群が必要とする状態を一つに集約したドメインエンティティ
///
/// map feature 内部でのみ使用する。
/// folder / location / pin の各 feature から必要な情報だけを抽出して保持し、
/// UI 層（MapFabButtons）が他 feature の Provider を直接 watch しなくて済む設計にする。
class MapFabState extends Equatable {
  /// フォルダが選択済みかどうか（ピン追加ボタンの表示/非表示に使う）
  final bool isFolderSelected;

  /// GPS の現在地（null = 未取得 or 権限なし）
  /// 現在地追従ボタンの表示/非表示と追従移動に使う
  final LatLng? currentLocation;

  /// ピン追加モードが ON かどうか
  final bool isPinAddMode;

  /// 現在地追従モードが ON かどうか
  final bool isFollowingLocation;

  const MapFabState({
    required this.isFolderSelected,
    this.currentLocation,
    this.isPinAddMode = false,
    this.isFollowingLocation = false,
  });

  MapFabState copyWith({
    bool? isFolderSelected,
    // null を「クリア」として扱えるよう Object? で受ける
    Object? currentLocation = _sentinel,
    bool? isPinAddMode,
    bool? isFollowingLocation,
  }) =>
      MapFabState(
        isFolderSelected: isFolderSelected ?? this.isFolderSelected,
        currentLocation: currentLocation == _sentinel
            ? this.currentLocation
            : currentLocation as LatLng?,
        isPinAddMode: isPinAddMode ?? this.isPinAddMode,
        isFollowingLocation: isFollowingLocation ?? this.isFollowingLocation,
      );

  @override
  List<Object?> get props => [
        isFolderSelected,
        currentLocation,
        isPinAddMode,
        isFollowingLocation,
      ];
}

const _sentinel = Object();
