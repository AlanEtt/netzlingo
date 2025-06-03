import 'package:appwrite/models.dart';

class Settings {
  final String id;
  final String userId;
  final String appLanguage;
  final String theme;
  final bool isDarkMode;
  final bool enableTTS;
  final bool enableNotifications;
  final String notificationTime;
  final int dailyGoal;
  final int dailySessionCount;
  final DateTime? lastSessionDate;
  final DateTime updatedAt;

  Settings({
    required this.id,
    required this.userId,
    this.appLanguage = 'id',
    this.theme = 'light',
    this.isDarkMode = false,
    this.enableTTS = true,
    this.enableNotifications = true,
    this.notificationTime = '20:00',
    this.dailyGoal = 10,
    this.dailySessionCount = 0,
    this.lastSessionDate,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'app_language': appLanguage,
      'theme': theme,
      'is_dark_mode': isDarkMode,
      'enable_tts': enableTTS,
      'enable_notifications': enableNotifications,
      'notification_time': notificationTime,
      'daily_goal': dailyGoal,
      'daily_session_count': dailySessionCount,
      'last_session_date': lastSessionDate?.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Settings.fromDocument(Document document) {
    return Settings(
      id: document.$id,
      userId: document.data['user_id'],
      appLanguage: document.data['app_language'] ?? 'id',
      theme: document.data['theme'] ?? 'light',
      isDarkMode: document.data['is_dark_mode'] ?? false,
      enableTTS: document.data['enable_tts'] ?? true,
      enableNotifications: document.data['enable_notifications'] ?? true,
      notificationTime: document.data['notification_time'] ?? '20:00',
      dailyGoal: document.data['daily_goal'] ?? 10,
      dailySessionCount: document.data['daily_session_count'] ?? 0,
      lastSessionDate: document.data['last_session_date'] != null
          ? DateTime.parse(document.data['last_session_date'])
          : null,
      updatedAt: document.data['updated_at'] != null
          ? DateTime.parse(document.data['updated_at'])
          : DateTime.parse(document.$updatedAt),
    );
  }

  factory Settings.fromMap(Map<String, dynamic> map) {
    return Settings(
      id: map.containsKey('\$id') ? map['\$id'] : map['id'],
      userId: map['user_id'],
      appLanguage: map['app_language'] ?? 'id',
      theme: map['theme'] ?? 'light',
      isDarkMode: map['is_dark_mode'] ?? false,
      enableTTS: map['enable_tts'] ?? true,
      enableNotifications: map['enable_notifications'] ?? true,
      notificationTime: map['notification_time'] ?? '20:00',
      dailyGoal: map['daily_goal'] ?? 10,
      dailySessionCount: map['daily_session_count'] ?? 0,
      lastSessionDate: map['last_session_date'] != null
          ? (map['last_session_date'] is String
              ? DateTime.parse(map['last_session_date'])
              : map['last_session_date'])
          : null,
      updatedAt: map['updated_at'] is String
          ? DateTime.parse(map['updated_at'])
          : map['updated_at'],
    );
  }

  Settings copyWith({
    String? id,
    String? userId,
    String? appLanguage,
    String? theme,
    bool? isDarkMode,
    bool? enableTTS,
    bool? enableNotifications,
    String? notificationTime,
    int? dailyGoal,
    int? dailySessionCount,
    DateTime? lastSessionDate,
    DateTime? updatedAt,
  }) {
    return Settings(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      appLanguage: appLanguage ?? this.appLanguage,
      theme: theme ?? this.theme,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      enableTTS: enableTTS ?? this.enableTTS,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      notificationTime: notificationTime ?? this.notificationTime,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      dailySessionCount: dailySessionCount ?? this.dailySessionCount,
      lastSessionDate: lastSessionDate ?? this.lastSessionDate,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
