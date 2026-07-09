import '../../../core/usecases/usecase.dart';
import '../entities/track_log.dart';
import '../repositories/track_repository.dart';

class TrackRootPathParams {
  final String rootPath;
  const TrackRootPathParams(this.rootPath);
}

class SaveTrackParams {
  final String rootPath;
  final TrackLog log;
  const SaveTrackParams({required this.rootPath, required this.log});
}

class DeleteTrackParams {
  final String rootPath;
  final String id;
  const DeleteTrackParams({required this.rootPath, required this.id});
}

class DeleteOldTracksParams {
  final String rootPath;
  final int days;
  const DeleteOldTracksParams({required this.rootPath, required this.days});
}

class LoadAllTracksUseCase
    implements UseCase<List<TrackLog>, TrackRootPathParams> {
  final TrackRepository _repository;
  LoadAllTracksUseCase(this._repository);
  @override
  Future<List<TrackLog>> call(TrackRootPathParams params) =>
      _repository.loadAll(params.rootPath);
}

class SaveTrackUseCase implements UseCase<void, SaveTrackParams> {
  final TrackRepository _repository;
  SaveTrackUseCase(this._repository);
  @override
  Future<void> call(SaveTrackParams params) =>
      _repository.save(params.rootPath, params.log);
}

class DeleteTrackUseCase implements UseCase<void, DeleteTrackParams> {
  final TrackRepository _repository;
  DeleteTrackUseCase(this._repository);
  @override
  Future<void> call(DeleteTrackParams params) =>
      _repository.delete(params.rootPath, params.id);
}

class DeleteOldTracksUseCase implements UseCase<void, DeleteOldTracksParams> {
  final TrackRepository _repository;
  DeleteOldTracksUseCase(this._repository);
  @override
  Future<void> call(DeleteOldTracksParams params) =>
      _repository.deleteOlderThan(params.rootPath, params.days);
}
