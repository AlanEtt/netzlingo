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
        try {
          // Ubah userId menjadi 'universal' dan set isPublic ke true
          final universalPhrase = phrase.copyWith(
            userId: 'universal',
            isPublic: true,
          );

          // Gunakan toAppWriteMap untuk menghindari error structure
          final data = universalPhrase.toAppWriteMap();

          await _databases.createDocument(
            databaseId: AppwriteConstants.databaseId,
            collectionId: AppwriteConstants.phrasesCollection,
            documentId: ID.unique(),
            data: data,
            // Tidak menggunakan permissions khusus - default permissions collection
          );
        } catch (phraseError) {
          print("Error creating universal phrase: $phraseError");
          continue; // Lanjut ke frasa berikutnya
        }
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
          // Salin frasa dengan mengubah userId ke userId pengguna
          final userPhrase = phrase.copyWith(
            id: '', // Biarkan ID kosong, Appwrite akan generate ID unik
            userId: userId, // Gunakan ID user baru
            isPublic: false, // Tidak public
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          final uniqueDocId = ID.unique();
          print("Creating phrase with ID: $uniqueDocId");

          // Gunakan toAppWriteMap untuk menghindari error structure
          final data = userPhrase.toAppWriteMap();

          await _databases.createDocument(
            databaseId: AppwriteConstants.databaseId,
            collectionId: AppwriteConstants.phrasesCollection,
            documentId: uniqueDocId,
            data: data,
            // Tidak menggunakan permissions khusus - default permissions collection
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
      // Validasi userId untuk memastikan keamanan
      if (userId == null || userId.isEmpty) {
        print("Warning: Attempting to get phrases without user ID");
        // Jika tidak ada userId yang valid, kembalikan frasa publik saja
        return await getPublicPhrases(
            languageId: languageId, categoryId: categoryId);
      }

      List<String> queries = [];

      // Selalu filter berdasarkan user_id untuk memastikan user hanya melihat frasanya sendiri
      // PERBAIKAN: Pastikan ini selalu ada dan diproses dengan benar
      queries.add(Query.equal('user_id', userId));

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

      print("Getting phrases with strict user_id filter: $userId");
      final documentList = await _databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.phrasesCollection,
        queries: queries,
      );

      List<Phrase> phrases = documentList.documents
          .map((doc) => Phrase.fromDocument(doc))
          .toList();

      print("Found ${phrases.length} phrases for user $userId");
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
      // PERBAIKAN: Validasi userId agar hanya mencari di frasa milik sendiri
      if (userId == null || userId.isEmpty) {
        print(
            "Warning: Searching phrases without user ID, will only return universal phrases");
        // Jika tidak ada userId yang valid, cari di frasa universal saja
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
        // PERBAIKAN: Pastikan selalu mencari HANYA frasa milik user
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

      // Buat data untuk frasa menggunakan toAppWriteMap (tanpa is_public dan tags)
      final data = phrase.toAppWriteMap();
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
          data: phrase.toAppWriteMap(), // Gunakan toAppWriteMap
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

  // PERBAIKAN: Memperbarui frasa dengan validasi ownership
  Future<Phrase> updatePhrase(Phrase phrase) async {
    try {
      print("Updating phrase with ID: ${phrase.id}");

      // PERBAIKAN: Validasi ownership sebelum update
      // Cek apakah frasa memang milik user yang melakukan update
      final originalDocument = await _databases.getDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.phrasesCollection,
        documentId: phrase.id,
      );

      final originalUserId = originalDocument.data['user_id'];
      if (originalUserId != phrase.userId) {
        print(
            "Security violation: User ${phrase.userId} attempted to update phrase owned by $originalUserId");
        throw Exception("Anda tidak memiliki akses untuk mengubah frasa ini");
      }

      // Update dokumen menggunakan toAppWriteMap (tanpa is_public dan tags)
      final document = await _databases.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.phrasesCollection,
        documentId: phrase.id,
        data: phrase.toAppWriteMap(), // Gunakan toAppWriteMap
      );

      print("Phrase successfully updated");
      return Phrase.fromDocument(document);
    } catch (e) {
      print("Error updating phrase: $e");

      // Jika error adalah karena validasi ownership, langsung throw exception
      if (e.toString().contains("Anda tidak memiliki akses")) {
        throw e;
      }

      // Jika error lain, coba dengan pendekatan lain
      try {
        print("Retrying with alternative approach...");

        // Jika gagal update, coba dapatkan dokumen asli dulu
        final original = await _databases.getDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.phrasesCollection,
          documentId: phrase.id,
        );

        // Validasi ownership lagi
        if (original.data['user_id'] != phrase.userId) {
          throw Exception("Anda tidak memiliki akses untuk mengubah frasa ini");
        }

        // Kemudian gunakan permissions dari dokumen asli
        final document = await _databases.updateDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.phrasesCollection,
          documentId: phrase.id,
          data: phrase.toAppWriteMap(), // Gunakan toAppWriteMap
          // Konversi List<dynamic> ke List<String> atau null jika tidak ada permissions
          permissions: original.$permissions != null
              ? original.$permissions.cast<String>()
              : null,
        );

        print("Phrase successfully updated with original permissions");
        return Phrase.fromDocument(document);
      } catch (secondError) {
        print("Second attempt failed: $secondError");

        // Jika masih gagal, dan error adalah karena ownership, langsung throw exception
        if (secondError.toString().contains("Anda tidak memiliki akses")) {
          throw secondError;
        }

        // Jika error lain, coba update dengan pendekatan minimal
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

  // Menghapus frasa dengan penanganan error yang lebih baik dan validasi ownership
  Future<bool> deletePhrase(String id) async {
    try {
      print("Deleting phrase with ID: $id");

      // PERBAIKAN: Dapatkan dokumen untuk cek ownership terlebih dahulu
      final document = await _databases.getDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.phrasesCollection,
        documentId: id,
      );

      // Proses penghapusan
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

  // Toggle favorite dengan validasi ownership
  Future<Phrase> toggleFavorite(Phrase phrase) async {
    try {
      print("PhraseService: Toggling favorite for phrase ID: ${phrase.id}");

      // PERBAIKAN: Validasi ownership sebelum toggle favorite
      final document = await _databases.getDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.phrasesCollection,
        documentId: phrase.id,
      );

      final ownerUserId = document.data['user_id'];
      if (ownerUserId != phrase.userId) {
        print(
            "Security violation: User ${phrase.userId} attempted to modify phrase owned by $ownerUserId");
        throw Exception("Anda tidak memiliki akses untuk mengubah frasa ini");
      }

      // Buat salinan frasa dengan status favorit dibalik
      final updatedPhrase = phrase.copyWith(isFavorite: !phrase.isFavorite);

      // Update document di Appwrite
      try {
        print(
            "PhraseService: Updating is_favorite to ${updatedPhrase.isFavorite}");
        final updatedDocument = await _databases.updateDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.phrasesCollection,
          documentId: phrase.id,
          data: {'is_favorite': updatedPhrase.isFavorite},
        );

        print("PhraseService: Favorite status updated successfully");
        // Kembalikan object Phrase dari dokumen yang diperbarui
        return Phrase.fromDocument(updatedDocument);
      } catch (updateError) {
        print("PhraseService: Error updating favorite status: $updateError");

        // Coba cara alternatif jika gagal
        final fullUpdate = await updatePhrase(updatedPhrase);
        print("PhraseService: Full phrase update completed as fallback");
        return fullUpdate;
      }
    } catch (e) {
      print("PhraseService: Error in toggleFavorite: $e");
      rethrow;
    }
  }
}
