import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import '../../../folder/presentation/providers/folder_provider.dart';
import '../../data/datasources/pin_local_datasource.dart';
import '../../data/repositories/pin_repository_impl.dart';
import '../../domain/entities/pin_data.dart';
import '../../domain/repositories/pin_repository.dart';
import '../../domain/usecases/pin_usecases.dart';

// ── DI ───────────────────────────────────────────────────────────────────

final pinLocalDataSourceProvider = Provider<PinLocalDataSource>(
  (ref) => PinLocalDataSourceImpl(),
);

final pinRepositoryProvider = Provider<PinRepository>(
  (ref) => PinRepositoryImpl(ref.watch(pinLocalDataSourceProvider)),
);

final loadPinsUseCaseProvider =
    Provider((ref) => LoadPinsUseCase(ref.watch(pinRepositoryProvider)));
final addPinUseCaseProvider =
    Provider((ref) => AddPinUseCase(ref.watch(pinRepositoryProvider)));
final updatePinUseCaseProvider =
    Provider((ref) => UpdatePinUseCase(ref.watch(pinRepositoryProvider)));
final deletePinUseCaseProvider =
    Provider((ref) => DeletePinUseCase(ref.watch(pinRepositoryProvider)));

// ── State ─────────────────────────────────────────────────────────────────

/// ピン一覧を管理する AsyncNotifier
/// folderProvider のルートパスを watch して
/// フォルダが切り替わると自動でピン一覧を再ロードする
class PinNotifier extends AsyncNotifier<List<PinData>> {
  final _uuid = const Uuid();

  @override
  Future<List<PinData>> build() async {
    final folder = ref.watch(folderProvider).valueOrNull;
    if (folder == null) return [];
    return ref
        .read(loadPinsUseCaseProvider)
        .call(LoadPinsParams(folder.path));
  }

  /// マップ中心座標にピンを追加する
  Future<void> addPin({
    required LatLng position,
    required String title,
    String memo = '',
    String colorHex = '#E63946',
  }) async {
    final folder = ref.read(folderProvider).valueOrNull;
    if (folder == null) return;

    final now = DateTime.now();
    final pin = PinData(
      id: _uuid.v4(),
      latitude: position.latitude,
      longitude: position.longitude,
      title: title,
      memo: memo,
      colorHex: colorHex,
      createdAt: now,
      updatedAt: now,
    );

    await ref
        .read(addPinUseCaseProvider)
        .call(PinMutationParams(rootPath: folder.path, pin: pin));

    // ファイル再読み込みせずメモリ上のリストに即時反映
    state = AsyncData([...state.valueOrNull ?? [], pin]);
  }

  /// ピンのタイトル・メモ・色を更新する
  Future<void> updatePin(PinData updated) async {
    final folder = ref.read(folderProvider).valueOrNull;
    if (folder == null) return;

    await ref
        .read(updatePinUseCaseProvider)
        .call(PinMutationParams(rootPath: folder.path, pin: updated));

    state = AsyncData(
      (state.valueOrNull ?? [])
          .map((p) => p.id == updated.id ? updated : p)
          .toList(),
    );
  }

  /// ID でピンを削除する
  Future<void> deletePin(String pinId) async {
    final folder = ref.read(folderProvider).valueOrNull;
    if (folder == null) return;

    await ref
        .read(deletePinUseCaseProvider)
        .call(DeletePinParams(rootPath: folder.path, pinId: pinId));

    state = AsyncData(
      (state.valueOrNull ?? []).where((p) => p.id != pinId).toList(),
    );
  }
}

final pinProvider =
    AsyncNotifierProvider<PinNotifier, List<PinData>>(PinNotifier.new);
