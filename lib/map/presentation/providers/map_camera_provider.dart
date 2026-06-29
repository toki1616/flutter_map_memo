import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/map_camera_state.dart';

// Flutterマップのカメラ状態（中心座標やズームレベル）をアプリ全体で一元管理・監視するためのプロバイダーファイル
// 地図がドラッグやピンチ操作で移動した際に、最新の値をリアルタイムにUIへ同期させるための更新メソッドを提供
class MapCameraNotifier extends StateNotifier<MapCameraState> {
  MapCameraNotifier() : super(const MapCameraState());

  // 地図の移動（カメラの変更）を検知した時に、状態を更新するメソッド
  void updateCamera(double latitude, double longitude, double zoom) {
    // わずかな変更でも無駄な再描画（リビルド）が走らないよう、値が変わっている場合のみ更新
    if (state.latitude == latitude &&
        state.longitude == longitude &&
        state.zoom == zoom) {
      return;
    }
    state = state.copyWith(
      latitude: latitude,
      longitude: longitude,
      zoom: zoom,
    );
  }
}

// 画面側から watch して現在の地図位置を取得したり、変更を通知するために使用するプロバイダー
final mapCameraProvider = StateNotifierProvider<MapCameraNotifier, MapCameraState>((ref) {
  return MapCameraNotifier();
});