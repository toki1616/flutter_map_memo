import 'dart:io';
import 'package:flutter/foundation.dart'; // プラットフォーム判定（defaultTargetPlatform）用に追加
import 'package:geolocator/geolocator.dart';
import '../../domain/entities/location_data.dart';

/// geolocator パッケージを使って位置情報を取得するデータソース
/// iOS / Android の設定の差異をここで吸収する
abstract class LocationDataSource {
  Future<bool> requestPermission();
  Future<LocationData?> getCurrentLocation();
  Stream<LocationData?> watchLocation();
}

class LocationDataSourceImpl implements LocationDataSource {
  /// 位置情報サービスの有効確認 → 権限確認 → 権限リクエストを順に実行する
  @override
  Future<bool> requestPermission() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      print("【GeolocatorDebug】GPSサービス（スマホ本体の設定）有効状態: $serviceEnabled");
      if (!serviceEnabled) return false;

      LocationPermission permission = await Geolocator.checkPermission();
      print("【GeolocatorDebug】現在の位置情報権限: $permission");

      if (permission == LocationPermission.denied) {
        print("【GeolocatorDebug】位置情報の権限ダイアログを表示します...");
        permission = await Geolocator.requestPermission();
        print("【GeolocatorDebug】ダイアログ操作後の権限: $permission");
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return false;
      }
      return true;
    } catch (e) {
      print("【GeolocatorDebug】権限確認/要求中に例外が発生しました: $e");
      return false;
    }
  }

  /// 現在地を一度だけ取得する（精度: high）
  @override
  Future<LocationData?> getCurrentLocation() async {
    try {
      final granted = await requestPermission();
      if (!granted) return null;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: _buildLocationSettings(),
      );
      print("【GeolocatorDebug】単発現在地取得成功: Lat=${position.latitude}, Lng=${position.longitude}");
      return _toLocationData(position);
    } catch (e) {
      print("【GeolocatorDebug】単発現在地取得失敗: $e");
      return null;
    }
  }

  /// 現在地を継続監視する Stream
  @override
  Stream<LocationData?> watchLocation() async* {
    print("【GeolocatorDebug】watchLocation が呼ばれました。ストリームの準備を開始します。");
    try {
      final granted = await requestPermission();
      if (!granted) {
        print("【GeolocatorDebug】位置情報権限がないため、nullを流してストリームを終了します。");
        yield null;
        return;
      }

      // ----------------------------------------------------------------
      // 【改善ポイント】
      // ストリーム（連続取得）は最初の1発目が出るまで数秒かかることがあるため、
      // まず「前回取得したキャッシュ」か「1発限りの現在地」を無理やり取ってきて
      // 即座に画面に流し込み（yield）、表示のフリーズを防ぎます。
      // ----------------------------------------------------------------
      try {
        print("【GeolocatorDebug】即時表示用の初回データを探しています...");

        // まずキャッシュ（数秒前に取得した情報など）があれば一瞬で取得
        Position? initialPosition = await Geolocator.getLastKnownPosition();

        // キャッシュがなければ、3秒だけ待って現在地を強制取得
        if (initialPosition == null) {
          print("【GeolocatorDebug】キャッシュがないため、強制取得を試みます...");
          initialPosition = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
            timeLimit: const Duration(seconds: 3),
          );
        }

        if (initialPosition != null) {
          print("【GeolocatorDebug】初回取得成功！画面に表示させます: Lat=${initialPosition.latitude}, Lng=${initialPosition.longitude}");
          yield _toLocationData(initialPosition); // ここで画面の「取得中...」が消えて即時反映されます
        }
      } catch (e) {
        print("【GeolocatorDebug】初回取得がタイムアウトまたは失敗しました（ストリームでの取得を待ちます）: $e");
      }

      // 本来のストリームをバックグラウンド設定付きで流し続ける
      print("【GeolocatorDebug】連続取得ストリームを起動しました。");
      yield* Geolocator.getPositionStream(
        locationSettings: _buildLocationSettings(),
      ).map((Position pos) {
        print("【GeolocatorDebug】位置情報更新: Lat=${pos.latitude}, Lng=${pos.longitude}, 精度=${pos.accuracy}m");
        return _toLocationData(pos);
      });
    } catch (e) {
      print("【GeolocatorDebug】ストリーム起動全体でエラーが発生しました: $e");
      yield null;
    }
  }

  // ── 内部ヘルパー ─────────────────────────────────────────────────────────

  LocationData _toLocationData(Position position) => LocationData(
    latitude: position.latitude,
    longitude: position.longitude,
    accuracy: position.accuracy,
  );

  /// iOS / Android ごとに最適な位置情報設定を返す
  LocationSettings _buildLocationSettings() {
    // バックグラウンドでも高頻度かつ確実に取得できるように距離フィルターを 0 に設定
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0, // 0に設定することで、わずかな動きでも即座にデータを取得
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText: "バックグラウンドで位置情報を記録しています",
          notificationTitle: "トラッキング実行中",
          enableWakeLock: true,
        ),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.fitness,
        distanceFilter: 0, // 0に設定
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      );
    } else {
      return const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      );
    }
  }
}