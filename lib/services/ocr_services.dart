import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../config/api_config.dart';

class OCRService {

  static const String _apiKey = ApiConfig.geminiApiKey;
  static const String _model = 'gemini-2.5-flash';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  static final TextRecognizer _recognizer =
  TextRecognizer(
      script: TextRecognitionScript.latin);

  // ── Check internet ─────────────────────────────────────────
  static Future<bool> isOnline() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty &&
          result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // ── Main OCR — auto switches online/offline ────────────────
  static Future<String> extractText(File imageFile) async {
    final online = await isOnline();

    if (online) {
      print('Online — Gemini OCR');
      final result = await _geminiOCR(imageFile);
      if (result.startsWith('Error:')) {
        print('Gemini failed — falling back to ML Kit');
        return await _mlKitOCR(imageFile);
      }
      return result;
    } else {
      print('Offline — ML Kit OCR');
      return await _mlKitOCR(imageFile);
    }
  }

  // ── Handwritten text ───────────────────────────────────────
  static Future<String> extractHandwrittenText(File imageFile) async {
    final online = await isOnline();

    if (online) {
      print('Online — Gemini handwriting OCR');
      return await _geminiOCR(imageFile);
    } else {
      print('Offline — ML Kit handwriting OCR');
      return await _mlKitOCR(imageFile);
    }
  }

  // ── Gemini OCR ─────────────────────────────────────────────
  static Future<String> _geminiOCR(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final url = Uri.parse(
          '$_baseUrl/$_model:generateContent?key=$_apiKey');

      int attempts = 0;
      while (attempts < 3) {
        attempts++;

        final body = jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text':
                  '''You are an expert OCR engine trained specifically for both printed and handwritten text recognition.

STRICT RULES:
- Read EVERY single word carefully, including messy, cursive, or fast handwriting
- Use surrounding context and word shapes to decode unclear letters
- Preserve EXACT line breaks, paragraph spacing, and document structure
- For printed text: extract with 100% accuracy
- For handwritten text: use context clues intelligently for unclear letters
- Preserve bullet points, numbering, underlines, headings as-is
- Do NOT skip any text including margin notes, side annotations, corrections
- Only mark truly unreadable words as [?word?]
- Do NOT add any explanation, preamble, or commentary
- Return ONLY the raw extracted text, nothing else'''
                },
                {
                  'inline_data': {
                    'mime_type': 'image/jpeg',
                    'data': base64Image,
                  }
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.1,
            'maxOutputTokens': 4096,
          }
        });

        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json'
          },
          body: body,
        ).timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final text = data['candidates']?[0]
          ?['content']?['parts']?[0]?['text'];
          return text ?? 'No text found';
        } else if (response.statusCode == 503 ||
            response.statusCode == 429) {
          if (attempts < 3) {
            await Future.delayed(
                Duration(seconds: 3 * attempts));
            continue;
          }
          return 'Error: Server busy. Try again.';
        } else {
          final error = jsonDecode(response.body);
          final msg = error['error']?['message'] ??
              'Unknown error';
          return 'Error: $msg';
        }
      }
      return 'Error: Max retries reached';
    } catch (e) {
      return 'Error: $e';
    }
  }

  // ── ML Kit OCR ─────────────────────────────────────────────
  static Future<String> _mlKitOCR(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _recognizer.processImage(inputImage);
      final text = recognizedText.text;
      return text.isNotEmpty ? text : 'No text found';
    } catch (e) {
      return 'Offline OCR error: $e';
    }
  }

  static void dispose() {
    _recognizer.close();
  }
}