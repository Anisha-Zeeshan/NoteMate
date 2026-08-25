import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

class NotesService {
  static String get _userID =>
      FirebaseAuth.instance.currentUser!.uid;

  // ── Save note ─────────────────────────────────────
  static Future<String> saveNote({
    required String title,
    required String content,
    required List<String> tags,
    String imageUrl = '',
    String type = 'manual',
    String teacherName = '',  // ✅ NEW
    String pdfPath = '',      // ✅ NEW
  }) async {
    try {
      DocumentReference docRef =
      await FirebaseFirestore.instance
          .collection('notes')
          .add({
        'title': title,
        'content': content,
        'tags': tags,
        'userID': _userID,
        'imageUrl': imageUrl,
        'type': type,
        'teacherName': teacherName,  // ✅ NEW
        'pdfPath': pdfPath,          // ✅ NEW
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
        'isSynced': true,
      });
      await docRef.update({'id': docRef.id});
      return 'success';
    } catch (e) {
      return 'Error: $e';
    }
  }

  // ── Get all notes stream ──────────────────────────
  static Stream<QuerySnapshot> getNotes() {
    return FirebaseFirestore.instance
        .collection('notes')
        .where('userID', isEqualTo: _userID)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ── Get notes by tag stream ───────────────────────
  static Stream<QuerySnapshot> getNotesByTag(
      String tag) {
    return FirebaseFirestore.instance
        .collection('notes')
        .where('userID', isEqualTo: _userID)
        .where('tags', arrayContains: tag)
        .snapshots();
  }

  // ── Edit note ─────────────────────────────────────
  static Future<String> editNote({
    required String noteID,
    required String title,
    required String content,
    required List<String> tags,
    String teacherName = '',  // ✅ NEW
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('notes')
          .doc(noteID)
          .update({
        'title': title,
        'content': content,
        'tags': tags,
        'teacherName': teacherName,  // ✅ NEW
        'updatedAt': Timestamp.now(),
      });
      return 'success';
    } catch (e) {
      return 'Error: $e';
    }
  }

  // ── Delete note ───────────────────────────────────
  static Future<String> deleteNote({
    required String noteID,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('notes')
          .doc(noteID)
          .delete();
      return 'success';
    } catch (e) {
      return 'Error: $e';
    }
  }

  // ── Search notes ──────────────────────────────────
  static Future<List<Map<String, dynamic>>>
  searchNotes({required String query}) async {
    try {
      QuerySnapshot snapshot =
      await FirebaseFirestore.instance
          .collection('notes')
          .where('userID', isEqualTo: _userID)
          .get();

      List<Map<String, dynamic>> results = [];
      String lowerQuery = query.toLowerCase();

      for (var doc in snapshot.docs) {
        Map<String, dynamic> note =
        doc.data() as Map<String, dynamic>;
        String title =
        (note['title'] ?? '').toLowerCase();
        String content =
        (note['content'] ?? '').toLowerCase();
        List<String> tags =
        List<String>.from(note['tags'] ?? []);
        bool tagMatch = tags.any((tag) =>
            tag.toLowerCase().contains(lowerQuery));

        if (title.contains(lowerQuery) ||
            content.contains(lowerQuery) ||
            tagMatch) {
          note['id'] = doc.id;
          results.add(note);
        }
      }
      return results;
    } catch (e) {
      return [];
    }
  }

  // ── Get all unique tags ───────────────────────────
  static Future<List<String>> getAllTags() async {
    try {
      QuerySnapshot snapshot =
      await FirebaseFirestore.instance
          .collection('notes')
          .where('userID', isEqualTo: _userID)
          .get();

      Set<String> tags = {};
      for (var doc in snapshot.docs) {
        Map<String, dynamic> note =
        doc.data() as Map<String, dynamic>;
        List<String> noteTags =
        List<String>.from(note['tags'] ?? []);
        tags.addAll(noteTags);
      }
      return tags.toList();
    } catch (e) {
      return [];
    }
  }

  // ── Track reading session ─────────────────────────
  static Future<void> trackSession({
    required String noteID,
    required int timeSpentSeconds,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('sessions')
          .add({
        'noteID': noteID,
        'userID': _userID,
        'timeSpent': timeSpentSeconds,
        'createdAt': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('Session error: $e');
    }
  }

  // ── Get performance stats ─────────────────────────
  static Future<Map<String, dynamic>>
  getPerformanceStats() async {
    try {
      QuerySnapshot notesSnapshot =
      await FirebaseFirestore.instance
          .collection('notes')
          .where('userID', isEqualTo: _userID)
          .get();

      QuerySnapshot sessionsSnapshot =
      await FirebaseFirestore.instance
          .collection('sessions')
          .where('userID', isEqualTo: _userID)
          .get();

      int totalNotes = notesSnapshot.docs.length;
      int totalTime = 0;
      int totalSessions =
          sessionsSnapshot.docs.length;

      for (var doc in sessionsSnapshot.docs) {
        Map<String, dynamic> s =
        doc.data() as Map<String, dynamic>;
        totalTime +=
        (s['timeSpent'] as int? ?? 0);
      }

      return {
        'totalNotes': totalNotes,
        'totalTime': totalTime,
        'totalSessions': totalSessions,
        'avgTime': totalSessions > 0
            ? (totalTime / totalSessions).round()
            : 0,
      };
    } catch (e) {
      return {
        'totalNotes': 0,
        'totalTime': 0,
        'totalSessions': 0,
        'avgTime': 0,
      };
    }
  }

  static Future<void> syncOfflineNotes() async {}
}