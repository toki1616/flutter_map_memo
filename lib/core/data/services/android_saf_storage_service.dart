import 'package:flutter/services.dart';

/// Android Storage Access Framework (SAF) の永続 URI を介したファイル操作。
///
/// Download など Scoped Storage の対象フォルダは dart:io で直接操作せず、
/// このサービスを通してネイティブの ContentResolver でアクセスする。
class AndroidSafStorageService {
  static const _channel = MethodChannel('com.example.flutter_map_memo/folder');

  static bool isSafUri(String value) =>
      Uri.tryParse(value)?.scheme == 'content';

  static Future<String?> pickDirectory() =>
      _channel.invokeMethod<String>('pickDirectory');

  static Future<bool> existsDirectory(String rootUri) async =>
      await _channel.invokeMethod<bool>('directoryExists', {
        'rootUri': rootUri,
      }) ??
      false;

  static Future<List<SafEntry>> listEntries(
    String rootUri,
    String relativePath,
  ) async {
    final result = await _channel.invokeMethod<List<dynamic>>('listEntries', {
      'rootUri': rootUri,
      'relativePath': relativePath,
    });
    return (result ?? const [])
        .cast<Map<dynamic, dynamic>>()
        .map(
          (entry) => SafEntry(
            name: entry['name']! as String,
            isDirectory: entry['isDirectory']! as bool,
          ),
        )
        .toList();
  }

  static Future<String?> readFile(String rootUri, String relativePath) =>
      _channel.invokeMethod<String>('readFile', {
        'rootUri': rootUri,
        'relativePath': relativePath,
      });

  static Future<void> writeFile(
    String rootUri,
    String relativePath,
    String content,
  ) => _channel.invokeMethod<void>('writeFile', {
    'rootUri': rootUri,
    'relativePath': relativePath,
    'content': content,
  });

  static Future<void> deleteFile(String rootUri, String relativePath) =>
      _channel.invokeMethod<void>('deleteFile', {
        'rootUri': rootUri,
        'relativePath': relativePath,
      });
}

class SafEntry {
  final String name;
  final bool isDirectory;

  const SafEntry({required this.name, required this.isDirectory});
}
