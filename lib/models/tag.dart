import 'package:appwrite/models.dart';

class Tag {
  final String id;
  final String name;
  final String? color;
  final String userId;
  final DateTime createdAt;

  Tag({
    required this.id,
    required this.name,
    this.color = '#2196F3',
    required this.userId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'color': color ?? '#2196F3',
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Tag.fromDocument(Document document) {
    return Tag(
      id: document.$id,
      name: document.data['name'],
      color: document.data['color'],
      userId: document.data['user_id'],
      createdAt: document.data['created_at'] != null
          ? DateTime.parse(document.data['created_at'])
          : DateTime.parse(document.$createdAt),
    );
  }

  factory Tag.fromMap(Map<String, dynamic> map) {
    return Tag(
      id: map.containsKey('\$id') ? map['\$id'] : map['id'],
      name: map['name'],
      color: map['color'],
      userId: map['user_id'],
      createdAt: map['created_at'] is String
          ? DateTime.parse(map['created_at'])
          : map['created_at'],
    );
  }

  Tag copyWith({
    String? id,
    String? name,
    String? color,
    String? userId,
    DateTime? createdAt,
  }) {
    return Tag(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
