import 'package:appwrite/models.dart';

class StudySession {
  final String id;
  final String userId;
  final DateTime startTime;
  final DateTime? endTime;
  final int totalPhrases;
  final int correctAnswers;
  final String sessionType;
  final String? languageId;
  final String? categoryId;

  StudySession({
    required this.id,
    required this.userId,
    required this.startTime,
    this.endTime,
    required this.totalPhrases,
    required this.correctAnswers,
    required this.sessionType,
    this.languageId,
    this.categoryId,
  });

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'total_phrases': totalPhrases,
      'correct_answers': correctAnswers,
      'session_type': sessionType,
      'language_id': languageId,
      'category_id': categoryId,
    };
  }

  factory StudySession.fromDocument(Document document) {
    return StudySession(
      id: document.$id,
      userId: document.data['user_id'],
      startTime: DateTime.parse(document.data['start_time']),
      endTime: document.data['end_time'] != null
          ? DateTime.parse(document.data['end_time'])
          : null,
      totalPhrases: document.data['total_phrases'],
      correctAnswers: document.data['correct_answers'],
      sessionType: document.data['session_type'],
      languageId: document.data['language_id'],
      categoryId: document.data['category_id'],
    );
  }

  factory StudySession.fromMap(Map<String, dynamic> map) {
    return StudySession(
      id: map.containsKey('\$id') ? map['\$id'] : map['id'],
      userId: map['user_id'],
      startTime: map['start_time'] is String
          ? DateTime.parse(map['start_time'])
          : map['start_time'],
      endTime: map['end_time'] != null
          ? (map['end_time'] is String
              ? DateTime.parse(map['end_time'])
              : map['end_time'])
          : null,
      totalPhrases: map['total_phrases'],
      correctAnswers: map['correct_answers'],
      sessionType: map['session_type'],
      languageId: map['language_id'],
      categoryId: map['category_id'],
    );
  }

  StudySession copyWith({
    String? id,
    String? userId,
    DateTime? startTime,
    DateTime? endTime,
    int? totalPhrases,
    int? correctAnswers,
    String? sessionType,
    String? languageId,
    String? categoryId,
  }) {
    return StudySession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      totalPhrases: totalPhrases ?? this.totalPhrases,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      sessionType: sessionType ?? this.sessionType,
      languageId: languageId ?? this.languageId,
      categoryId: categoryId ?? this.categoryId,
    );
  }

  // Hitung durasi sesi dalam menit
  int get durationMinutes {
    if (endTime == null) return 0;
    return endTime!.difference(startTime).inMinutes;
  }

  // Hitung persentase jawaban benar
  double get accuracyPercentage {
    if (totalPhrases == 0) return 0.0;
    return (correctAnswers / totalPhrases) * 100;
  }
}
