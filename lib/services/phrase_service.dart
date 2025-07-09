import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import '../models/phrase.dart';
import '../config/appwrite_constants.dart';
import 'appwrite_service.dart';

class PhraseService {
  final AppwriteService _appwriteService;
  late Databases _databases;

  PhraseService(this._appwriteService) {
    _databases = _appwriteService.databases;
  }

  // Mendapatkan frasa berdasarkan ID
  Future<Phrase> getPhrase(String id) async {
    try {
      final document = await _databases.getDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.phrasesCollection,
        documentId: id,
      );

      return Phrase.fromDocument(document);
    } catch (e) {
      print("Error getting phrase: $e");

      // Buat default phrase jika error
      return Phrase(
        id: id,
        userId: 'unknown',
        languageId: 'unknown',
        categoryId: 'unknown',
        originalText: 'Error loading phrase',
        translatedText: 'Please try again later',
        isFavorite: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  // Membuat frasa publik universal di database (bisa dipanggil saat aplikasi pertama kali dijalankan)
  Future<void> createUniversalPublicPhrases() async {
    try {
      print("Creating universal public phrases in database");

      // Periksa apakah frasa publik sudah ada
      final existingPhrases = await _databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.phrasesCollection,
        queries: [
          Query.equal('user_id', 'universal'),
        ],
      );

      if (existingPhrases.documents.isNotEmpty) {
        print("Universal phrases already exist, skipping creation");
        return;
      }

      // Buat frasa publik dari frasa statis default
      final defaultPhrases = Phrase.getDefaultPublicPhrases();

      for (var phrase in defaultPhrases) {
        // Ubah userId menjadi 'universal' dan set isPublic ke true
        final universalPhrase = phrase.copyWith(
          userId: 'universal',
          isPublic: true,
        );

        await _databases.createDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.phrasesCollection,
          documentId: ID.unique(),
          data: universalPhrase.toMap(),
          // Izin yang sangat permisif - semua bisa membaca
          permissions: [
            Permission.read(Role.any()),
            Permission.read(Role.users()),
            Permission.read(Role.guests()),
          ],
        );
      }

      print("Universal public phrases created successfully");
    } catch (e) {
      print("Error creating universal public phrases: $e");
    }
  }

  // PERBAIKAN: Membuat frasa default untuk user baru yang DAPAT diedit dan dihapus
  Future<void> createUserDefaultPhrases(String userId) async {
    try {
      print("Creating default phrases for new user: $userId");

      // Periksa apakah user sudah memiliki frasa
      final existingUserPhrases = await _databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.phrasesCollection,
        queries: [
          Query.equal('user_id', userId),
          Query.limit(1),
        ],
      );

      // Jika user sudah memiliki frasa, skip pembuatan
      if (existingUserPhrases.documents.isNotEmpty) {
        print("User already has phrases, skipping default phrase creation");
        return;
      }

      // Buat frasa default untuk user baru dari template
      final defaultPhrases = Phrase.getDefaultPublicPhrases();

      // Buat frasa default untuk user baru (dengan user_id mereka, bukan 'system')
      for (var phrase in defaultPhrases) {
        try {
          // Salin frasa dengan mengubah userId ke userId pengguna dan isPublic ke false
          final userPhrase = phrase.copyWith(
            id: '', // Biarkan ID kosong, Appwrite akan generate ID unik
            userId: userId, // Gunakan ID user baru
            isPublic: false, // Tidak public
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          final uniqueDocId = ID.unique();
          print("Creating phrase with ID: $uniqueDocId");

          await _databases.createDocument(
            databaseId: AppwriteConstants.databaseId,
            collectionId: AppwriteConstants.phrasesCollection,
            documentId: uniqueDocId,
            data: userPhrase.toMap(),
            // Permissions khusus untuk user agar bisa mengedit dan menghapus
            permissions: [
              Permission.read(Role.user(userId)),
              Permission.update(Role.user(userId)),
              Permission.delete(Role.user(userId)),
            ],
          );
        } catch (phraseError) {
          // Log error but continue with other phrases
          print("Error creating individual phrase: $phraseError");
          continue;
        }
      }

      print("Default phrases created successfully for user: $userId");
    } catch (e) {
      print("Error creating default phrases for user: $e");
      // Don't rethrow - this shouldn't prevent user login
    }
  }

  // Mendapatkan frasa untuk pengguna yang tidak terautentikasi atau tidak memiliki izin
  Future<List<Phrase>> getPublicPhrases({
    String? languageId,
    String? categoryId,
    int limit = 20,
  }) async {
    try {
      print("Getting public phrases for all users");
      List<String> queries = [];

      // Pendekatan lebih permisif - coba cari frasa milik user universal dulu
      queries.add(Query.equal('user_id', 'universal'));

      // Filter tambahan jika diperlukan
      if (languageId != null) {
        queries.add(Query.equal('language_id', languageId));
      }

      if (categoryId != null) {
        queries.add(Query.equal('category_id', categoryId));
      }

      // Batasi jumlah frasa
      queries.add(Query.limit(limit));

      final documentList = await _databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.phrasesCollection,
        queries: queries,
      );

      List<Phrase> phrases = documentList.documents
          .map((doc) => Phrase.fromDocument(doc))
          .toList();

      // Jika tidak menemukan frasa universal, coba cari frasa publik
      if (phrases.isEmpty) {
        print("No universal phrases found, trying public phrases");
        queries = [Query.equal('is_public', true)];

        if (languageId != null) {
          queries.add(Query.equal('language_id', languageId));
        }

        if (categoryId != null) {
          queries.add(Query.equal('category_id', categoryId));
        }

        queries.add(Query.limit(limit));

        final publicDocuments = await _databases.listDocuments(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.phrasesCollection,
          queries: queries,
        );

        phrases = publicDocuments.documents
            .map((doc) => Phrase.fromDocument(doc))
            .toList();
      }

      // Jika masih tidak menemukan frasa, gunakan frasa statis
      if (phrases.isEmpty) {
        print("No public phrases found in database, using static fallback");
        return getDefaultStaticPhrases();
      }

      return phrases;
    } catch (e) {
      print("Error getting public phrases: $e");
      // Jika gagal, kembalikan frasa default statis
      return getDefaultStaticPhrases();
    }
  }

  // Frasa default statis sebagai fallback terakhir
  List<Phrase> getDefaultStaticPhrases() {
    print("Returning static default phrases as fallback");
    return Phrase.getDefaultPublicPhrases();
  }

  // Mendapatkan daftar semua frasa pengguna
  Future<List<Phrase>> getPhrases({
    String? userId,
    String? languageId,
    String? categoryId,
    bool? isFavorite,
  }) async {
    try {
      List<String> queries = [];

      if (userId != null) {
        queries.add(Query.equal('user_id', userId));
      }

      if (languageId != null) {
        queries.add(Query.equal('language_id', languageId));
      }

      if (categoryId != null) {
        queries.add(Query.equal('category_id', categoryId));
      }

      if (isFavorite != null) {
        queries.add(Query.equal('is_favorite', isFavorite));
      }

      // Urutkan berdasarkan created_at terbaru
      queries.add(Query.orderDesc('created_at'));

      final documentList = await _databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.phrasesCollection,
        queries: queries,
      );

      List<Phrase> phrases = documentList.documents
          .map((doc) => Phrase.fromDocument(doc))
          .toList();

      return phrases;
    } catch (e) {
      print("Error getting phrases: $e");

      // Jika gagal dan error adalah unauthorized, coba dapatkan frasa publik
      if (e.toString().contains('user_unauthorized') ||
          e.toString().contains('401')) {
        print("Unauthorized access, getting public phrases instead");
        return await getPublicPhrases(
          languageId: languageId,
          categoryId: categoryId,
        );
      }

      // Jika error lain, kembalikan frasa default statis
      print("Error fetching phrases, returning default static phrases");
      return getDefaultStaticPhrases();
    }
  }

  // Mencari frasa berdasarkan teks
  Future<List<Phrase>> searchPhrases(String text, String? userId) async {
    try {
      // Jika tidak ada userId, cari di frasa universal
      if (userId == null || userId.isEmpty) {
        print("Searching in universal phrases");
        final universalDocs = await _databases.listDocuments(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.phrasesCollection,
          queries: [
            Query.search('original_text', text),
            Query.equal('user_id', 'universal'),
          ],
        );

        return universalDocs.documents
            .map((doc) => Phrase.fromDocument(doc))
            .toList();
      }

      // Cari di frasa milik user ini
      print("Searching phrases for user $userId with text: '$text'");
      List<String> queries = [
        Query.search('original_text', text),
        Query.equal('user_id', userId),
      ];

      final documentList = await _databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.phrasesCollection,
        queries: queries,
      );

      print("Found ${documentList.documents.length} phrases matching '$text'");

      return documentList.documents
          .map((doc) => Phrase.fromDocument(doc))
          .toList();
    } catch (e) {
      print("Error searching phrases: $e");
      // Return empty list instead of throwing
      return [];
    }
  }

  // PERBAIKAN: Menambah frasa baru dengan penanganan error yang lebih baik
  Future<Phrase> addPhrase(Phrase phrase) async {
    try {
      print("Adding new phrase: ${phrase.originalText}");

      // Buat ID baru untuk frasa
      final documentId = ID.unique();

      // Buat data untuk frasa (pastikan semua field required terisi)
      final data = phrase.toMap();
      data['user_id'] = phrase.userId; // Pastikan user_id tidak null

      // Debug info
      print("Sending to AppWrite: ${data.toString()}");

      // Coba buat dokumen dengan permissions yang jelas
      final document = await _databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.phrasesCollection,
        documentId: documentId,
        data: data,
        // Tambahkan izin eksplisit
        permissions: [
          Permission.read(Role.user(phrase.userId)),
          Permission.update(Role.user(phrase.userId)),
          Permission.delete(Role.user(phrase.userId)),
        ],
      );

      print("Phrase successfully added with ID: ${document.$id}");
      return Phrase.fromDocument(document);
    } catch (e) {
      print("Error adding phrase: $e");

      // Jika error, coba lagi dengan menghilangkan permissions
      try {
        print("Retrying phrase addition without permissions...");

        final documentId = ID.unique();

        final document = await _databases.createDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.phrasesCollection,
          documentId: documentId,
          data: phrase.toMap(),
          // Tanpa permissions kustom
        );

        print(
            "Phrase added successfully on second attempt with ID: ${document.$id}");
        return Phrase.fromDocument(document);
      } catch (secondError) {
        print("Second attempt failed: $secondError");

        // Jika masih gagal, coba satu kali lagi dengan pendekatan minimum
        try {
          print("Final attempt with simplified approach...");

          // Minimalisasi data, hanya gunakan yang required
          final Map<String, dynamic> minimalData = {
            'original_text': phrase.originalText,
            'translated_text': phrase.translatedText,
            'language_id': phrase.languageId,
            'user_id': phrase.userId,
            'notes': phrase.notes,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
            'is_favorite': false,
          };

          final document = await _databases.createDocument(
            databaseId: AppwriteConstants.databaseId,
            collectionId: AppwriteConstants.phrasesCollection,
            documentId: ID.unique(),
            data: minimalData,
          );

          print(
              "Phrase added successfully with minimal approach: ${document.$id}");
          return Phrase.fromDocument(document);
        } catch (finalError) {
          print("All attempts failed: $finalError");
          throw Exception(
              "Gagal menambahkan frasa setelah beberapa percobaan: $finalError");
        }
      }
    }
  }

  // PERBAIKAN: Memperbarui frasa dengan penanganan error yang lebih baik
  Future<Phrase> updatePhrase(Phrase phrase) async {
    try {
      print("Updating phrase with ID: ${phrase.id}");

      // Update dokumen tanpa permissions kustom
      final document = await _databases.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.phrasesCollection,
        documentId: phrase.id,
        data: phrase.toMap(),
      );

      print("Phrase successfully updated");
      return Phrase.fromDocument(document);
    } catch (e) {
      print("Error updating phrase: $e");

      // Jika error, coba dengan pendekatan lain
      try {
        print("Retrying with alternative approach...");

        // Jika gagal update, coba dapatkan dokumen asli dulu
        final original = await _databases.getDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.phrasesCollection,
          documentId: phrase.id,
        );

        // Kemudian gunakan permissions dari dokumen asli
        final document = await _databases.updateDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.phrasesCollection,
          documentId: phrase.id,
          data: phrase.toMap(),
          // Konversi List<dynamic> ke List<String> atau null jika tidak ada permissions
          permissions: original.$permissions != null
              ? original.$permissions.cast<String>()
              : null,
        );

        print("Phrase successfully updated with original permissions");
        return Phrase.fromDocument(document);
      } catch (secondError) {
        print("Second attempt failed: $secondError");

        // Jika masih gagal, coba update dengan pendekatan minimal
        try {
          print("Final attempt with minimal data approach...");

          // Hanya update field penting
          final Map<String, dynamic> minimalData = {
            'original_text': phrase.originalText,
            'translated_text': phrase.translatedText,
            'notes': phrase.notes,
            'updated_at': DateTime.now().toIso8601String(),
          };

          final document = await _databases.updateDocument(
            databaseId: AppwriteConstants.databaseId,
            collectionId: AppwriteConstants.phrasesCollection,
            documentId: phrase.id,
            data: minimalData,
          );

          print("Phrase updated successfully with minimal approach");
          return Phrase.fromDocument(document);
        } catch (finalError) {
          print("All update attempts failed: $finalError");
          throw Exception("Gagal memperbarui frasa: $finalError");
        }
      }
    }
  }

  // Menghapus frasa dengan penanganan error yang lebih baik
  Future<bool> deletePhrase(String id) async {
    try {
      print("Deleting phrase with ID: $id");
      await _databases.deleteDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.phrasesCollection,
        documentId: id,
      );
      print("Phrase successfully deleted");
      return true;
    } catch (e) {
      print("Error deleting phrase: $e");

      // Jika gagal karena permission, coba update status isDeleted tanpa menghapus
      try {
        print("Trying soft delete instead...");
        await _databases.updateDocument(
            databaseId: AppwriteConstants.databaseId,
            collectionId: AppwriteConstants.phrasesCollection,
            documentId: id,
            data: {
              'is_deleted': true,
              'updated_at': DateTime.now().toIso8601String(),
            });
        print("Phrase soft deleted successfully");
        return true;
      } catch (secondError) {
        print("Soft delete failed: $secondError");
        return false;
      }
    }
  }

  // Toggle favorite
  Future<Phrase> toggleFavorite(Phrase phrase) async {
    try {
      final updatedPhrase = phrase.copyWith(isFavorite: !phrase.isFavorite);
      return await updatePhrase(updatedPhrase);
    } catch (e) {
      print("Error toggling favorite: $e");
      rethrow;
    }
  }
}
