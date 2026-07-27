/// URL指定で取得するマップの情報を表す純粋なデータ構造を定義したファイル
/// 外部のパッケージに依存せず、マップの識別子、画面表示用の名前、タイルのURLテンプレート、著作権表記のみを保持
class MapUrlConfig {
  final String id;
  final String name;
  final String urlTemplate;
  final String? attribution;

  MapUrlConfig({
    required this.id,
    required this.name,
    required this.urlTemplate,
    this.attribution,
  });
}