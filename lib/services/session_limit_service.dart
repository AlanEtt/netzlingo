import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class SessionLimitService {
  static final SessionLimitService _instance = SessionLimitService._internal();

  factory SessionLimitService() => _instance;

  SessionLimitService._internal();

  // Key untuk SharedPreferences
  static const String _lastSessionDateKey = 'last_session_date';
  static const String _dailySessionCountKey = 'daily_session_count';
  static const int _maxFreeSessionsPerDay =
      10; // Batas sesi untuk pengguna gratis

  // Cek apakah pengguna bisa memulai sesi baru
  Future<bool> canStartNewSession(bool isPremium) async {
    if (isPremium) return true; // Pengguna premium tidak memiliki batasan

    final int remainingSessions = await getRemainingSessionsToday(isPremium);
    return remainingSessions > 0;
  }

  // Mendapatkan jumlah sesi tersisa hari ini
  Future<int> getRemainingSessionsToday(bool isPremium) async {
    if (isPremium) return -1; // -1 menandakan tak terbatas

    final int sessionsUsedToday = await _getSessionsUsedToday();
    return _maxFreeSessionsPerDay - sessionsUsedToday;
  }

  // Mencatat penggunaan sesi baru
  Future<bool> recordNewSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final todayStr = _getDateString(now);

      // Ambil data hari ini
      final lastSessionDateStr = prefs.getString(_lastSessionDateKey) ?? '';
      final int currentCount = prefs.getInt(_dailySessionCountKey) ?? 0;

      // Cek apakah hari yang sama
      if (lastSessionDateStr == todayStr) {
        // Hari yang sama, tambah counter
        await prefs.setInt(_dailySessionCountKey, currentCount + 1);
      } else {
        // Hari berbeda, reset counter
        await prefs.setString(_lastSessionDateKey, todayStr);
        await prefs.setInt(_dailySessionCountKey, 1);
      }

      return true;
    } catch (e) {
      print('Error recording session usage: $e');
      return false;
    }
  }

  // Mendapatkan jumlah sesi yang sudah digunakan hari ini
  Future<int> _getSessionsUsedToday() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final todayStr = _getDateString(now);

      // Ambil data terakhir
      final lastSessionDateStr = prefs.getString(_lastSessionDateKey) ?? '';

      // Jika hari berbeda, reset counter
      if (lastSessionDateStr != todayStr) {
        await prefs.setString(_lastSessionDateKey, todayStr);
        await prefs.setInt(_dailySessionCountKey, 0);
        return 0;
      }

      return prefs.getInt(_dailySessionCountKey) ?? 0;
    } catch (e) {
      print('Error getting sessions used today: $e');
      return 0;
    }
  }

  // Helper untuk format tanggal YYYY-MM-DD
  String _getDateString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
