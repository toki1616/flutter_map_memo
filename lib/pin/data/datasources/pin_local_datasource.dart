import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../../../core/constants/app_constants.dart';
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
      final file = File(_pinFilePath(rootPath));

      // 💡【追加】親フォルダが存在するか事前に確認し、なければ作成を待つ
      final parentDir = file.parent;
      if (!await parentDir.exists()) {
        await parentDir.create(recursive: true);
      }

      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(
          pins.map((e) => e.toJson()).toList(),
        ),
      );
    } catch (e) {
      // デバッグ用にコンソールにエラー原因を出力
      print('[PinLocalDataSource] ピンファイル書き込みエラー: $e');
      // 💡【重要】例外を上層（add_pin_bottom_sheet）へ投げてローディングを解除させる
      rethrow;
    }
  }
}