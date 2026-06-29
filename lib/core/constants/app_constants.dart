/// アプリ全体で共有する定数を管理するファイル
/// マップのデフォルトズーム値や最大最小ズーム値、保存先となるフォルダ名やファイル名などの文字列を一元管理
class AppConstants {
  // Folder structure inside selected root folder
  static const String mapFolderName = 'map';
  static const String saveDataFolderName = 'save_data';
  static const String mapDataFolderName = 'map_data';
  static const String trackLogFolderName = 'track_log';

  // File names
  static const String pinFileName = 'マップのピン.json';
  static const String trackLogFileName = 'track_log.json';

  // App internal folder (path_provider)
  static const String settingFolderName = 'setting';
  static const String settingFileName = '設定ファイル.json';

  // Tile image extension
  static const String tileExtension = '.png';

  // Map defaults
  static const double defaultZoom = 15.0;
  static const double minZoom = 1.0;
  static const double maxZoom = 20.0;
}
