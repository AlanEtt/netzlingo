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
            // Admin bisa mengubah
            Permission.update(Role.team("admin", "owner")),
            Permission.delete(Role.team("admin", "owner")),
          ],
        );
      }
      
      print("Universal public phrases created successfully");
    } catch (e) {
      print("Error creating universal public phrases: $e");
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

      final documentList = await _databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.phrasesCollection,
        queries: queries,
      );

      return documentList.documents
          .map((doc) => Phrase.fromDocument(doc))
          .toList();
    } catch (e) {
      print("Error getting phrases: $e");
      
      // Jika gagal dan error adalah unauthorized, coba dapatkan frasa publik
      if (e.toString().contains('user_unauthorized') || e.toString().contains('401')) {
        print("Unauthorized access, getting public phrases instead");
        return await getPublicPhrases(
          languageId: languageId,
          categoryId: categoryId,
        );
      }
      
      // Return empty list instead of throwing
      return [];
    }
  }

  // Mencari frasa berdasarkan teks
  Future<List<Phrase>> searchPhrases(String text, String? userId) async {
    try {
      List<String> queries = [Query.search('original_text', text)];

      if (userId != null) {
        queries.add(Query.equal('user_id', userId));
      }

      final documentList = await _databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.phrasesCollection,
        queries: queries,
      );

      return documentList.documents
          .map((doc) => Phrase.fromDocument(doc))
          .toList();
    } catch (e) {
      print("Error searching phrases: $e");
      // Return empty list instead of throwing
      return [];
    }
  }

  // Menambah frasa baru
  Future<Phrase> addPhrase(Phrase phrase) async {
    try {
      final document = await _databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.phrasesCollection,
        documentId: ID.unique(),
        data: phrase.toMap(),
        // Tambahkan izin untuk pengguna ini dan any untuk read
        permissions: [
          Permission.read(Role.any()),
          Permission.read(Role.user(phrase.userId)),
          Permission.update(Role.user(phrase.userId)),
          Permission.delete(Role.user(phrase.userId)),
        ],
      );

      return Phrase.fromDocument(document);
    } catch (e) {
      print("Error adding phrase: $e");
      
      // Jika gagal, coba lagi tanpa permissions
      try {
        final document = await _databases.createDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.phrasesCollection,
          documentId: ID.unique(),
          data: phrase.toMap(),
          // Tanpa custom permissions
        );
        return Phrase.fromDocument(document);
      } catch (innerError) {
        print("Error adding phrase without permissions: $innerError");
        throw innerError;
      }
    }
  }

  // Memperbarui frasa
  Future<Phrase> updatePhrase(Phrase phrase) async {
    try {
      final document = await _databases.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.phrasesCollection,
        documentId: phrase.id,
        data: phrase.toMap(),
        // Tambahkan izin untuk pengguna ini dan any untuk read
        permissions: [
          Permission.read(Role.any()),
          Permission.read(Role.user(phrase.userId)),
          Permission.update(Role.user(phrase.userId)),
          Permission.delete(Role.user(phrase.userId)),
        ],
      );

      return Phrase.fromDocument(document);
    } catch (e) {
      print("Error updating phrase: $e");
      
      // Jika gagal, coba lagi tanpa permissions
      try {
        final document = await _databases.updateDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.phrasesCollection,
          documentId: phrase.id,
          data: phrase.toMap(),
          // Tanpa custom permissions
        );
        return Phrase.fromDocument(document);
      } catch (innerError) {
        print("Error updating phrase without permissions: $innerError");
        // Jika masih gagal, kembalikan objek phrase yang diteruskan
        return phrase;
      }
    }
  }

  // Menghapus frasa
  Future<void> deletePhrase(String id) async {
    try {
      await _databases.deleteDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.phrasesCollection,
        documentId: id,
      );
    } catch (e) {
      print("Error deleting phrase: $e");
      rethrow;
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
