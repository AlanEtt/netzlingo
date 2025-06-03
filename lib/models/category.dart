import 'package:appwrite/models.dart';

class Category {
  final String id;
  final String name;
  final String? description;
  final String? languageId;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Category({
    required this.id,
    required this.name,
    this.description,
    this.languageId,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description ?? '',
      'language_id': languageId,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Category.fromDocument(Document document) {
    return Category(
      id: document.$id,
      name: document.data['name'],
      description: document.data['description'],
      languageId: document.data['language_id'],
      userId: document.data['user_id'],
      createdAt: document.data['created_at'] != null
          ? DateTime.parse(document.data['created_at'])
          : DateTime.parse(document.$createdAt),
      updatedAt: document.data['updated_at'] != null
          ? DateTime.parse(document.data['updated_at'])
          : DateTime.parse(document.$updatedAt),
    );
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map.containsKey('\$id') ? map['\$id'] : map['id'],
      name: map['name'],
      description: map['description'],
      languageId: map['language_id'],
      userId: map['user_id'],
      createdAt: map['created_at'] is String
          ? DateTime.parse(map['created_at'])
          : map['created_at'],
      updatedAt: map['updated_at'] is String
          ? DateTime.parse(map['updated_at'])
          : map['updated_at'],
    );
  }

  Category copyWith({
    String? id,
    String? name,
    String? description,
    String? languageId,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      languageId: languageId ?? this.languageId,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
