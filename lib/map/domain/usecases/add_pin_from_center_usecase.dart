import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import '../../../core/usecases/usecase.dart';
import '../../../folder/domain/repositories/folder_repository.dart';
import '../../../pin/domain/entities/pin_data.dart';
import '../../../pin/domain/repositories/pin_repository.dart';

/// マップ中央座標にピンを追加するユースケース
///
/// map feature のユースケースとして定義することで、
/// UI 層が pin feature / folder feature を直接操作しなくて済む
class AddPinFromCenterParams {
  final LatLng position;
  final String title;
  final String memo;
  final String colorHex;

  const AddPinFromCenterParams({
    required this.position,
    required this.title,
    this.memo = '',
    this.colorHex = '#E63946',
  });
}

class AddPinFromCenterUseCase implements UseCase<void, AddPinFromCenterParams> {
  final PinRepository _pinRepository;
  final FolderRepository _folderRepository;
  final _uuid = const Uuid();

  AddPinFromCenterUseCase({
    required PinRepository pinRepository,
    required FolderRepository folderRepository,
  })  : _pinRepository = pinRepository,
        _folderRepository = folderRepository;

  @override
  Future<void> call(AddPinFromCenterParams params) async {
    // フォルダパスを取得（未選択なら何もしない）
    final folder = await _folderRepository.loadSavedFolder();
    if (folder == null) return;

    final now = DateTime.now();
    final pin = PinData(
      id: _uuid.v4(),
      latitude: params.position.latitude,
      longitude: params.position.longitude,
      title: params.title,
      memo: params.memo,
      colorHex: params.colorHex,
      createdAt: now,
      updatedAt: now,
    );

    await _pinRepository.addPin(folder.path, pin);
  }
}
