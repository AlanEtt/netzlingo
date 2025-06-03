import 'dart:math';
import 'package:intl/intl.dart';
import '../models/phrase.dart';
import '../services/database_service.dart';

class SpacedRepetitionService {
  final DatabaseService _databaseService = DatabaseService();

  // Implementasi algoritma SM-2 (Spaced Repetition)
  // Reference: https://en.wikipedia.org/wiki/SuperMemo#Algorithm_SM-2

  // Faktor default untuk algorithm
  static const double _initialEaseFactor = 2.5;
  static const int _initialInterval = 1; // dalam hari

  // Kalkulasi interval berdasarkan performance dan tingkat kesulitan
  Future<Map<String, dynamic>> calculateNextReview(
    int phraseId,
    bool wasCorrect,
    int responseQuality, // 0-5, dimana 0 = sangat sulit, 5 = sangat mudah
  ) async {
    // Validasi nilai responseQuality
    final quality = max(0, min(5, responseQuality));

    // Default untuk item baru
    double easeFactor = _initialEaseFactor;
    int interval = _initialInterval;

    // Cek apakah ada riwayat review sebelumnya
    final db = await _databaseService.database;
    final reviews = await db.query(
      'review_history',
      where: 'phrase_id = ?',
      whereArgs: [phraseId],
      orderBy: 'review_date DESC',
      limit: 1,
    );

    // Jika ada riwayat, gunakan nilai sebelumnya
    if (reviews.isNotEmpty) {
      easeFactor = reviews.first['ease_factor'] as double;
      interval = reviews.first['interval'] as int;
    }

    // Jika jawaban salah, reset interval
    if (!wasCorrect || quality < 3) {
      interval = 1; // Ulang besok
    } else {
      // Rumus untuk algoritma SM-2:
      // EF' = EF + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
      easeFactor =
          easeFactor + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));

      // Batas minimum untuk EF adalah 1.3
      easeFactor = max(1.3, easeFactor);

      // Hitung interval baru:
      if (interval == 1) {
        interval = 1; // First interval
      } else if (interval == 2) {
        interval = 6; // Second interval
      } else {
        interval = (interval * easeFactor).round(); // Subsequent intervals
      }
    }

    return {
      'phrase_id': phraseId,
      'was_correct': wasCorrect,
      'ease_factor': easeFactor,
      'interval': interval,
      'next_review_date': DateTime.now().add(Duration(days: interval)),
    };
  }

  // Mendapatkan daftar frasa untuk ditinjau hari ini
  Future<List<Phrase>> getPhrasesToReview({
    int? languageId,
    int? categoryId,
    int limit = 10,
  }) async {
    final db = await _databaseService.database;
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);

    // Query untuk mendapatkan frasa yang perlu direview
    String query = '''
      SELECT p.* FROM phrases p
      LEFT JOIN (
        SELECT phrase_id, MAX(review_date) as last_review, 
               interval, ease_factor
        FROM review_history
        GROUP BY phrase_id
      ) r ON p.id = r.phrase_id
      WHERE 
        r.phrase_id IS NULL OR
        date(r.last_review, '+' || r.interval || ' day') <= date('$today')
    ''';

    List<dynamic> args = [];

    // Tambahkan filter bahasa jika ada
    if (languageId != null) {
      query += ' AND p.language_id = ?';
      args.add(languageId);
    }

    // Tambahkan filter kategori jika ada
    if (categoryId != null) {
      query += ' AND p.category_id = ?';
      args.add(categoryId);
    }

    // Tambahkan batasan jumlah dan urutan acak
    query += ' ORDER BY RANDOM() LIMIT ?';
    args.add(limit);

    final List<Map<String, dynamic>> maps = await db.rawQuery(query, args);

    return List.generate(maps.length, (i) {
      return Phrase.fromMap(maps[i]);
    });
  }

  // Memperbarui riwayat review
  Future<void> updateReviewHistory(int phraseId, bool wasCorrect,
      {int responseQuality = 3}) async {
    try {
      final db = await _databaseService.database;

      // Hitung interval berikutnya
      final nextReview = await calculateNextReview(
        phraseId,
        wasCorrect,
        responseQuality,
      );

      // Tambahkan entry baru di review_history
      await db.insert('review_history', {
        'phrase_id': phraseId,
        'review_date': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
        'was_correct': wasCorrect ? 1 : 0,
        'ease_factor': nextReview['ease_factor'],
        'interval': nextReview['interval'],
      });
    } catch (e) {
      print('Error updating review history: $e');
      rethrow;
    }
  }
}
