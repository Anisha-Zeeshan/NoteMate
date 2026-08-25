import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class OnlineAIService {
  static const String _apiKey = ApiConfig.geminiApiKey;
  static const String _model = 'gemini-2.5-flash';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  // ── Check internet ───────────────────────────────────────
  static Future<bool> isOnline() async {
    try {
      final result = await InternetAddress.lookup(
          'google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty &&
          result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // ── Summary Notes ────────────────────────────────────────
  static Future<String> generateSummary(
      String text) async {
    return await _geminiRequest(
      '''Create concise SUMMARY NOTES from the text below.

Format your response exactly like this:

## 📌 Key Points
- (bullet point 1)
- (bullet point 2)
- (up to 8 key points max)

## 💡 Main Idea
(1-2 sentences summarizing the core message)

## 🔑 Keywords
(comma-separated important keywords)

Text to summarize:
$text''',
      temperature: 0.4,
    );
  }

  // ── Detailed Notes ───────────────────────────────────────
  static Future<String> generateDetailedNotes(
      String text) async {
    return await _geminiRequest(
      '''Create comprehensive DETAILED STUDY NOTES from the text below.

Format your response using markdown:

# (Infer a suitable title from the content)

## Overview
(Brief overview in 2-3 sentences)

## Key Concepts
(Explain each major concept clearly with subheadings)

## Important Details
(All supporting details, facts, examples)

## Key Definitions
(Any terms that need defining)

## Summary
(Closing summary in 3-4 sentences)

Text to convert:
$text''',
      temperature: 0.4,
    );
  }

  // ── Tags ─────────────────────────────────────────────────
  static Future<List<String>> generateTags(
      String text) async {
    try {
      final result = await _geminiRequest(
        'Generate 3 to 5 relevant tags for this text. '
            'Return ONLY the tags separated by commas, '
            'nothing else:\n\n$text',
        temperature: 0.4,
      );
      return result
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();
    } catch (e) {
      return ['note'];
    }
  }

  static Future<List<String>> autoTagNote(
      String text) async {
    return await generateTags(text);
  }

  // ── Gemini Chat ──────────────────────────────────────────
  static Future<String> generateChatResponse(
      String userMessage,
      List<Map<String, String>> history,
      ) async {
    final url = Uri.parse(
        '$_baseUrl/$_model:generateContent?key=$_apiKey');

    final contents = history.map((msg) {
      return {
        'role': msg['role'] == 'user'
            ? 'user'
            : 'model',
        'parts': [
          {'text': msg['content']}
        ],
      };
    }).toList();

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json'
      },
      body: jsonEncode({
        'contents': contents,
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 2048,
        },
        'systemInstruction': {
          'parts': [
            {
              'text':
              'You are a helpful AI assistant '
                  'inside NoteMate study app. '
                  'Help users with notes, studies, '
                  'and questions. Be concise.'
            }
          ]
        }
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates']?[0]?['content']
      ?['parts']?[0]?['text'] ??
          'No response';
    }
    throw Exception(
        'Gemini error: ${response.statusCode}');
  }

  // ── Gemini Request ───────────────────────────────────────
  static Future<String> _geminiRequest(
      String prompt, {
        double temperature = 0.4,
      }) async {
    final url = Uri.parse(
        '$_baseUrl/$_model:generateContent?key=$_apiKey');

    int attempts = 0;
    while (attempts < 3) {
      attempts++;

      final response = await http
          .post(
        url,
        headers: {
          'Content-Type': 'application/json'
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': temperature,
            'maxOutputTokens': 4096,
          }
        }),
      )
          .timeout(const Duration(seconds: 30));

      debugPrint(
          'OnlineAI: status ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates']?[0]?['content']
        ?['parts']?[0]?['text'] ??
            'Could not generate notes';
      } else if (response.statusCode == 503 ||
          response.statusCode == 429) {
        if (attempts < 3) {
          await Future.delayed(
              Duration(seconds: 3 * attempts));
          continue;
        }
        throw Exception('Server busy');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(
            error['error']?['message'] ??
                'Unknown error');
      }
    }
    throw Exception('Max retries reached');
  }
}