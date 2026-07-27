import UIKit
import Flutter

/// iOS のフォルダ永続アクセスを管理する AppDelegate
///
/// iOS のサンドボックス制約により、ユーザーが選択したフォルダへのアクセス権は
/// アプリを終了すると失われる。
/// これを解決するために「セキュリティスコープブックマーク」を使用する。
///
/// 仕組み:
///   1. フォルダ選択時に URL → bookmarkData（合鍵）を生成して UserDefaults に保存
///   2. 次回起動時に bookmarkData → URL を復元し startAccessingSecurityScopedResource() を呼ぶ
///   3. アクセス不要になったら stopAccessingSecurityScopedResource() で解放する
@main
@objc class AppDelegate: FlutterAppDelegate, UIDocumentPickerDelegate {

  var securedUrl: URL?
  var pendingResult: FlutterResult?
  private let bookmarkKey = "folder_bookmark_data"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    let controller: FlutterViewController = window?.rootViewController as! FlutterViewController

    // チャンネル名は ios_directory_service.dart の _channel と一致させること
    let channel = FlutterMethodChannel(
      name: "com.example.flutter_map_memo/folder",
      binaryMessenger: controller.binaryMessenger
    )

    channel.setMethodCallHandler({ [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      guard let self = self else { return }
      switch call.method {
      case "pickDirectory":
        self.pendingResult = result
        self.openDocumentPicker(controller: controller)
      case "restoreDirectoryAccess":
        self.restoreAccess(result: result)
      case "stopDirectoryAccess":
        self.stopAccess(result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    })

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // MARK: - フォルダ選択ダイアログ

  private func openDocumentPicker(controller: UIViewController) {
    let picker: UIDocumentPickerViewController
    if #available(iOS 14.0, *) {
      picker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder], asCopy: false)
    } else {
      picker = UIDocumentPickerViewController(documentTypes: ["public.folder"], in: .open)
    }
    picker.delegate = self
    picker.allowsMultipleSelection = false
    controller.present(picker, animated: true)
  }

  // MARK: - UIDocumentPickerDelegate

  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    guard let url = urls.first else {
      pendingResult?(nil); pendingResult = nil; return
    }
    guard url.startAccessingSecurityScopedResource() else {
      pendingResult?(nil); pendingResult = nil; return
    }
    do {
      let bookmarkData = try url.bookmarkData(
        options: .minimalBookmark,
        includingResourceValuesForKeys: nil,
        relativeTo: nil
      )
      UserDefaults.standard.set(bookmarkData, forKey: bookmarkKey)
      self.securedUrl = url
      pendingResult?(url.path)
    } catch {
      print("[AppDelegate] ブックマーク生成エラー: \(error)")
      url.stopAccessingSecurityScopedResource()
      pendingResult?(nil)
    }
    pendingResult = nil
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    pendingResult?(nil); pendingResult = nil
  }

  // MARK: - アクセス権の復元（起動時）

  private func restoreAccess(result: FlutterResult) {
    guard let bookmarkData = UserDefaults.standard.data(forKey: bookmarkKey) else {
      result(nil); return
    }
    do {
      var isStale = false
      let url = try URL(
        resolvingBookmarkData: bookmarkData,
        options: .withoutUI,
        relativeTo: nil,
        bookmarkDataIsStale: &isStale
      )
      if isStale {
        let newBookmark = try url.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
        UserDefaults.standard.set(newBookmark, forKey: bookmarkKey)
      }
      guard url.startAccessingSecurityScopedResource() else { result(nil); return }
      self.securedUrl = url
      result(url.path)
    } catch {
      print("[AppDelegate] アクセス権復元エラー: \(error)")
      result(nil)
    }
  }

  // MARK: - アクセス権の解放

  private func stopAccess(result: FlutterResult) {
    securedUrl?.stopAccessingSecurityScopedResource()
    securedUrl = nil
    result(nil)
  }
}
