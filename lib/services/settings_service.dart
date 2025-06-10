import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import '../models/settings.dart';
import '../config/appwrite_constants.dart';
import 'appwrite_service.dart';

class SettingsService {
  final AppwriteService _appwriteService;
  late Databases _databases;

  SettingsService(this._appwriteService) {
    _databases = _appwriteService.databases;
  }

  // Mendapatkan atau membuat pengaturan universal untuk semua jenis akun
  Future<Settings> getOrCreateUniversalSettings() async {
    try {
      print("Getting universal settings");
      // Cari pengaturan universal yang sudah ada
      final documentList = await _databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.settingsCollection,
        queries: [Query.equal('user_id', 'universal')],
      );

      // Jika pengaturan universal sudah ada, kembalikan
      if (documentList.documents.isNotEmpty) {
        print("Universal settings found");
        return Settings.fromDocument(documentList.documents.first);
      }

      // Jika belum ada, buat pengaturan universal
      print("Creating universal settings");
      final settings = Settings(
        id: ID.unique(),
        userId: 'universal',
        appLanguage: 'id',
        theme: 'light',
        isDarkMode: false,
        enableTTS: true,
        enableNotifications: false,
        notificationTime: '20:00',
        dailyGoal: 5,
        dailySessionCount: 0,
        updatedAt: DateTime.now(),
      );

      try {
        final document = await _databases.createDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.settingsCollection,
          documentId: settings.id,
          data: settings.toMap(),
          // Izin sangat permisif - semua bisa mengakses
          permissions: [
            Permission.read(Role.any()),
            Permission.read(Role.users()),
            Permission.read(Role.guests()),
            Permission.update(Role.team("admin", "owner")),
            Permission.delete(Role.team("admin", "owner")),
          ],
        );
        return Settings.fromDocument(document);
      } catch (e) {
        print("Error creating universal settings with permissions: $e");
        // Coba tanpa permissions
        final document = await _databases.createDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.settingsCollection,
          documentId: settings.id,
          data: settings.toMap(),
        );
        return Settings.fromDocument(document);
      }
    } catch (e) {
      print("Error getting/creating universal settings: $e");
      // Kembalikan objek settings default sebagai fallback
      return Settings(
        id: 'universal_fallback',
        userId: 'universal',
        appLanguage: 'id',
        theme: 'light',
        isDarkMode: false,
        enableTTS: true,
        enableNotifications: false,
        notificationTime: '20:00',
        dailyGoal: 5,
        dailySessionCount: 0,
        updatedAt: DateTime.now(),
      );
    }
  }

  // Mendapatkan pengaturan pengguna
  Future<Settings> getSettings(String userId) async {
    try {
      // Untuk userId universal atau guest, pakai pengaturan universal
      if (userId == 'universal' || userId == 'guest') {
        return await getOrCreateUniversalSettings();
      }

      print("Attempting to get settings for user: $userId");
      // Cari pengaturan yang sudah ada
      final documentList = await _databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.settingsCollection,
        queries: [Query.equal('user_id', userId)],
      );

      // Jika pengaturan sudah ada, kembalikan
      if (documentList.documents.isNotEmpty) {
        print("Settings found for user: $userId");
        return Settings.fromDocument(documentList.documents.first);
      }

      // Jika belum ada, buat pengaturan default
      print("No settings found, creating default settings for user: $userId");
      return await createDefaultSettings(userId);
    } catch (e) {
      print("Error getting settings: $e");

      // Jika error adalah permission denied atau unauthorized, coba pengaturan universal
      if (e.toString().contains('user_unauthorized') ||
          e.toString().contains('401')) {
        print("Permission issue, trying universal settings");
        return await getOrCreateUniversalSettings();
      }

      // Coba lagi dengan membuat pengaturan baru dengan strategi berbeda
      try {
        return await _createDefaultSettingsWithoutPermissions(userId);
      } catch (innerError) {
        print("Error creating default settings: $innerError");

        // Sebagai fallback, kembalikan objek Settings tanpa menyimpan ke database
        print("Returning fallback settings object");
        return Settings(
          id: 'local_fallback',
          userId: userId,
          appLanguage: 'id',
          theme: 'light',
          isDarkMode: false,
          enableTTS: true,
          enableNotifications: true,
          notificationTime: '20:00',
          dailyGoal: 10,
          dailySessionCount: 0,
          updatedAt: DateTime.now(),
        );
      }
    }
  }

  // Membuat pengaturan default untuk pengguna baru (dengan permissions)
  Future<Settings> createDefaultSettings(String userId) async {
    try {
      print("Creating default settings with permissions for user: $userId");
      final settings = Settings(
        id: ID.unique(),
        userId: userId,
        appLanguage: 'id',
        theme: 'light',
        isDarkMode: false,
        enableTTS: true,
        enableNotifications: true,
        notificationTime: '20:00',
        dailyGoal: 10,
        dailySessionCount: 0,
        updatedAt: DateTime.now(),
      );

      final document = await _databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.settingsCollection,
        documentId: settings.id,
        data: settings.toMap(),
        // Izin yang lebih permisif - izinkan any untuk create dan read
        permissions: [
          Permission.read(Role.any()),
          Permission.read(Role.user(userId)),
          Permission.update(Role.user(userId)),
          Permission.delete(Role.user(userId)),
        ],
      );

      print("Default settings document created successfully for user: $userId");
      return Settings.fromDocument(document);
    } catch (e) {
      print("Error in createDefaultSettings: $e");
      throw e;
    }
  }

  // Membuat pengaturan default tanpa permissions (sebagai fallback)
  Future<Settings> _createDefaultSettingsWithoutPermissions(
      String userId) async {
    try {
      print("Creating default settings WITHOUT permissions for user: $userId");
      final settings = Settings(
        id: ID.unique(),
        userId: userId,
        appLanguage: 'id',
        theme: 'light',
        isDarkMode: false,
        enableTTS: true,
        enableNotifications: true,
        notificationTime: '20:00',
        dailyGoal: 10,
        dailySessionCount: 0,
        updatedAt: DateTime.now(),
      );

      final document = await _databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.settingsCollection,
        documentId: settings.id,
        data: settings.toMap(),
        // Biarkan AppWrite mengatur permissions default
      );

      print("Default settings created without custom permissions");
      return Settings.fromDocument(document);
    } catch (e) {
      print("Error in _createDefaultSettingsWithoutPermissions: $e");
      throw e;
    }
  }

  // Memperbarui pengaturan
  Future<Settings> updateSettings(Settings settings) async {
    try {
      final updatedSettings = settings.copyWith(
        updatedAt: DateTime.now(),
      );

      Document document;
      try {
        // Coba update dengan permissions
        document = await _databases.updateDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.settingsCollection,
          documentId: settings.id,
          data: updatedSettings.toMap(),
          // Izin yang sama dengan createDefaultSettings
          permissions: [
            Permission.read(Role.any()),
            Permission.read(Role.user(settings.userId)),
            Permission.update(Role.user(settings.userId)),
            Permission.delete(Role.user(settings.userId)),
          ],
        );
      } catch (e) {
        print("Error updating with permissions: $e");
        // Jika gagal, coba tanpa permissions
        document = await _databases.updateDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.settingsCollection,
          documentId: settings.id,
          data: updatedSettings.toMap(),
          // Tidak ada permissions yang ditentukan
        );
      }

      return Settings.fromDocument(document);
    } catch (e) {
      print("Error in updateSettings: $e");
      return settings.copyWith(
          updatedAt: DateTime.now()); // Return current settings as fallback
    }
  }

  // Memperbarui tema aplikasi
  Future<Settings> updateTheme(String userId, bool isDarkMode) async {
    try {
      final settings = await getSettings(userId);
      final updatedSettings = settings.copyWith(
        isDarkMode: isDarkMode,
        theme: isDarkMode ? 'dark' : 'light',
        updatedAt: DateTime.now(),
      );

      return await updateSettings(updatedSettings);
    } catch (e) {
      print("Error in updateTheme: $e");

      // Kembalikan objek settings default sebagai fallback
      return Settings(
        id: 'local_fallback',
        userId: userId,
        appLanguage: 'id',
        theme: isDarkMode ? 'dark' : 'light',
        isDarkMode: isDarkMode,
        enableTTS: true,
        enableNotifications: true,
        notificationTime: '20:00',
        dailyGoal: 10,
        dailySessionCount: 0,
        updatedAt: DateTime.now(),
      );
    }
  }

  // Memperbarui bahasa aplikasi
  Future<Settings> updateAppLanguage(String userId, String language) async {
    try {
      final settings = await getSettings(userId);
      final updatedSettings = settings.copyWith(
        appLanguage: language,
        updatedAt: DateTime.now(),
      );

      return await updateSettings(updatedSettings);
    } catch (e) {
      print("Error in updateAppLanguage: $e");

      // Kembalikan objek settings default sebagai fallback
      return Settings(
        id: 'local_fallback',
        userId: userId,
        appLanguage: language,
        theme: 'light',
        isDarkMode: false,
        enableTTS: true,
        enableNotifications: true,
        notificationTime: '20:00',
        dailyGoal: 10,
        dailySessionCount: 0,
        updatedAt: DateTime.now(),
      );
    }
  }

  // Memperbarui pengaturan notifikasi
  Future<Settings> updateNotificationSettings(
    String userId, {
    bool? enableNotifications,
    String? notificationTime,
  }) async {
    try {
      final settings = await getSettings(userId);
      final updatedSettings = settings.copyWith(
        enableNotifications: enableNotifications,
        notificationTime: notificationTime,
        updatedAt: DateTime.now(),
      );

      return await updateSettings(updatedSettings);
    } catch (e) {
      print("Error in updateNotificationSettings: $e");

      // Kembalikan objek settings default sebagai fallback
      return Settings(
        id: 'local_fallback',
        userId: userId,
        appLanguage: 'id',
        theme: 'light',
        isDarkMode: false,
        enableTTS: true,
        enableNotifications: enableNotifications ?? true,
        notificationTime: notificationTime ?? '20:00',
        dailyGoal: 10,
        dailySessionCount: 0,
        updatedAt: DateTime.now(),
      );
    }
  }

  // Memperbarui target harian
  Future<Settings> updateDailyGoal(String userId, int dailyGoal) async {
    try {
      final settings = await getSettings(userId);
      final updatedSettings = settings.copyWith(
        dailyGoal: dailyGoal,
        updatedAt: DateTime.now(),
      );

      return await updateSettings(updatedSettings);
    } catch (e) {
      print("Error in updateDailyGoal: $e");

      // Kembalikan objek settings default sebagai fallback
      return Settings(
        id: 'local_fallback',
        userId: userId,
        appLanguage: 'id',
        theme: 'light',
        isDarkMode: false,
        enableTTS: true,
        enableNotifications: true,
        notificationTime: '20:00',
        dailyGoal: dailyGoal,
        dailySessionCount: 0,
        updatedAt: DateTime.now(),
      );
    }
  }

  // Memperbarui jumlah sesi hari ini
  Future<Settings> updateDailySessionCount(String userId, int count) async {
    try {
      final settings = await getSettings(userId);
      final updatedSettings = settings.copyWith(
        dailySessionCount: count,
        lastSessionDate: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      return await updateSettings(updatedSettings);
    } catch (e) {
      print("Error in updateDailySessionCount: $e");

      // Kembalikan objek settings default sebagai fallback
      return Settings(
        id: 'local_fallback',
        userId: userId,
        appLanguage: 'id',
        theme: 'light',
        isDarkMode: false,
        enableTTS: true,
        enableNotifications: true,
        notificationTime: '20:00',
        dailyGoal: 10,
        dailySessionCount: count,
        lastSessionDate: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  // Reset jumlah sesi harian jika hari sudah berganti
  Future<Settings> resetDailySessionCountIfNeeded(String userId) async {
    try {
      final settings = await getSettings(userId);

      // Jika belum ada sesi sebelumnya, tidak perlu reset
      if (settings.lastSessionDate == null) {
        return settings;
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final lastSessionDay = DateTime(
        settings.lastSessionDate!.year,
        settings.lastSessionDate!.month,
        settings.lastSessionDate!.day,
      );

      // Jika hari sudah berganti, reset jumlah sesi
      if (today.isAfter(lastSessionDay)) {
        final updatedSettings = settings.copyWith(
          dailySessionCount: 0,
          updatedAt: now,
        );

        return await updateSettings(updatedSettings);
      }

      return settings;
    } catch (e) {
      print("Error in resetDailySessionCountIfNeeded: $e");

      // Kembalikan objek settings default sebagai fallback
      return Settings(
        id: 'local_fallback',
        userId: userId,
        appLanguage: 'id',
        theme: 'light',
        isDarkMode: false,
        enableTTS: true,
        enableNotifications: true,
        notificationTime: '20:00',
        dailyGoal: 10,
        dailySessionCount: 0,
        updatedAt: DateTime.now(),
      );
    }
  }

  // Memperbarui pengaturan tertentu dengan nilai baru
  Future<Settings> updateSetting(
      String userId, String key, String value) async {
    try {
      final settings = await getSettings(userId);

      // Buat map data untuk update
      Map<String, dynamic> data = {
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Tambahkan key yang akan diupdate
      switch (key) {
        case 'app_language':
          data['app_language'] = value;
          break;
        case 'theme':
          data['theme'] = value;
          break;
        case 'is_dark_mode':
          data['is_dark_mode'] = value.toLowerCase() == 'true';
          break;
        case 'enable_tts':
          data['enable_tts'] = value.toLowerCase() == 'true';
          break;
        case 'enable_notifications':
          data['enable_notifications'] = value.toLowerCase() == 'true';
          break;
        case 'notification_time':
          data['notification_time'] = value;
          break;
        case 'daily_goal':
          data['daily_goal'] = int.tryParse(value) ?? 10;
          break;
        case 'daily_session_count':
          data['daily_session_count'] = int.tryParse(value) ?? 0;
          break;
        case 'remaining_sessions':
          data['remaining_sessions'] = int.tryParse(value) ?? 10;
          break;
        default:
          // Key tidak dikenali, jangan lakukan update
          return settings;
      }

      // Update dokumen
      try {
        final document = await _databases.updateDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.settingsCollection,
          documentId: settings.id,
          data: data,
        );

        return Settings.fromDocument(document);
      } catch (e) {
        print("Error updating setting $key: $e");

        // Jika gagal update, kembalikan settings dengan nilai yang diubah secara lokal
        final Map<String, dynamic> updatedData = {...settings.toMap()};
        updatedData.addAll(data);

        return Settings.fromMap(updatedData);
      }
    } catch (e) {
      print("Error in updateSetting: $e");

      // Kembalikan objek settings default sebagai fallback
      return Settings(
        id: 'local_fallback',
        userId: userId,
        appLanguage: 'id',
        theme: 'light',
        isDarkMode: false,
        enableTTS: true,
        enableNotifications: true,
        notificationTime: '20:00',
        dailyGoal: 10,
        dailySessionCount: 0,
        updatedAt: DateTime.now(),
      );
    }
  }
}
