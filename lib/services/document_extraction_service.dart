import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:docx_to_text/docx_to_text.dart';
import 'ocr_services.dart';
import '../config/api_config.dart';

class DocumentExtractionService {
  static const String _apiKey = ApiConfig.geminiApiKey;
  static const String _model = 'gemini-2.5-flash';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  // ── Main entry ────────────────────────────────────
  static Future<String> extractFromFiles(
      List<File> files) async {
    final buffer = StringBuffer();

    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      final ext = file.path.toLowerCase();

      if (files.length > 1) {
        buffer.writeln(
            '--- File ${i + 1}: ${_fileName(file)} ---\n');
      }

      String text;
      if (ext.endsWith('.pdf')) {
        text = await _extractFromPdf(file);
      } else if (ext.endsWith('.docx') ||
          ext.endsWith('.doc')) {
        text = await _extractFromDocx(file);
      } else {
        text = await OCRService.extractText(file);
      }

      buffer.writeln(text);
      if (files.length > 1) buffer.writeln();
    }

    return buffer.toString().trim();
  }

  // ── PDF — Syncfusion (offline) ────────────────────
  static Future<String> _extractFromPdf(
      File file) async {
    try {
      final bytes = await file.readAsBytes();
      final document =
      PdfDocument(inputBytes: bytes);
      final extractor = PdfTextExtractor(document);
      final text = extractor.extractText();
      document.dispose();

      if (text.trim().isNotEmpty) {
        return text.trim();
      }
      // Scanned PDF — fall back to Gemini
      return await _geminiDocumentOCR(file, 'PDF');
    } catch (e) {
      return 'PDF extraction error: $e';
    }
  }

  // ── DOCX — docx_to_text (offline) ────────────────
  // Falls back to Gemini only if offline extraction fails
  static Future<String> _extractFromDocx(
      File file) async {
    try {
      final bytes = await file.readAsBytes();
      // ✅ docx_to_text works fully offline
      final text = docxToText(bytes);
      if (text.trim().isNotEmpty) {
        return text.trim();
      }
      // Empty result — fall back to Gemini
      return await _geminiDocumentOCR(file, 'DOCX');
    } catch (e) {
      // Package failed — fall back to Gemini
      return await _geminiDocumentOCR(file, 'DOCX');
    }
  }

  // ── Gemini (online fallback) ──────────────────────
  static Future<String> _geminiDocumentOCR(
      File file, String fileType) async {
    try {
      final online = await OCRService.isOnline();
      if (!online) {
        if (fileType == 'DOCX') {
          return 'Could not read this DOCX file offline. '
              'Please connect to internet to try again.';
        }
        return 'Offline: Cannot extract from scanned '
            '$fileType without internet. '
            'Please connect and try again.';
      }

      final bytes = await file.readAsBytes();
      final base64Data = base64Encode(bytes);

      String mimeType;
      final ext = file.path.toLowerCase();
      if (ext.endsWith('.pdf')) {
        mimeType = 'application/pdf';
      } else {
        mimeType =
        'application/vnd.openxmlformats-officedocument'
            '.wordprocessingml.document';
      }

      final url = Uri.parse(
          '$_baseUrl/$_model:generateContent?key=$_apiKey');

      final body = jsonEncode({
        'contents': [
          {
            'parts': [
              {
                'text':
                'Extract ALL text from this $fileType '
                    'document exactly as it appears. '
                    'Preserve formatting, headings, '
                    'bullet points, and structure. '
                    'Return ONLY the extracted text, '
                    'no commentary.',
              },
              {
                'inline_data': {
                  'mime_type': mimeType,
                  'data': base64Data,
                }
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.1,
          'maxOutputTokens': 8192,
        }
      });

      final response = await http
          .post(
        url,
        headers: {
          'Content-Type': 'application/json'
        },
        body: body,
      )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]
        ?['content']?['parts']?[0]?['text'];
        return text ?? 'No text found in document';
      } else {
        final error = jsonDecode(response.body);
        final msg =
            error['error']?['message'] ??
                'Unknown error';
        return 'Document extraction failed: $msg';
      }
    } catch (e) {
      return 'Document extraction error: $e';
    }
  }

  static String _fileName(File file) {
    return file.path.split('/').last;
  }
}