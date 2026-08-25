import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:fllama/fllama.dart';
import 'model_manager.dart';

class LlamaService {
  static final LlamaService _instance =
  LlamaService._internal();
  factory LlamaService() => _instance;
  LlamaService._internal();

  bool _isLoaded = false;
  String? _modelPath;
  double? _contextId;

  bool get isLoaded => _isLoaded;

  Future<void> loadModel() async {
    if (_isLoaded) return;
    _modelPath = await ModelManager().modelPath;
    debugPrint(
        'LlamaService: Loading from $_modelPath');

    final result =
    await Fllama.instance()?.initContext(
      _modelPath!,
      nCtx: 4096,
      nThreads: 4,
      nGpuLayers: 0,
    );

    if (result != null &&
        result['contextId'] != null) {
      _contextId =
          (result['contextId'] as num).toDouble();
      _isLoaded = true;
      debugPrint(
          'LlamaService: Ready ✅ contextId=$_contextId');
    } else {
      throw Exception(
          'Model initialization failed — null contextId');
    }
  }

  Future<void> unloadModel() async {
    if (_contextId != null) {
      await Fllama.instance()
          ?.releaseContext(_contextId!);
    }
    _contextId = null;
    _isLoaded = false;
    debugPrint('LlamaService: Model unloaded');
  }

  // ✅ Exact same generate as working app
  Stream<String> generate({
    required String prompt,
    int maxTokens = 512,
  }) async* {
    if (!_isLoaded || _contextId == null) {
      throw Exception('Model not loaded');
    }

    final result =
    await Fllama.instance()?.completion(
      _contextId!,
      prompt: prompt,
      temperature: 0.7,
      topP: 0.95,
      nPredict: maxTokens,
      penaltyRepeat: 1.1,
    );

    developer.log('RESULT: $result',
        name: 'LlamaService');

    if (result == null) {
      yield 'No response.';
      return;
    }

    String found = '';
    for (final entry in result.entries) {
      developer.log(
          'KEY: ${entry.key} => VALUE: ${entry.value}',
          name: 'LlamaService');
      if (entry.value is String &&
          (entry.value as String).length > 2) {
        found = entry.value as String;
        break;
      }
    }

    yield found.isNotEmpty
        ? found
        : 'Could not generate response.';
  }
}