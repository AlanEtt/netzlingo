import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

// Mock untuk database
class Database {
  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
  }) async {
    // Return empty list for now
    return [];
  }

  Future<List<Map<String, dynamic>>> rawQuery(
      String query, List<dynamic> args) async {
    // Return empty list for now
    return [];
  }

  Future<int> insert(String table, Map<String, dynamic> data) async {
    // Return dummy ID
    return 1;
  }

  Future<int> update(
    String table,
    Map<String, dynamic> data, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    // Return number of rows affected
    return 1;
  }

  Future<int> delete(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    // Return number of rows affected
    return 1;
  }

  Future<void> execute(String sql) async {
    // Do nothing
  }
}

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  static Database? _database;
  static SharedPreferences? _prefs;

  // Flag untuk menandai apakah kita di web atau native
  final bool _isWebPlatform = kIsWeb;

  // Mendapatkan database instance
  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = Database(); // Use mock database
    return _database!;
  }

  // Mendapatkan shared preferences instance
  Future<SharedPreferences> get prefs async {
    if (_prefs != null) return _prefs!;
    _prefs = await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ===== Metode untuk Web Platform =====

  // Menyimpan pengaturan di web menggunakan SharedPreferences
  Future<void> saveSettingsWeb(Map<String, dynamic> settings) async {
    final prefs = await this.prefs;

    // Simpan data pengaturan sebagai JSON string
    await prefs.setString('app_language', settings['app_language'] as String);
    await prefs.setString('theme', settings['theme'] as String);
    await prefs.setBool('is_dark_mode', settings['is_dark_mode'] == 1);
    await prefs.setBool('enable_tts', settings['enable_tts'] == 1);
    await prefs.setBool(
        'enable_notifications', settings['enable_notifications'] == 1);
    await prefs.setString(
        'notification_time', settings['notification_time'] as String);
    await prefs.setInt('daily_goal', settings['daily_goal'] as int);
    await prefs.setBool('is_premium', settings['is_premium'] == 1);
  }

  // Mendapatkan pengaturan di web dari SharedPreferences
  Future<Map<String, dynamic>> getSettingsWeb() async {
    final prefs = await this.prefs;

    // Default values jika tidak ada data tersimpan
    return {
      'id': 1,
      'app_language': prefs.getString('app_language') ?? 'id',
      'theme': prefs.getString('theme') ?? 'light',
      'is_dark_mode': prefs.getBool('is_dark_mode') == true ? 1 : 0,
      'enable_tts': prefs.getBool('enable_tts') == true ? 1 : 0,
      'enable_notifications':
          prefs.getBool('enable_notifications') == true ? 1 : 0,
      'notification_time': prefs.getString('notification_time') ?? '20:00',
      'daily_goal': prefs.getInt('daily_goal') ?? 10,
      'is_premium': prefs.getBool('is_premium') == true ? 1 : 0,
      'daily_session_count': 0,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  // Mendapatkan flag apakah ini platform web
  bool get isWebPlatform => _isWebPlatform;
}
