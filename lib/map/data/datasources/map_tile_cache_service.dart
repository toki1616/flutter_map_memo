// マップタイルのキャッシュデータベースを初期化するためのデータ層のファイルです。
// アプリ起動時に呼び出され、ローカルストレージ上にタイル画像を保存するための専用領域を安全に作成します。

import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

class MapTileCacheService {
  static Future<void> initialize() async {
    await FMTCObjectBoxBackend().initialise();
    await FMTCStore('custom_url_map_cache').manage.create();
  }
}