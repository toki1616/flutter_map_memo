import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../constants/app_constants.dart';

// アプリケーション内で使用するすべての物理パスの生成ロジックを一元管理するユーティリティファイル
// アプリ内保存領域（Documents）をベースに、save_dataやsettingなどの階層構造を安全に組み立てて返却
class AppPathUtils {
  // ユーザーが選択した任意のカスタムデータセットフォルダへのパスを静的に管理する変数
  static String? _currentDatasetPath;
  static String? get currentDatasetPath => _currentDatasetPath;

  // データセットの基準ルートパスを初期化するメソッド
  static void initializeDatasetPath(String? savedPath) {
    _currentDatasetPath = savedPath;
  }

  // アプリ専用のDocumentsディレクトリを取得
  static Future<Directory> _getAppDocsDir() async {
    return await getApplicationDocumentsDirectory();
  }

  /// ユーザーが外部フォルダを選択していない場合のデータ保存ルート。
  /// この配下に save_data/map_data/ を作成してピン・トラックを保存する。
  static Future<String> getApplicationDocumentsPath() async {
    return (await _getAppDocsDir()).path;
  }

  // アプリ内保存場所のルート（Documents/save_data）のパスを取得
  static Future<String> getSaveDataRootPath() async {
    final docsDir = await _getAppDocsDir();
    return p.join(docsDir.path, AppConstants.saveDataFolderName);
  }

  // 設定フォルダ（Documents/save_data/setting）のパスを取得
  static Future<String> getSettingFolderPath() async {
    final saveDataRoot = await getSaveDataRootPath();
    return p.join(saveDataRoot, AppConstants.settingFolderName);
  }

  // 設定ファイル（Documents/save_data/setting/設定ファイル.json）の絶対パスを取得
  static Future<String> getSettingsFilePath() async {
    final settingFolder = await getSettingFolderPath();
    return p.join(settingFolder, AppConstants.settingFileName);
  }
}
