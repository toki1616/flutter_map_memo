import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/usecases/usecase.dart';
import '../../data/datasources/location_datasource.dart';
import '../../data/repositories/location_repository_impl.dart';
import '../../domain/entities/location_data.dart';
import '../../domain/repositories/location_repository.dart';
import '../../domain/usecases/location_usecases.dart';

// ── DI ───────────────────────────────────────────────────────────────────

final locationDataSourceProvider = Provider<LocationDataSource>(
  (ref) => LocationDataSourceImpl(),
);

final locationRepositoryProvider = Provider<LocationRepository>(
  (ref) => LocationRepositoryImpl(ref.watch(locationDataSourceProvider)),
);

final requestLocationPermissionUseCaseProvider = Provider(
  (ref) => RequestLocationPermissionUseCase(
      ref.watch(locationRepositoryProvider)),
);

final getCurrentLocationUseCaseProvider = Provider(
  (ref) =>
      GetCurrentLocationUseCase(ref.watch(locationRepositoryProvider)),
);

final watchLocationUseCaseProvider = Provider(
  (ref) => WatchLocationUseCase(ref.watch(locationRepositoryProvider)),
);

// ── Stream Provider ───────────────────────────────────────────────────────

/// 現在地をリアルタイムで監視する StreamProvider
/// map_screen.dart と coordinate_display.dart から watch して使う
///
/// 戻り値:
///   AsyncData(LocationData) : 位置情報取得成功
///   AsyncData(null)         : 権限なし / 位置情報サービス無効
///   AsyncLoading            : Stream 接続中（初回のみ一瞬）
final locationStreamProvider = StreamProvider<LocationData?>((ref) {
  final useCase = ref.watch(watchLocationUseCaseProvider);
  return useCase.call();
});
