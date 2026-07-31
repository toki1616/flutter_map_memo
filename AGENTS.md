# AGENTS.md

## Project

- Flutter 製の地図メモ・トラックログアプリ。
- 主な動作対象は Android / iOS。デスクトップ向けのフォルダ選択も考慮する。
- 状態管理には Riverpod、画面遷移には go_router を使用する。
- 地図表示には flutter_map、位置情報の取得には geolocator を使用する。
- ピン、設定、トラックログは JSON ファイルへローカル保存する。
- Android の外部フォルダは Storage Access Framework（SAF）で扱う。

## Architecture

- 機能ごとに `lib/<feature>/data`、`domain`、`presentation` を分ける。
- `data` には DataSource、Model、Repository 実装を置く。
- `domain` には Entity、Repository の抽象、UseCase を置く。
- `presentation` には Screen、Widget、Riverpod Provider / Notifier を置く。
- UI Widget にファイル操作・JSON変換・ビジネスロジックを書かない。
- UI からのデータ操作は Notifier と UseCase / Repository を経由する。
- 既存の Feature をまたぐ操作は、必要に応じて呼び出し元 Feature の UseCase にまとめる。
- Entity は UI・永続化形式から独立させ、JSON 変換は Model / DataSource 側で行う。
- 新しい状態を追加するときは、フォルダ切替・アプリ再起動・非同期ローディング時の状態遷移も確認する。
- 既存の変更や未コミットファイルを、ユーザーの明示的な依頼なく破棄しない。

## Storage

- ピンとトラックログの保存ルートは `FolderProvider` が管理する `FolderSelection.path` を使う。
- 外部フォルダが未選択の場合は、アプリ内 Documents ディレクトリを保存ルートにする。
- 保存構造は次を維持する。

  ```text
  {rootPath}/save_data/map_data/pin.json
  {rootPath}/save_data/map_data/track_log/track_YYYYMMDD_HHmmss.json
  ```

- Android で `content://` から始まる SAF URI を扱う場合、`dart:io` の `File` / `Directory` で直接アクセスしない。
- SAF URI の読み書き・列挙・削除は `AndroidSafStorageService` と MethodChannel を経由する。
- 通常パスと SAF URI の分岐は DataSource 層に閉じ込め、UI や Entity に持ち込まない。
- フォルダ選択ダイアログをキャンセルした場合、選択済みの外部フォルダをアプリ内保存へ勝手に切り替えない。
- 保存失敗を握りつぶさず、呼び出し元が利用者へ通知できるように例外・失敗を伝播させる。

## Track Logs

- トラックログは位置情報更新時に保存して、タスク終了によるデータ損失を減らす。
- 一覧での選択状態と、地図上の表示条件は別の状態として扱う。
- 地図表示は「設定の表示期間」と「明示的に選択したログのみ」を切り替えられるようにする。
- 保存フォルダを切り替えた場合は、前フォルダ由来の選択状態と地図表示フィルタをリセットする。
- 設定の表示期間へ戻す場合は、トラックログ一覧の選択状態も解除する。
- 自動削除の仕様を変更する場合、既存ログを意図せず削除しないよう明示的な説明・確認を設ける。

## UI

- Material Design を基本とし、既存の `AppTheme` を優先して使う。
- 文字サイズ設定（`textScaleProvider`）を考慮し、大きな文字でも操作ボタン・一覧が崩れないようにする。
- 位置情報・ストレージの権限がない場合や、保存に失敗した場合は、利用者が次に取る操作が分かる表示にする。
- 地図のピン追加・トラック記録は、現在の保存先が利用可能な状態でのみ実行する。
- 既存の画面文言・操作フローを変更する場合は、設定画面・地図画面・トラック一覧の整合性を確認する。

## Platform Integration

- Android のネイティブ実装は `android/app/src/main/kotlin/` に置く。
- iOS のフォルダアクセスはセキュリティスコープブックマークを使い、既存の `IosDirectoryService` を経由する。
- Podfile、Xcode プロジェクト、Workspace の変更は、関連するプラットフォームのビルドで確認してからコミットする。
- `.idea/`、`*.iml`、`xcuserdata/`、`Pods/`、`ephemeral/` などのIDE・ビルド生成物は原則コミットしない。
- 個人用の実機位置シミュレーションGPXや起動設定を、明示的な目的なくコミットしない。

## Git

- 通常の開発は `feature/<feature-name>`、不具合修正は `fix/<issue-name>`、雑務は `chore/<topic>` ブランチで行う。
- リリース準備には `release/<version>` ブランチを使用する。
- `main` へ直接コミットしない。`develop` を統合ブランチとして扱う。
- 1つの機能・修正・設定変更ごとにコミットを分ける。
- 関係のないファイルや既存の未コミット変更を、コミットに含めない。
- コミット前に `git diff --check` を実行する。
- 破壊的な Git 操作（reset --hard、checkoutによる破棄など）は、ユーザーが明示的に依頼した場合だけ実行する。

## Tests and Verification

- Domain Entity、Model の JSON 変換、Repository、UseCase を変更した場合は、対応するユニットテストを追加・更新する。
- 保存先フォールバック、SAF URI と通常パスの分岐、トラック表示フィルタを変更した場合は、回帰ケースをテストする。
- 画面の主要操作を変更する場合は、可能であれば Widget Test または Integration Test を追加する。
- 変更後は対象ファイルに `dart format` を実行する。
- PR 前に `flutter analyze` と `flutter test` を実行する。
- Android / iOS / macOS のネイティブ設定を変更した場合は、該当プラットフォームのビルドも確認する。
