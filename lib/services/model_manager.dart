import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kAssetModelPath = 'assets/models/qwen2.5-0.5b-instruct-q4_k_m.gguf';
const String kModelFileName = 'qwen2.5-0.5b-instruct-q4_k_m.gguf';
const String kPrefModelCopied = 'model_copied';

class ModelManager {
  static final ModelManager _instance = ModelManager._internal();
  factory ModelManager() => _instance;
  ModelManager._internal();

  Future<String> get modelPath async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$kModelFileName';
  }

  Future<bool> isModelReady() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final copied = prefs.getBool(kPrefModelCopied) ?? false;
      if (!copied) return false;
      final path = await modelPath;
      return await File(path).exists();
    } catch (_) {
      return false;
    }
  }

  Future<void> copyModelFromAssets({
    required void Function(double percent) onProgress,
    required void Function() onComplete,
    required void Function(String error) onError,
  }) async {
    try {
      final path = await modelPath;
      final outFile = File(path);

      onProgress(0.1);
      final byteData = await rootBundle.load(kAssetModelPath);
      final bytes = byteData.buffer.asUint8List();

      onProgress(0.5);
      await outFile.writeAsBytes(bytes, flush: true);
      onProgress(1.0);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(kPrefModelCopied, true);

      onComplete();
    } catch (e) {
      onError(e.toString());
    }
  }

  Future<String> getModelSize() async {
    final path = await modelPath;
    final file = File(path);
    if (!await file.exists()) return '0 MB';
    final bytes = await file.length();
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }
}
