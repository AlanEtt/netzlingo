import 'package:appwrite/models.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final bool isPremium;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int dailyGoal;
  final String preferredLanguage;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.isPremium = false,
    required this.createdAt,
    required this.updatedAt,
    this.dailyGoal = 10,
    this.preferredLanguage = 'id',
  });

  factory UserModel.fromAccount(User account) {
    return UserModel(
      id: account.$id,
      name: account.name,
      email: account.email,
      isPremium: false,
      createdAt: DateTime.parse(account.$createdAt),
      updatedAt: DateTime.parse(account.$updatedAt),
    );
  }

  factory UserModel.fromDocument(Document document) {
    return UserModel(
      id: document.$id,
      name: document.data['name'],
      email: document.data['email'],
      isPremium: document.data['is_premium'] ?? false,
      createdAt: document.data['created_at'] != null
          ? DateTime.parse(document.data['created_at'])
          : DateTime.parse(document.$createdAt),
      updatedAt: document.data['updated_at'] != null
          ? DateTime.parse(document.data['updated_at'])
          : DateTime.parse(document.$updatedAt),
      dailyGoal: document.data['daily_goal'] ?? 10,
      preferredLanguage: document.data['preferred_language'] ?? 'id',
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map.containsKey('\$id') ? map['\$id'] : map['id'],
      name: map['name'],
      email: map['email'],
      isPremium: map['is_premium'] ?? false,
      createdAt: map['created_at'] is String
          ? DateTime.parse(map['created_at'])
          : map['created_at'],
      updatedAt: map['updated_at'] is String
          ? DateTime.parse(map['updated_at'])
          : map['updated_at'],
      dailyGoal: map['daily_goal'] ?? 10,
      preferredLanguage: map['preferred_language'] ?? 'id',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'is_premium': isPremium,
      'daily_goal': dailyGoal,
      'preferred_language': preferredLanguage,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    bool? isPremium,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? dailyGoal,
    String? preferredLanguage,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      isPremium: isPremium ?? this.isPremium,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
    );
  }
}
