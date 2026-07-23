import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../../../core/constants/app_constants.dart';
import '../../../core/data/services/android_saf_storage_service.dart';
import '../models/pin_model.dart';

/// {rootPath}/save_data/map_data/pin.json への読み書きを担うデータソース
abstract class PinLocalDataSource {
  Future<List<PinModel>> loadPins(String rootPath);
  Future<void> savePins(String rootPath, List<PinModel> pins);
}

class PinLocalDataSourceImpl implements PinLocalDataSource {
  String _pinFilePath(String rootPath) => p.join(
    rootPath,
    AppConstants.saveDataFolderName,
    AppConstants.mapDataFolderName,
    AppConstants.pinFileName,
  );

  @override
  Future<List<PinModel>> loadPins(String rootPath) async {
    try {
      if (AndroidSafStorageService.isSafUri(rootPath)) {
        final content = await AndroidSafStorageService.readFile(
          rootPath,
          _pinRelativePath(),
        );
        if (content == null) return [];
        final list = json.decode(content) as List<dynamic>;
        return list
            .map((e) => PinModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      final file = File(_pinFilePath(rootPath));
      if (!await file.exists()) return [];
      final content = await file.readAsString();
      final list = json.decode(content) as List<dynamic>;
      return list
          .map((e) => PinModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> savePins(String rootPath, List<PinModel> pins) async {
    try {
      final content = const JsonEncoder.withIndent(
        '  ',
      ).convert(pins.map((e) => e.toJson()).toList());
      if (AndroidSafStorageService.isSafUri(rootPath)) {
        await AndroidSafStorageService.writeFile(
          rootPath,
          _pinRelativePath(),
          content,
        );
        return;
      }
      final file = File(_pinFilePath(rootPath));

      // 💡【追加】親フォルダが存在するか事前に確認し、なければ作成を待つ
      final parentDir = file.parent;
      if (!await parentDir.exists()) {
        await parentDir.create(recursive: true);
      }

      await file.writeAsString(content);
    } catch (e) {
      // デバッグ用にコンソールにエラー原因を出力
      print('[PinLocalDataSource] ピンファイル書き込みエラー: $e');
      // 💡【重要】例外を上層（add_pin_bottom_sheet）へ投げてローディングを解除させる
      rethrow;
    }
  }

  String _pinRelativePath() => p.join(
    AppConstants.saveDataFolderName,
    AppConstants.mapDataFolderName,
    AppConstants.pinFileName,
  );
}
