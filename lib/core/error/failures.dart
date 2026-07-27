import 'package:equatable/equatable.dart';

/// アプリ内で発生するエラーや例外を表現するためのクラス群定義ファイル
/// Equatableを継承しており、ストレージのエラーやファイルシステムの不具合、パース失敗などのエラー状態を安全に比較・ハンドリングできるように
abstract class AppFailure extends Equatable {
  final String message;
  const AppFailure(this.message);

  @override
  List<Object> get props => [message];
}

class FileSystemFailure extends AppFailure {
  const FileSystemFailure(super.message);
}

class ParseFailure extends AppFailure {
  const ParseFailure(super.message);
}

class StorageFailure extends AppFailure {
  const StorageFailure(super.message);
}

class InvalidFolderFailure extends AppFailure {
  const InvalidFolderFailure(super.message);
}

class NotFoundFailure extends AppFailure {
  const NotFoundFailure(super.message);
}
