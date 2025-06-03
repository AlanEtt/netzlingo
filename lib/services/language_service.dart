import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' hide Language;
import '../models/language.dart';
import '../config/appwrite_constants.dart';
import 'appwrite_service.dart';

class LanguageService {
  final AppwriteService _appwriteService;
  late Databases _databases;

  LanguageService(this._appwriteService) {
    _databases = _appwriteService.databases;
  }

  // Mendapatkan semua bahasa
  Future<List<Language>> getLanguages() async {
    try {
      final documentList = await _databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.languagesCollection,
      );

      return documentList.documents
          .map((doc) => Language.fromDocument(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Mendapatkan bahasa berdasarkan kode
  Future<Language> getLanguageByCode(String code) async {
    try {
      final documentList = await _databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.languagesCollection,
        queries: [
          Query.equal('code', code),
        ],
      );

      if (documentList.documents.isEmpty) {
        throw Exception('Bahasa dengan kode $code tidak ditemukan');
      }

      return Language.fromDocument(documentList.documents.first);
    } catch (e) {
      rethrow;
    }
  }

  // Mendapatkan bahasa berdasarkan ID
  Future<Language> getLanguageById(String id) async {
    try {
      final document = await _databases.getDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.languagesCollection,
        documentId: id,
      );

      return Language.fromDocument(document);
    } catch (e) {
      rethrow;
    }
  }

  // Fungsi untuk subscribe ke perubahan bahasa
  Stream<RealtimeMessage> subscribeToLanguages() {
    return _appwriteService.realtime.subscribe([
      'databases.${AppwriteConstants.databaseId}.collections.${AppwriteConstants.languagesCollection}.documents'
    ]).stream;
  }
}
