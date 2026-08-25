import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ChatSession {
  final String id;
  final String title;
  final DateTime createdAt;
  final List<Map<String, String>> messages;

  ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.messages,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'createdAt': createdAt.toIso8601String(),
    'messages': messages,
  };

  factory ChatSession.fromJson(
      Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'],
      title: json['title'],
      createdAt:
      DateTime.parse(json['createdAt']),
      messages: List<Map<String, String>>.from(
        (json['messages'] as List).map(
              (m) => Map<String, String>.from(m),
        ),
      ),
    );
  }
}

class ChatStorageService {
  static const String _key = 'chat_sessions';

  // ── Load all sessions ─────────────────────────
  static Future<List<ChatSession>>
  loadSessions() async {
    final prefs =
    await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final List list = jsonDecode(raw);
      return list
          .map((j) => ChatSession.fromJson(j))
          .toList()
        ..sort((a, b) =>
            b.createdAt.compareTo(a.createdAt));
    } catch (_) {
      return [];
    }
  }

  // ── Save session ──────────────────────────────
  static Future<void> saveSession(
      ChatSession session) async {
    final sessions = await loadSessions();
    final idx = sessions
        .indexWhere((s) => s.id == session.id);
    if (idx >= 0) {
      sessions[idx] = session;
    } else {
      sessions.insert(0, session);
    }
    // Keep max 20 sessions
    final trimmed = sessions.take(20).toList();
    final prefs =
    await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(
          trimmed.map((s) => s.toJson()).toList()),
    );
  }

  // ── Delete session ────────────────────────────
  static Future<void> deleteSession(
      String id) async {
    final sessions = await loadSessions();
    sessions.removeWhere((s) => s.id == id);
    final prefs =
    await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(sessions
          .map((s) => s.toJson())
          .toList()),
    );
  }

  // ── Generate title from first message ─────────
  static String generateTitle(
      List<Map<String, String>> messages) {
    final first = messages
        .firstWhere(
          (m) => m['role'] == 'user',
      orElse: () => {'content': 'New Chat'},
    )['content'] ??
        'New Chat';
    return first.length > 30
        ? '${first.substring(0, 30)}...'
        : first;
  }
}