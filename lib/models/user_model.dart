class UserModel {
  String userID;
  String name;
  String email;
  DateTime createdAt;
  int totalNotes;
  int totalStudyTime;

  UserModel({
    required this.userID,
    required this.name,
    required this.email,
    required this.createdAt,
    this.totalNotes = 0,
    this.totalStudyTime = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'userID': userID,
      'name': name,
      'email': email,
      'createdAt': createdAt.toIso8601String(),
      'totalNotes': totalNotes,
      'totalStudyTime': totalStudyTime,
    };
  }

  factory UserModel.fromMap(
      Map<String, dynamic> map) {
    return UserModel(
      userID: map['userID'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      createdAt: DateTime.parse(
          map['createdAt'] ??
              DateTime.now().toIso8601String()),
      totalNotes: map['totalNotes'] ?? 0,
      totalStudyTime: map['totalStudyTime'] ?? 0,
    );
  }
}