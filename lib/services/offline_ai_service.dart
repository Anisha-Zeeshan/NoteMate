import 'package:flutter/foundation.dart';
import 'llama_service.dart';
import 'model_manager.dart';

class OfflineAIService {
  static final OfflineAIService _instance =
  OfflineAIService._internal();
  factory OfflineAIService() => _instance;
  OfflineAIService._internal();

  final LlamaService _llama = LlamaService();
  final ModelManager _modelManager = ModelManager();

  bool _isInitializing = false;

  static final ValueNotifier<bool> readyNotifier =
  ValueNotifier(false);
  static final ValueNotifier<double> progressNotifier =
  ValueNotifier(0.0);
  static final ValueNotifier<String> statusNotifier =
  ValueNotifier('Not started');

  bool get isReady => _llama.isLoaded;

  Future<void> initialize() async {
    if (isReady) return;
    if (_isInitializing) return;
    _isInitializing = true;

    try {
      statusNotifier.value = 'Checking model...';
      progressNotifier.value = 0.0;

      final ready =
      await _modelManager.isModelReady();

      if (!ready) {
        bool copySuccess = false;
        String copyError = '';

        await _modelManager.copyModelFromAssets(
          onProgress: (p) {
            progressNotifier.value = p * 0.7;
            statusNotifier.value =
            'Copying: ${(p * 100).toStringAsFixed(0)}%';
          },
          onComplete: () {
            copySuccess = true;
            progressNotifier.value = 0.7;
            statusNotifier.value = 'Model copied ✅';
          },
          onError: (e) {
            copyError = e;
          },
        );

        if (!copySuccess) {
          statusNotifier.value =
          'Failed: $copyError';
          progressNotifier.value = 0.0;
          _isInitializing = false;
          return;
        }
      } else {
        progressNotifier.value = 0.7;
      }

      statusNotifier.value =
      'Starting AI engine...';
      progressNotifier.value = 0.8;
      await _llama.loadModel();

      progressNotifier.value = 1.0;
      statusNotifier.value = 'AI Ready ✅';
      readyNotifier.value = true;
      debugPrint('OfflineAI: Ready ✅');
    } catch (e) {
      readyNotifier.value = false;
      statusNotifier.value = 'Failed: $e';
      progressNotifier.value = 0.0;
      debugPrint('OfflineAI: Failed — $e');
    } finally {
      _isInitializing = false;
    }
  }

  // ✅ Cleans multi-image OCR dividers and limits input
  String _prepareInput(String text) {
    String cleaned = text
        .replaceAll(
        RegExp(r'--- Image \d+ ---'), '')
        .replaceAll(
        RegExp(r'--- Image \d+: extraction failed ---'),
        '')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
    final words = cleaned
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    return words.length > 500
        ? '${words.take(500).join(' ')}...'
        : cleaned;
  }

  String _cleanOutput(String raw) {
    String text = raw;
    final remove = [
      '<|im_end|>',
      '<|im_start|>',
      '<|end|>',
      '<|assistant|>',
      '<|endoftext|>',
    ];
    for (final tag in remove) {
      text = text.replaceAll(tag, '');
    }
    return text.trim();
  }

  Future<String> _generate(String prompt,
      {int maxTokens = 512}) async {
    if (!_llama.isLoaded) {
      return 'Offline AI not ready.';
    }
    String output = '';
    await for (final chunk in _llama.generate(
      prompt: prompt,
      maxTokens: maxTokens,
    )) {
      output += chunk;
    }
    return _cleanOutput(output);
  }

  // ── Summary ───────────────────────────────────────
  Future<String> generateSummary(
      String text) async {
    if (!isReady) {
      await initialize();
      if (!isReady) return 'Offline AI not ready.';
    }
    final input = _prepareInput(text);
    final prompt =
        '<|im_start|>system\n'
        'You are a study notes assistant. '
        'Write only the notes, nothing else.\n'
        '<|im_end|>\n'
        '<|im_start|>user\n'
        'Summarize this into key points:\n\n'
        '$input\n'
        '<|im_end|>\n'
        '<|im_start|>assistant\n';
    return await _generate(prompt, maxTokens: 400);
  }

  // ── Detailed Notes ────────────────────────────────
  Future<String> generateDetailedNotes(
      String text) async {
    if (!isReady) {
      await initialize();
      if (!isReady) return 'Offline AI not ready.';
    }
    final input = _prepareInput(text);
    final prompt =
        '<|im_start|>system\n'
        'You are a study notes assistant. '
        'Write only the notes, nothing else.\n'
        '<|im_end|>\n'
        '<|im_start|>user\n'
        'Create detailed study notes from this:\n\n'
        '$input\n'
        '<|im_end|>\n'
        '<|im_start|>assistant\n';
    return await _generate(prompt, maxTokens: 600);
  }

  // ── Chat ──────────────────────────────────────────
  Future<String> generateChatResponse(
      String userMessage) async {
    if (!isReady) {
      await initialize();
      if (!isReady) return 'Offline AI not ready.';
    }
    final prompt =
        '<|im_start|>system\n'
        'You are NoteMate AI, a helpful study assistant. '
        'Give short clear answers.\n'
        '<|im_end|>\n'
        '<|im_start|>user\n'
        '$userMessage\n'
        '<|im_end|>\n'
        '<|im_start|>assistant\n';
    return await _generate(prompt, maxTokens: 300);
  }
}