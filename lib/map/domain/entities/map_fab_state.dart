import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

/// マップ画面のFABボタン群が必要とする状態を一つに集約したドメインエンティティ
class MapFabState extends Equatable {
  final bool isFolderSelected;
  final LatLng? currentLocation;
  final bool isPinAddMode;
  final bool isFollowingLocation;

  /// トラック記録中かどうか
  final bool isTracking;

  const MapFabState({
    required this.isFolderSelected,
    this.currentLocation,
    this.isPinAddMode = false,
    this.isFollowingLocation = false,
    this.isTracking = false,
  });

  MapFabState copyWith({
    bool? isFolderSelected,
    Object? currentLocation = _sentinel,
    bool? isPinAddMode,
    bool? isFollowingLocation,
    bool? isTracking,
  }) =>
      MapFabState(
        isFolderSelected: isFolderSelected ?? this.isFolderSelected,
        currentLocation: currentLocation == _sentinel
            ? this.currentLocation
            : currentLocation as LatLng?,
        isPinAddMode: isPinAddMode ?? this.isPinAddMode,
        isFollowingLocation: isFollowingLocation ?? this.isFollowingLocation,
        isTracking: isTracking ?? this.isTracking,
      );

  @override
  List<Object?> get props => [
        isFolderSelected,
        currentLocation,
        isPinAddMode,
        isFollowingLocation,
        isTracking,
      ];
}

const _sentinel = Object();
