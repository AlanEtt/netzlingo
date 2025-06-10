import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import '../models/user_model.dart';
import '../config/appwrite_constants.dart';
import 'appwrite_service.dart';

class UserService {
  final AppwriteService _appwriteService;
  late Account _account;
  late Databases _databases;

  UserService(this._appwriteService) {
    _account = _appwriteService.account;
    _databases = _appwriteService.databases;
  }

  // Mendapatkan user saat ini
  Future<User> getCurrentUser() async {
    try {
      return await _account.get();
    } catch (e) {
      rethrow;
    }
  }

  // Mendaftar user baru
  Future<User> signup(String email, String password, String name) async {
    try {
      // 1. Buat akun pengguna dengan Account API
      final user = await _account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name,
      );

      // 2. HAPUS Login otomatis setelah signup - ini menyebabkan error user_session_already_exists
      // Kita akan membiarkan AuthProvider yang melakukan login secara terpisah

      // 3. Buat dokumen user di collection users
      try {
        await _createUserDocument(user);
      } catch (e) {
        print("Error creating user document: $e");
        // Tetap lanjutkan meskipun ada error, karena akun sudah terbuat
      }

      return user;
    } catch (e) {
      print("Signup error: $e");
      rethrow;
    }
  }

  // Login
  Future<Session> login(String email, String password) async {
    try {
      return await _account.createEmailSession(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      print('UserService: Attempting to delete current session...');
      await _account.deleteSession(sessionId: 'current');
      print('UserService: Session deleted successfully');
    } catch (e) {
      print('UserService: Error deleting session: $e');
      rethrow;
    }
  }

  // Mendapatkan semua sesi aktif
  Future<List<Session>> getActiveSessions() async {
    try {
      final result = await _account.listSessions();
      return result.sessions;
    } catch (e) {
      print("Error getting active sessions: $e");
      return [];
    }
  }

  // Logout dari semua sesi
  Future<void> logoutAll() async {
    try {
      await _account.deleteSessions();
      print("Logout from all sessions successful");
    } catch (e) {
      print("Error during logoutAll: $e");
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _account.createRecovery(
        email: email,
        url: 'https://netzlingo.app/reset-password',
      );
    } catch (e) {
      rethrow;
    }
  }

  // Update profile
  Future<User> updateProfile({String? name, String? email}) async {
    try {
      User user = await _account.get();

      if (name != null) {
        user = await _account.updateName(name: name);
      }

      if (email != null && email != user.email) {
        user = await _account.updateEmail(
          email: email,
          password: '', // Perlu password saat ini untuk update email
        );
      }

      // Update dokumen user di database
      try {
        await _updateUserDocument(user);
      } catch (e) {
        print("Error updating user document: $e");
        // Tetap lanjutkan meskipun ada error
      }

      return user;
    } catch (e) {
      rethrow;
    }
  }

  // Mendapatkan UserModel (dengan data lengkap dari collection users)
  Future<UserModel> getUserModel(String userId) async {
    try {
      final document = await _databases.getDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollection,
        documentId: userId,
      );

      return UserModel.fromDocument(document);
    } catch (e) {
      // Jika gagal mendapatkan dokumen, coba buat dokumen baru
      print("Error getting user document: $e");

      try {
        // Coba dapatkan data user dari akun
        final user = await _account.get();

        // Buat dokumen user baru jika belum ada
        final userModel = UserModel(
          id: userId,
          name: user.name,
          email: user.email,
          isPremium: false,
          createdAt: DateTime.parse(user.$createdAt),
          updatedAt: DateTime.now(),
          dailyGoal: 10,
          preferredLanguage: 'id',
        );

        // Coba buat dokumen user
        await _createUserDocument(user);

        return userModel;
      } catch (innerError) {
        print("Error creating missing user document: $innerError");
        rethrow;
      }
    }
  }

  // Membuat dokumen user di collection users
  Future<void> _createUserDocument(User user) async {
    try {
      final userModel = UserModel(
        id: user.$id,
        name: user.name,
        email: user.email,
        isPremium: false,
        createdAt: DateTime.parse(user.$createdAt),
        updatedAt: DateTime.parse(user.$createdAt),
        dailyGoal: 10,
        preferredLanguage: 'id',
      );

      // Coba buat dokumen dengan izin yang diberikan oleh Appwrite
      await _databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollection,
        documentId: user.$id,
        data: userModel.toMap(),
        // Berikan izin baca dan tulis untuk pengguna ini
        permissions: [
          Permission.read(Role.user(user.$id)),
          Permission.update(Role.user(user.$id)),
          Permission.delete(Role.user(user.$id)),
        ],
      );
      print("User document created successfully for user ${user.$id}");
    } catch (e) {
      print("Error in _createUserDocument: $e");
      rethrow;
    }
  }

  // Memperbarui dokumen user di collection users
  Future<void> _updateUserDocument(User user) async {
    try {
      // Coba ambil dokumen user yang ada
      Document? document;
      try {
        document = await _databases.getDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.usersCollection,
          documentId: user.$id,
        );
      } catch (e) {
        print("Document not found, will create new one: $e");
      }

      // Jika dokumen ada, update. Jika tidak, buat baru.
      if (document != null) {
        final existingUser = UserModel.fromDocument(document);

        final updatedUser = existingUser.copyWith(
          name: user.name,
          email: user.email,
          updatedAt: DateTime.now(),
        );

        await _databases.updateDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.usersCollection,
          documentId: user.$id,
          data: updatedUser.toMap(),
          // Tambahkan permissions untuk memastikan user memiliki akses
          permissions: [
            Permission.read(Role.user(user.$id)),
            Permission.update(Role.user(user.$id)),
            Permission.delete(Role.user(user.$id)),
          ],
        );
        print("User document updated successfully for user ${user.$id}");
      } else {
        // Buat dokumen baru jika tidak ditemukan
        await _createUserDocument(user);
      }
    } catch (e) {
      print("Error updating user document: $e");
      rethrow;
    }
  }

  // Update pengaturan user
  Future<UserModel> updateUserSettings({
    required String userId,
    int? dailyGoal,
    String? preferredLanguage,
    bool? isPremium,
  }) async {
    try {
      Document? document;

      // Coba ambil dokumen user
      try {
        document = await _databases.getDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.usersCollection,
          documentId: userId,
        );
      } catch (e) {
        print("Error getting document for updateUserSettings: $e");
        // Jika dokumen tidak ditemukan, coba dapatkan user dari auth dan buat dokumen
        final user = await _account.get();
        await _createUserDocument(user);

        // Coba ambil lagi setelah dibuat
        document = await _databases.getDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.usersCollection,
          documentId: userId,
        );
      }

      final existingUser = UserModel.fromDocument(document!);

      // Update properties
      final updatedUser = existingUser.copyWith(
        dailyGoal: dailyGoal,
        preferredLanguage: preferredLanguage,
        isPremium: isPremium,
        updatedAt: DateTime.now(),
      );

      // Save to database
      final updatedDoc = await _databases.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollection,
        documentId: userId,
        data: updatedUser.toMap(),
        // Tambahkan permissions untuk memastikan user memiliki akses
        permissions: [
          Permission.read(Role.user(userId)),
          Permission.update(Role.user(userId)),
          Permission.delete(Role.user(userId)),
        ],
      );

      return UserModel.fromDocument(updatedDoc);
    } catch (e) {
      print("Error in updateUserSettings: $e");
      rethrow;
    }
  }
}
