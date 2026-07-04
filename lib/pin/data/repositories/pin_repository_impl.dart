import '../../domain/entities/pin_data.dart';
import '../../domain/repositories/pin_repository.dart';
import '../datasources/pin_local_datasource.dart';
import '../models/pin_model.dart';

class PinRepositoryImpl implements PinRepository {
  final PinLocalDataSource _dataSource;
  PinRepositoryImpl(this._dataSource);

  @override
  Future<List<PinData>> loadPins(String rootPath) async {
    final models = await _dataSource.loadPins(rootPath);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> addPin(String rootPath, PinData pin) async {
    final current = await _dataSource.loadPins(rootPath);
    if (current.any((m) => m.id == pin.id)) return; // 重複防止
    current.add(PinModel.fromEntity(pin));
    await _dataSource.savePins(rootPath, current);
  }

  @override
  Future<void> updatePin(String rootPath, PinData pin) async {
    final current = await _dataSource.loadPins(rootPath);
    final index = current.indexWhere((m) => m.id == pin.id);
    if (index == -1) return;
    current[index] = PinModel.fromEntity(pin);
    await _dataSource.savePins(rootPath, current);
  }

  @override
  Future<void> deletePin(String rootPath, String pinId) async {
    final current = await _dataSource.loadPins(rootPath);
    final updated = current.where((m) => m.id != pinId).toList();
    await _dataSource.savePins(rootPath, updated);
  }
}
