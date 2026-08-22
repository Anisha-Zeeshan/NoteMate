import 'package:cloud_firestore/cloud_firestore.dart';

class NoteModel {
  String id;
  String title;
  String content;
  List<String> tags;
  String userID;
  DateTime createdAt;
  bool isSynced;

  NoteModel({
    required this.id,
    required this.title,
    required this.content,
    required this.tags,
    required this.userID,
    required this.createdAt,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'tags': tags,
      'userID': userID,
      'createdAt': createdAt,
      'isSynced': isSynced,
    };
  }

  factory NoteModel.fromMap(Map<String, dynamic> map) {
    return NoteModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      tags: List<String>.from(map['tags'] ?? []),
      userID: map['userID'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isSynced: map['isSynced'] ?? false,
    );
  }
}