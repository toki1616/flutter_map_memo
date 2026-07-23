import 'package:equatable/equatable.dart';

/// ユーザーが選択したルートフォルダの情報を保持するドメインエンティティ
/// path           : 選択されたフォルダの絶対パス
/// name           : フォルダ名（表示用）
/// localMapNames  : {path}/map/ 直下に存在するマップ名の一覧
/// isAppStorage   : 外部フォルダ未選択時のアプリ内保存先かどうか
class FolderSelection extends Equatable {
  final String path;
  final String name;
  final List<String> localMapNames;
  final bool isAppStorage;

  const FolderSelection({
    required this.path,
    required this.name,
    required this.localMapNames,
    this.isAppStorage = false,
  });

  @override
  List<Object> get props => [path, name, localMapNames, isAppStorage];
}
