import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import '../models/tag.dart';
import '../models/phrase_tag.dart';
import '../config/appwrite_constants.dart';
import 'appwrite_service.dart';

class TagService {
  final AppwriteService _appwriteService;
  late Databases _databases;

  TagService(this._appwriteService) {
    _databases = _appwriteService.databases;
  }

  // Mendapatkan semua tag pengguna
  Future<List<Tag>> getTags(String userId) async {
    try {
      final documentList = await _databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.tagsCollection,
        queries: [Query.equal('user_id', userId)],
      );

      return documentList.documents
          .map((doc) => Tag.fromDocument(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Mendapatkan tag berdasarkan ID
  Future<Tag> getTag(String id) async {
    try {
      final document = await _databases.getDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.tagsCollection,
        documentId: id,
      );

      return Tag.fromDocument(document);
    } catch (e) {
      rethrow;
    }
  }

  // Menambahkan tag baru
  Future<Tag> addTag(Tag tag) async {
    try {
      final document = await _databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.tagsCollection,
        documentId: ID.unique(),
        data: tag.toMap(),
      );

      return Tag.fromDocument(document);
    } catch (e) {
      rethrow;
    }
  }

  // Memperbarui tag
  Future<Tag> updateTag(Tag tag) async {
    try {
      final document = await _databases.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.tagsCollection,
        documentId: tag.id,
        data: tag.toMap(),
      );

      return Tag.fromDocument(document);
    } catch (e) {
      rethrow;
    }
  }

  // Menghapus tag
  Future<void> deleteTag(String id) async {
    try {
      await _databases.deleteDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.tagsCollection,
        documentId: id,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Mendapatkan tag untuk frasa tertentu
  Future<List<Tag>> getTagsForPhrase(String phraseId, String userId) async {
    try {
      // Pertama, dapatkan semua relasi PhraseTag untuk frasa ini
      final phraseTagsList = await _databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.phraseTagsCollection,
        queries: [
          Query.equal('phrase_id', phraseId),
          Query.equal('user_id', userId),
        ],
      );

      // Jika tidak ada tag yang terkait, kembalikan list kosong
      if (phraseTagsList.documents.isEmpty) {
        return [];
      }

      // Ambil ID tag dari relasi
      final tagIds = phraseTagsList.documents
          .map((doc) => PhraseTag.fromDocument(doc).tagId)
          .toList();

      // Buat queries untuk mencari tag berdasarkan ID
      List<String> queries = [];
      for (var tagId in tagIds) {
        queries.add(Query.equal('\$id', tagId));
      }

      // Gabungkan semua query dengan OR
      final finalQuery = queries.join(' || ');

      // Dapatkan tag berdasarkan ID
      final tagsList = await _databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.tagsCollection,
        queries: [
          Query.equal('user_id', userId),
          Query.search('\$id', finalQuery)
        ],
      );

      return tagsList.documents.map((doc) => Tag.fromDocument(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }

  // Menambahkan tag ke frasa
  Future<void> addTagToPhrase(
      String phraseId, String tagId, String userId) async {
    try {
      // Cek apakah relasi sudah ada
      final existingRelations = await _databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.phraseTagsCollection,
        queries: [
          Query.equal('phrase_id', phraseId),
          Query.equal('tag_id', tagId),
          Query.equal('user_id', userId),
        ],
      );

      // Jika relasi sudah ada, tidak perlu menambahkan lagi
      if (existingRelations.documents.isNotEmpty) {
        return;
      }

      // Buat relasi baru
      final phraseTag = PhraseTag(
        id: ID.unique(),
        phraseId: phraseId,
        tagId: tagId,
        userId: userId,
      );

      await _databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.phraseTagsCollection,
        documentId: phraseTag.id,
        data: phraseTag.toMap(),
      );
    } catch (e) {
      rethrow;
    }
  }

  // Menghapus tag dari frasa
  Future<void> removeTagFromPhrase(
      String phraseId, String tagId, String userId) async {
    try {
      // Cari relasi yang akan dihapus
      final relations = await _databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.phraseTagsCollection,
        queries: [
          Query.equal('phrase_id', phraseId),
          Query.equal('tag_id', tagId),
          Query.equal('user_id', userId),
        ],
      );

      // Jika tidak ada relasi, tidak perlu menghapus
      if (relations.documents.isEmpty) {
        return;
      }

      // Hapus relasi
      for (var doc in relations.documents) {
        await _databases.deleteDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.phraseTagsCollection,
          documentId: doc.$id,
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}
