import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import '../models/category.dart';
import '../config/appwrite_constants.dart';
import 'appwrite_service.dart';

class CategoryService {
  final AppwriteService _appwriteService;
  late Databases _databases;

  CategoryService(this._appwriteService) {
    _databases = _appwriteService.databases;
  }

  // Mendapatkan semua kategori pengguna
  Future<List<Category>> getCategories({
    required String userId,
    String? languageId,
  }) async {
    try {
      List<String> queries = [Query.equal('user_id', userId)];

      if (languageId != null) {
        queries.add(Query.equal('language_id', languageId));
      }

      final documentList = await _databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.categoriesCollection,
        queries: queries,
      );

      return documentList.documents
          .map((doc) => Category.fromDocument(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Mendapatkan kategori berdasarkan ID
  Future<Category> getCategory(String id) async {
    try {
      final document = await _databases.getDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.categoriesCollection,
        documentId: id,
      );

      return Category.fromDocument(document);
    } catch (e) {
      rethrow;
    }
  }

  // Menambahkan kategori baru
  Future<Category> addCategory(Category category) async {
    try {
      final document = await _databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.categoriesCollection,
        documentId: ID.unique(),
        data: category.toMap(),
      );

      return Category.fromDocument(document);
    } catch (e) {
      rethrow;
    }
  }

  // Memperbarui kategori
  Future<Category> updateCategory(Category category) async {
    try {
      final document = await _databases.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.categoriesCollection,
        documentId: category.id,
        data: category.toMap(),
      );

      return Category.fromDocument(document);
    } catch (e) {
      rethrow;
    }
  }

  // Menghapus kategori
  Future<void> deleteCategory(String id) async {
    try {
      await _databases.deleteDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.categoriesCollection,
        documentId: id,
      );
    } catch (e) {
      rethrow;
    }
  }
}
