import 'package:appwrite/models.dart';

class ReviewHistory {
  final String id;
  final String phraseId;
  final String userId;
  final DateTime reviewDate;
  final bool wasCorrect;
  final double easeFactor;
  final int interval;

  ReviewHistory({
    required this.id,
    required this.phraseId,
    required this.userId,
    required this.reviewDate,
    required this.wasCorrect,
    this.easeFactor = 2.5,
    this.interval = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'phrase_id': phraseId,
      'user_id': userId,
      'review_date': reviewDate.toIso8601String(),
      'was_correct': wasCorrect,
      'ease_factor': easeFactor,
      'interval': interval,
    };
  }

  factory ReviewHistory.fromDocument(Document document) {
    return ReviewHistory(
      id: document.$id,
      phraseId: document.data['phrase_id'],
      userId: document.data['user_id'],
      reviewDate: DateTime.parse(document.data['review_date']),
      wasCorrect: document.data['was_correct'],
      easeFactor: document.data['ease_factor'].toDouble(),
      interval: document.data['interval'],
    );
  }

  factory ReviewHistory.fromMap(Map<String, dynamic> map) {
    return ReviewHistory(
      id: map.containsKey('\$id') ? map['\$id'] : map['id'],
      phraseId: map['phrase_id'],
      userId: map['user_id'],
      reviewDate: map['review_date'] is String
          ? DateTime.parse(map['review_date'])
          : map['review_date'],
      wasCorrect: map['was_correct'],
      easeFactor:
          map['ease_factor'] != null ? map['ease_factor'].toDouble() : 2.5,
      interval: map['interval'] ?? 1,
    );
  }

  ReviewHistory copyWith({
    String? id,
    String? phraseId,
    String? userId,
    DateTime? reviewDate,
    bool? wasCorrect,
    double? easeFactor,
    int? interval,
  }) {
    return ReviewHistory(
      id: id ?? this.id,
      phraseId: phraseId ?? this.phraseId,
      userId: userId ?? this.userId,
      reviewDate: reviewDate ?? this.reviewDate,
      wasCorrect: wasCorrect ?? this.wasCorrect,
      easeFactor: easeFactor ?? this.easeFactor,
      interval: interval ?? this.interval,
    );
  }
}
