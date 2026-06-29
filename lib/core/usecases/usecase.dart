import '../error/failures.dart';

/// ドメイン層のビジネスロジックが実装する共通のインターフェースを定義したファイル
/// すべてのユースケースが引数を受け取り、成否に応じてエラーか正常なデータを必ず返すという統一された構造を保証
abstract class UseCase<Type, Params> {
  Future<Type> call(Params params);
}

class NoParams {
  const NoParams();
}
