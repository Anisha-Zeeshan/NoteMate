import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StorageService {

  // Save image locally — no Firebase Storage needed
  static Future<String> saveImageLocally(
      File imageFile) async {
    try {
      // Get app documents directory
      String userID =
          FirebaseAuth.instance.currentUser!.uid;
      String fileName =
          '${userID}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Return local path
      return imageFile.path;
    } catch (e) {
      print('Storage error: $e');
      return '';
    }
  }

  // Track study session
  static Future<void> trackStudySession({
    required String noteID,
    required int timeSpentSeconds,
  }) async {
    try {
      String userID =
          FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance
          .collection('sessions')
          .add({
        'noteID': noteID,
        'userID': userID,
        'timeSpent': timeSpentSeconds,
        'date': DateTime.now().toIso8601String(),
        'createdAt': Timestamp.now(),
      });
      print('Session tracked: $timeSpentSeconds seconds');
    } catch (e) {
      print('Session tracking error: $e');
    }
  }

  // Get performance stats
  static Future<Map<String, dynamic>>
  getPerformanceStats() async {
    try {
      String userID =
          FirebaseAuth.instance.currentUser!.uid;

      // Get total notes
      QuerySnapshot notesSnapshot =
      await FirebaseFirestore.instance
          .collection('notes')
          .where('userID', isEqualTo: userID)
          .get();

      // Get all sessions
      QuerySnapshot sessionsSnapshot =
      await FirebaseFirestore.instance
          .collection('sessions')
          .where('userID', isEqualTo: userID)
          .get();

      int totalNotes = notesSnapshot.docs.length;
      int totalTimeSeconds = 0;
      int totalSessions =
          sessionsSnapshot.docs.length;

      for (var doc in sessionsSnapshot.docs) {
        Map<String, dynamic> session =
        doc.data() as Map<String, dynamic>;
        totalTimeSeconds +=
        (session['timeSpent'] as int? ?? 0);
      }

      int avgTimeSeconds = totalSessions > 0
          ? (totalTimeSeconds / totalSessions)
          .round()
          : 0;

      return {
        'totalNotes': totalNotes,
        'totalTime': totalTimeSeconds,
        'totalSessions': totalSessions,
        'avgTime': avgTimeSeconds,
      };
    } catch (e) {
      print('Performance stats error: $e');
      return {
        'totalNotes': 0,
        'totalTime': 0,
        'totalSessions': 0,
        'avgTime': 0,
      };
    }
  }

  // Get weekly stats for chart
  static Future<List<double>>
  getWeeklyStats() async {
    try {
      String userID =
          FirebaseAuth.instance.currentUser!.uid;
      List<double> weeklyData =
      List.filled(7, 0.0);

      DateTime now = DateTime.now();
      for (int i = 0; i < 7; i++) {
        DateTime day =
        now.subtract(Duration(days: 6 - i));
        String dateStr =
            '${day.year}-${day.month}-${day.day}';

        QuerySnapshot daySnapshot =
        await FirebaseFirestore.instance
            .collection('notes')
            .where('userID', isEqualTo: userID)
            .get();

        int count = daySnapshot.docs.where((doc) {
          Map<String, dynamic> note =
          doc.data() as Map<String, dynamic>;
          if (note['createdAt'] == null) return false;
          DateTime noteDate =
          note['createdAt'].toDate();
          return noteDate.year == day.year &&
              noteDate.month == day.month &&
              noteDate.day == day.day;
        }).length;

        weeklyData[i] = count.toDouble();
      }
      return weeklyData;
    } catch (e) {
      return List.filled(7, 0.0);
    }
  }
}