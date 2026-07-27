import '../../../core/usecases/usecase.dart';
import '../entities/pin_data.dart';
import '../repositories/pin_repository.dart';

class LoadPinsParams {
  final String rootPath;
  const LoadPinsParams(this.rootPath);
}

class PinMutationParams {
  final String rootPath;
  final PinData pin;
  const PinMutationParams({required this.rootPath, required this.pin});
}

class DeletePinParams {
  final String rootPath;
  final String pinId;
  const DeletePinParams({required this.rootPath, required this.pinId});
}

class LoadPinsUseCase implements UseCase<List<PinData>, LoadPinsParams> {
  final PinRepository _repository;
  LoadPinsUseCase(this._repository);
  @override
  Future<List<PinData>> call(LoadPinsParams params) =>
      _repository.loadPins(params.rootPath);
}

class AddPinUseCase implements UseCase<void, PinMutationParams> {
  final PinRepository _repository;
  AddPinUseCase(this._repository);
  @override
  Future<void> call(PinMutationParams params) =>
      _repository.addPin(params.rootPath, params.pin);
}

class UpdatePinUseCase implements UseCase<void, PinMutationParams> {
  final PinRepository _repository;
  UpdatePinUseCase(this._repository);
  @override
  Future<void> call(PinMutationParams params) =>
      _repository.updatePin(params.rootPath, params.pin);
}

class DeletePinUseCase implements UseCase<void, DeletePinParams> {
  final PinRepository _repository;
  DeletePinUseCase(this._repository);
  @override
  Future<void> call(DeletePinParams params) =>
      _repository.deletePin(params.rootPath, params.pinId);
}
