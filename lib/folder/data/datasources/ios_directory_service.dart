import 'package:flutter/services.dart';

/// iOS のセキュリティスコープブックマークを操作するサービスクラス
/// AppDelegate.swift の MethodChannel ハンドラと対になっている
/// チャンネル名は AppDelegate.swift の channel 名と完全一致させること
class IosDirectoryService {
  static const _channel = MethodChannel('com.example.flutter_map_memo/folder');

  /// iOS フォルダ選択ダイアログを開き、パスを返す
  /// 内部で bookmarkData を UserDefaults に保存するため次回 restoreDirectoryAccess() で復元できる
  /// キャンセル時は null を返す
  static Future<String?> pickAndSaveDirectory() async {
    try {
      return await _channel.invokeMethod<String>('pickDirectory');
    } on PlatformException catch (e) {
      print('[IosDirectoryService] pickDirectory エラー: ${e.message}');
      return null;
    }
  }

  /// アプリ起動時に保存済みブックマークを使ってアクセス権を復元する
  /// 成功した場合は利用可能になったフォルダの絶対パスを返す
  /// ブックマーク未保存または権限切れの場合は null を返す
  static Future<String?> restoreDirectoryAccess() async {
    try {
      return await _channel.invokeMethod<String>('restoreDirectoryAccess');
    } on PlatformException catch (e) {
      print('[IosDirectoryService] restoreDirectoryAccess エラー: ${e.message}');
      return null;
    }
  }

  /// アクセス権を解放する（フォルダリセット時に呼ぶ）
  static Future<void> stopDirectoryAccess() async {
    try {
      await _channel.invokeMethod<void>('stopDirectoryAccess');
    } on PlatformException catch (e) {
      print('[IosDirectoryService] stopDirectoryAccess エラー: ${e.message}');
    }
  }
}
