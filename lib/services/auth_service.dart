import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import '../config/appwrite_constants.dart';
import 'appwrite_service.dart';
import '../models/user_model.dart';

class AuthService {
  final AppwriteService _appwriteService = AppwriteService();

  Future<UserModel?> createUser({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final account = await _appwriteService.account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name,
      );

      // Buat dokumen user di collection
      await _appwriteService.databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollection,
        documentId: account.$id,
        data: {
          'name': name,
          'email': email,
          'is_premium': false,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          'daily_goal': 10,
          'preferred_language': 'id',
        },
      );

      // Buat dokumen settings untuk user
      await _appwriteService.databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.settingsCollection,
        documentId: ID.unique(),
        data: {
          'user_id': account.$id,
          'app_language': 'id',
          'theme': 'light',
          'is_dark_mode': false,
          'enable_tts': true,
          'enable_notifications': true,
          'notification_time': '08:00',
          'daily_goal': 10,
          'updated_at': DateTime.now().toIso8601String(),
        },
      );

      return UserModel.fromAccount(account);
    } catch (e) {
      rethrow;
    }
  }

  Future<Session> login({
    required String email,
    required String password,
  }) async {
    try {
      return await _appwriteService.account.createEmailSession(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _appwriteService.account.deleteSession(sessionId: 'current');
    } catch (e) {
      rethrow;
    }
  }

  Future<User> getCurrentUser() async {
    try {
      return await _appwriteService.account.get();
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel> getUserData(String userId) async {
    try {
      final document = await _appwriteService.databases.getDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollection,
        documentId: userId,
      );

      return UserModel.fromMap(document.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> isUserPremium(String userId) async {
    try {
      final userData = await getUserData(userId);
      return userData.isPremium;
    } catch (e) {
      return false;
    }
  }
}
