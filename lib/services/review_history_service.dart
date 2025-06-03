import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import '../models/review_history.dart';
import '../config/appwrite_constants.dart';
import 'appwrite_service.dart';

class ReviewHistoryService {
  final AppwriteService _appwriteService;
  late Databases _databases;

  ReviewHistoryService(this._appwriteService) {
    _databases = _appwriteService.databases;
  }

  // Mendapatkan riwayat review untuk frasa tertentu
  Future<List<ReviewHistory>> getReviewHistoryForPhrase(
      String phraseId, String userId) async {
    try {
      final documentList = await _databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.reviewHistoryCollection,
        queries: [
          Query.equal('phrase_id', phraseId),
          Query.equal('user_id', userId),
          Query.orderDesc('review_date'),
        ],
      );

      return documentList.documents
          .map((doc) => ReviewHistory.fromDocument(doc))
          .toList();
    } catch (e) {
      print("Error getting review history: $e");
      return []; // Return empty list instead of throwing
    }
  }

  // Mendapatkan riwayat review terbaru untuk frasa tertentu
  Future<ReviewHistory?> getLatestReviewForPhrase(
      String phraseId, String userId) async {
    try {
      final documentList = await _databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.reviewHistoryCollection,
        queries: [
          Query.equal('phrase_id', phraseId),
          Query.equal('user_id', userId),
          Query.orderDesc('review_date'),
          Query.limit(1),
        ],
      );

      if (documentList.documents.isEmpty) {
        return null;
      }

      return ReviewHistory.fromDocument(documentList.documents.first);
    } catch (e) {
      print("Error getting latest review: $e");
      return null; // Return null instead of throwing
    }
  }

  // Mendapatkan frasa yang perlu direview hari ini
  Future<List<String>> getPhrasesToReviewToday(String userId) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final documentList = await _databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.reviewHistoryCollection,
        queries: [
          Query.equal('user_id', userId),
          Query.lessThanEqual('review_date', today.toIso8601String()),
          Query.orderAsc('review_date'),
        ],
      );

      // Ambil ID frasa yang perlu direview
      final phraseIds = <String>{};
      for (var doc in documentList.documents) {
        final reviewHistory = ReviewHistory.fromDocument(doc);
        phraseIds.add(reviewHistory.phraseId);
      }

      return phraseIds.toList();
    } catch (e) {
      print("Error getting phrases to review: $e");
      return []; // Return empty list instead of throwing
    }
  }

  // Menambahkan riwayat review baru
  Future<ReviewHistory> addReviewHistory(ReviewHistory reviewHistory) async {
    try {
      print("Adding review history for phrase: ${reviewHistory.phraseId}, user: ${reviewHistory.userId}");
      final document = await _databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.reviewHistoryCollection,
        documentId: ID.unique(),
        data: reviewHistory.toMap(),
        // Tambahkan izin untuk pengguna ini dan any untuk read
        permissions: [
          Permission.read(Role.any()),
          Permission.read(Role.user(reviewHistory.userId)),
          Permission.update(Role.user(reviewHistory.userId)),
          Permission.delete(Role.user(reviewHistory.userId)),
        ],
      );

      print("Review history added successfully: ${document.$id}");
      return ReviewHistory.fromDocument(document);
    } catch (e) {
      print("Error adding review history: $e");
      
      // Coba lagi tanpa permissions
      try {
        print("Trying to add review history without custom permissions");
        final document = await _databases.createDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.reviewHistoryCollection,
          documentId: ID.unique(),
          data: reviewHistory.toMap(),
          // Tanpa custom permissions
        );
        
        print("Review history added without custom permissions: ${document.$id}");
        return ReviewHistory.fromDocument(document);
      } catch (innerError) {
        print("Error adding review history without permissions: $innerError");
        // Jika masih gagal, return object lokal dengan ID yang dimulai dengan 'local_'
        return ReviewHistory(
          id: 'local_${DateTime.now().millisecondsSinceEpoch}',
          phraseId: reviewHistory.phraseId,
          userId: reviewHistory.userId,
          reviewDate: reviewHistory.reviewDate,
          wasCorrect: reviewHistory.wasCorrect,
          easeFactor: reviewHistory.easeFactor,
          interval: reviewHistory.interval,
        );
      }
    }
  }

  // Menghitung interval berikutnya berdasarkan algoritma spaced repetition
  Future<Map<String, dynamic>> calculateNextReview(
      String phraseId, String userId, bool wasCorrect) async {
    try {
      // Dapatkan riwayat review terbaru
      final latestReview = await getLatestReviewForPhrase(phraseId, userId);

      // Nilai default jika belum ada review sebelumnya
      double easeFactor = 2.5;
      int interval = 1;

      // Jika sudah ada review sebelumnya, gunakan nilai tersebut
      if (latestReview != null) {
        easeFactor = latestReview.easeFactor;
        interval = latestReview.interval;
      }

      // Hitung nilai baru berdasarkan algoritma SM-2
      if (wasCorrect) {
        // Jika jawaban benar, tingkatkan interval dan pertahankan/tingkatkan ease factor
        if (interval == 1) {
          interval = 6; // 6 hari untuk interval kedua
        } else {
          interval = (interval * easeFactor).round();
        }
        easeFactor = easeFactor + 0.1;
      } else {
        // Jika jawaban salah, reset interval dan kurangi ease factor
        interval = 1;
        easeFactor = easeFactor - 0.3;
      }

      // Batasi ease factor minimal 1.3
      easeFactor = easeFactor < 1.3 ? 1.3 : easeFactor;

      // Hitung tanggal review berikutnya
      final nextReviewDate = DateTime.now().add(Duration(days: interval));

      return {
        'ease_factor': easeFactor,
        'interval': interval,
        'next_review_date': nextReviewDate,
      };
    } catch (e) {
      print("Error calculating next review: $e");
      // Return default values if there's an error
      return {
        'ease_factor': 2.5,
        'interval': 1,
        'next_review_date': DateTime.now().add(Duration(days: 1)),
      };
    }
  }
}
