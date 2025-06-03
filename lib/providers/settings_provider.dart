import 'package:flutter/foundation.dart';
import '../models/settings.dart';
import '../services/settings_service.dart';
import '../services/appwrite_service.dart';

class SettingsProvider with ChangeNotifier {
  final SettingsService _settingsService = SettingsService(AppwriteService());
  Settings? _settings;
  bool _isLoading = false;
  String? _error;

  Settings? get settings => _settings;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isDarkMode => _settings?.isDarkMode ?? false;
  String get appLanguage => _settings?.appLanguage ?? 'id';
  bool get enableTTS => _settings?.enableTTS ?? true;
  bool get enableNotifications => _settings?.enableNotifications ?? true;
  String get notificationTime => _settings?.notificationTime ?? '20:00';
  int get dailyGoal => _settings?.dailyGoal ?? 10;

  // Memuat pengaturan pengguna
  Future<void> loadSettings(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _settings = await _settingsService.getSettings(userId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Memperbarui tema aplikasi
  Future<bool> updateTheme(String userId, bool isDarkMode) async {
    try {
      _settings = await _settingsService.updateTheme(userId, isDarkMode);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Memperbarui bahasa aplikasi
  Future<bool> updateAppLanguage(String userId, String language) async {
    try {
      _settings = await _settingsService.updateAppLanguage(userId, language);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Memperbarui pengaturan notifikasi
  Future<bool> updateNotificationSettings(
    String userId, {
    bool? enableNotifications,
    String? notificationTime,
  }) async {
    try {
      _settings = await _settingsService.updateNotificationSettings(
        userId,
        enableNotifications: enableNotifications,
        notificationTime: notificationTime,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Memperbarui target harian
  Future<bool> updateDailyGoal(String userId, int dailyGoal) async {
    try {
      _settings = await _settingsService.updateDailyGoal(userId, dailyGoal);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Reset error
  void resetError() {
    _error = null;
    notifyListeners();
  }
}
