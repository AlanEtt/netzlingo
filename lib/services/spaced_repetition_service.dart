import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'dart:math';
import '../models/phrase.dart';
import '../models/review_history.dart';
import '../config/appwrite_constants.dart';
import 'appwrite_service.dart';
import 'review_history_service.dart';
import 'phrase_service.dart';

/// Service untuk mengelola algoritma spaced repetition
/// Mengimplementasikan algoritma SuperMemo-2 (SM-2) dengan beberapa modifikasi
class SpacedRepetitionService {
  final AppwriteService _appwriteService;
  final ReviewHistoryService _reviewHistoryService;
  final PhraseService _phraseService;

  SpacedRepetitionService(this._appwriteService)
      : _reviewHistoryService = ReviewHistoryService(_appwriteService),
        _phraseService = PhraseService(_appwriteService);

  /// Mendapatkan frasa yang perlu direview hari ini
  Future<List<Phrase>> getPhrasesToReviewToday(String userId) async {
    try {
      // Dapatkan ID frasa yang perlu direview
      final phraseIds =
          await _reviewHistoryService.getPhrasesToReviewToday(userId);

      if (phraseIds.isEmpty) {
        return [];
      }

      // Dapatkan detail frasa
      List<Phrase> phrases = [];
      for (var id in phraseIds) {
        try {
          final phrase = await _phraseService.getPhrase(id);
          phrases.add(phrase);
        } catch (e) {
          print("Error getting phrase $id: $e");
          // Lanjutkan dengan frasa berikutnya
        }
      }

      return phrases;
    } catch (e) {
      print("Error getting phrases to review: $e");
      return [];
    }
  }

  /// Mendapatkan frasa untuk sesi review dengan prioritas
  Future<List<Phrase>> getPhrasesForReviewSession(
    String userId, {
    int limit = 10,
    String? languageId,
    String? categoryId,
  }) async {
    try {
      // Dapatkan frasa yang harus direview hari ini
      final dueTodayPhrases = await getPhrasesToReviewToday(userId);

      // Filter berdasarkan bahasa dan kategori jika diperlukan
      List<Phrase> filteredPhrases = dueTodayPhrases;
      if (languageId != null) {
        filteredPhrases =
            filteredPhrases.where((p) => p.languageId == languageId).toList();
      }

      if (categoryId != null) {
        filteredPhrases =
            filteredPhrases.where((p) => p.categoryId == categoryId).toList();
      }

      // Jika jumlah frasa kurang dari limit, tambahkan frasa baru
      if (filteredPhrases.length < limit) {
        final additionalCount = limit - filteredPhrases.length;

        // Dapatkan frasa yang belum pernah direview
        final additionalPhrases = await _getUnreviewedPhrases(
          userId,
          languageId: languageId,
          categoryId: categoryId,
          limit: additionalCount,
          excludeIds: filteredPhrases.map((p) => p.id).toList(),
        );

        filteredPhrases.addAll(additionalPhrases);
      }

      // Jika masih kurang, tambahkan frasa yang pernah direview tapi tidak jatuh tempo hari ini
      if (filteredPhrases.length < limit) {
        final additionalCount = limit - filteredPhrases.length;

        final additionalPhrases = await _getReviewedButNotDuePhrases(
          userId,
          languageId: languageId,
          categoryId: categoryId,
          limit: additionalCount,
          excludeIds: filteredPhrases.map((p) => p.id).toList(),
        );

        filteredPhrases.addAll(additionalPhrases);
      }

      // Batasi jumlah frasa
      if (filteredPhrases.length > limit) {
        filteredPhrases = filteredPhrases.sublist(0, limit);
      }

      // Acak urutan frasa
      filteredPhrases.shuffle();

      return filteredPhrases;
    } catch (e) {
      print("Error getting phrases for review session: $e");
      return [];
    }
  }

  /// Mendapatkan frasa yang belum pernah direview
  Future<List<Phrase>> _getUnreviewedPhrases(
    String userId, {
    String? languageId,
    String? categoryId,
    int limit = 10,
    List<String> excludeIds = const [],
  }) async {
    try {
      // Dapatkan semua frasa pengguna
      final allPhrases = await _phraseService.getPhrases(
        userId: userId,
        languageId: languageId,
        categoryId: categoryId,
      );

      // Filter frasa yang belum ada di history review
      List<Phrase> unreviewedPhrases = [];

      for (var phrase in allPhrases) {
        if (excludeIds.contains(phrase.id)) {
          continue;
        }

        final history = await _reviewHistoryService.getReviewHistoryForPhrase(
          phrase.id,
          userId,
        );

        if (history.isEmpty) {
          unreviewedPhrases.add(phrase);
        }

        // Batasi jumlah query untuk performa
        if (unreviewedPhrases.length >= limit) {
          break;
        }
      }

      // Batasi jumlah frasa
      if (unreviewedPhrases.length > limit) {
        unreviewedPhrases = unreviewedPhrases.sublist(0, limit);
      }

      return unreviewedPhrases;
    } catch (e) {
      print("Error getting unreviewed phrases: $e");
      return [];
    }
  }

  /// Mendapatkan frasa yang pernah direview tapi tidak jatuh tempo hari ini
  Future<List<Phrase>> _getReviewedButNotDuePhrases(
    String userId, {
    String? languageId,
    String? categoryId,
    int limit = 10,
    List<String> excludeIds = const [],
  }) async {
    try {
      // Dapatkan semua frasa pengguna
      final allPhrases = await _phraseService.getPhrases(
        userId: userId,
        languageId: languageId,
        categoryId: categoryId,
      );

      // Filter frasa yang sudah direview tapi tidak jatuh tempo hari ini
      List<Phrase> reviewedPhrases = [];

      for (var phrase in allPhrases) {
        if (excludeIds.contains(phrase.id)) {
          continue;
        }

        final latestReview =
            await _reviewHistoryService.getLatestReviewForPhrase(
          phrase.id,
          userId,
        );

        if (latestReview != null) {
          reviewedPhrases.add(phrase);
        }

        // Batasi jumlah query untuk performa
        if (reviewedPhrases.length >= limit) {
          break;
        }
      }

      // Dapatkan ease factor untuk setiap frasa terlebih dahulu
      Map<String, double> phraseEaseFactors = {};
      for (var phrase in reviewedPhrases) {
        final latestReview =
            await _reviewHistoryService.getLatestReviewForPhrase(
          phrase.id,
          userId,
        );
        phraseEaseFactors[phrase.id] = latestReview?.easeFactor ?? 2.5;
      }

      // Urutkan berdasarkan ease factor (prioritaskan yang lebih sulit)
      reviewedPhrases.sort((a, b) {
        final easeFactorA = phraseEaseFactors[a.id] ?? 2.5;
        final easeFactorB = phraseEaseFactors[b.id] ?? 2.5;
        return easeFactorA.compareTo(easeFactorB);
      });

      // Batasi jumlah frasa
      if (reviewedPhrases.length > limit) {
        reviewedPhrases = reviewedPhrases.sublist(0, limit);
      }

      return reviewedPhrases;
    } catch (e) {
      print("Error getting reviewed but not due phrases: $e");
      return [];
    }
  }

  /// Memproses jawaban dan menghitung interval berikutnya
  Future<Map<String, dynamic>> processAnswer(
    String phraseId,
    String userId,
    int quality,
  ) async {
    try {
      // Dapatkan riwayat review terbaru
      final latestReview = await _reviewHistoryService.getLatestReviewForPhrase(
        phraseId,
        userId,
      );

      // Nilai default jika belum ada review sebelumnya
      double easeFactor = 2.5;
      int interval = 1;
      int repetitions = 0;

      // Jika sudah ada review sebelumnya, gunakan nilai tersebut
      if (latestReview != null) {
        easeFactor = latestReview.easeFactor;
        interval = latestReview.interval;
        // Repetitions tidak disimpan di model, jadi kita hitung dari history
        final history = await _reviewHistoryService.getReviewHistoryForPhrase(
          phraseId,
          userId,
        );
        repetitions = history.length;
      }

      // Konversi wasCorrect menjadi quality (0-5)
      // 0: complete blackout, 5: perfect recall
      bool wasCorrect = quality >= 3; // 3 atau lebih dianggap benar

      // Hitung nilai baru berdasarkan algoritma SM-2
      if (quality < 3) {
        // Jawaban salah, reset interval dan repetitions
        repetitions = 0;
        interval = 1;
      } else {
        // Jawaban benar
        repetitions++;

        if (repetitions == 1) {
          interval = 1;
        } else if (repetitions == 2) {
          interval = 6;
        } else {
          interval = (interval * easeFactor).round();
        }
      }

      // Hitung ease factor baru
      easeFactor = max(1.3,
          easeFactor + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02)));

      // Hitung tanggal review berikutnya
      final nextReviewDate = DateTime.now().add(Duration(days: interval));

      // Simpan review history baru
      final reviewHistory = ReviewHistory(
        id: '',
        phraseId: phraseId,
        userId: userId,
        reviewDate: DateTime.now(),
        wasCorrect: wasCorrect,
        easeFactor: easeFactor,
        interval: interval,
      );

      await _reviewHistoryService.addReviewHistory(reviewHistory);

      return {
        'ease_factor': easeFactor,
        'interval': interval,
        'next_review_date': nextReviewDate,
        'repetitions': repetitions,
        'was_correct': wasCorrect,
      };
    } catch (e) {
      print("Error processing answer: $e");
      // Return default values if there's an error
      return {
        'ease_factor': 2.5,
        'interval': 1,
        'next_review_date': DateTime.now().add(Duration(days: 1)),
        'repetitions': 0,
        'was_correct': false,
      };
    }
  }

  /// Mendapatkan statistik review untuk frasa tertentu
  Future<Map<String, dynamic>> getPhraseReviewStats(
    String phraseId,
    String userId,
  ) async {
    try {
      final history = await _reviewHistoryService.getReviewHistoryForPhrase(
        phraseId,
        userId,
      );

      if (history.isEmpty) {
        return {
          'total_reviews': 0,
          'correct_reviews': 0,
          'accuracy': 0.0,
          'last_review_date': null,
          'next_review_date': null,
          'current_interval': 0,
          'ease_factor': 2.5,
        };
      }

      // Hitung statistik
      int totalReviews = history.length;
      int correctReviews = history.where((r) => r.wasCorrect).length;
      double accuracy =
          totalReviews > 0 ? correctReviews / totalReviews * 100 : 0.0;

      // Dapatkan review terakhir
      final latestReview = history.first; // Sudah diurutkan descending

      // Hitung tanggal review berikutnya
      final nextReviewDate = latestReview.reviewDate.add(
        Duration(days: latestReview.interval),
      );

      return {
        'total_reviews': totalReviews,
        'correct_reviews': correctReviews,
        'accuracy': accuracy,
        'last_review_date': latestReview.reviewDate,
        'next_review_date': nextReviewDate,
        'current_interval': latestReview.interval,
        'ease_factor': latestReview.easeFactor,
      };
    } catch (e) {
      print("Error getting phrase review stats: $e");
      return {
        'total_reviews': 0,
        'correct_reviews': 0,
        'accuracy': 0.0,
        'last_review_date': null,
        'next_review_date': null,
        'current_interval': 0,
        'ease_factor': 2.5,
      };
    }
  }

  /// Mendapatkan statistik review keseluruhan untuk pengguna
  Future<Map<String, dynamic>> getUserReviewStats(String userId) async {
    try {
      // Dapatkan semua frasa pengguna
      final phrases = await _phraseService.getPhrases(userId: userId);

      int totalReviews = 0;
      int correctReviews = 0;
      int phrasesReviewed = 0;
      int phrasesLearned = 0; // Frasa dengan interval > 30 hari

      for (var phrase in phrases) {
        final stats = await getPhraseReviewStats(phrase.id, userId);

        totalReviews += stats['total_reviews'] as int;
        correctReviews += stats['correct_reviews'] as int;

        if (stats['total_reviews'] > 0) {
          phrasesReviewed++;
        }

        if (stats['current_interval'] > 30) {
          phrasesLearned++;
        }
      }

      double accuracy =
          totalReviews > 0 ? correctReviews / totalReviews * 100 : 0.0;

      return {
        'total_reviews': totalReviews,
        'correct_reviews': correctReviews,
        'accuracy': accuracy,
        'phrases_reviewed': phrasesReviewed,
        'phrases_learned': phrasesLearned,
        'total_phrases': phrases.length,
        'progress_percentage':
            phrases.isEmpty ? 0.0 : (phrasesLearned / phrases.length * 100),
      };
    } catch (e) {
      print("Error getting user review stats: $e");
      return {
        'total_reviews': 0,
        'correct_reviews': 0,
        'accuracy': 0.0,
        'phrases_reviewed': 0,
        'phrases_learned': 0,
        'total_phrases': 0,
        'progress_percentage': 0.0,
      };
    }
  }
}
