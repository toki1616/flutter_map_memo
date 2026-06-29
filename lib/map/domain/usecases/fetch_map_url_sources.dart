import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../entities/map_url_config.dart';

// 利用可能なURL指定のマップソース一覧を取得するビジネスロジックを実装したファイル
// コア層のUseCaseを継承しており、データの取得失敗時にはEither型ではなく、定義されたAppFailure系の例外をスローすることでDart標準の例外処理に合わせる設計
class FetchMapUrlSources implements UseCase<List<MapUrlConfig>, NoParams> {
  @override
  Future<List<MapUrlConfig>> call(NoParams params) async {
    try {
      return [
        MapUrlConfig(
          id: 'osm_standard',
          name: 'OpenStreetMap',
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          attribution: '© OpenStreetMap contributors',
        ),
        MapUrlConfig(
          id: 'gsi_standard',
          name: '国土地理院 (標準地図)',
          urlTemplate: 'https://cyberjapandata.gsi.go.jp/xyz/std/{z}/{x}/{y}.png',
          attribution: '地理院タイル',
        ),
      ];
    } catch (e) {
      throw const StorageFailure('マップソースの読み込みに失敗しました');
    }
  }
}