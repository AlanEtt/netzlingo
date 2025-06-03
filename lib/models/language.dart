import 'package:appwrite/models.dart';

class Language {
  final String id;
  final String name;
  final String code;
  final String? flagIcon;
  final DateTime createdAt;
  final DateTime updatedAt;

  Language({
    required this.id,
    required this.name,
    required this.code,
    this.flagIcon,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'code': code,
      'flag_icon': flagIcon,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Language.fromDocument(Document document) {
    return Language(
      id: document.$id,
      name: document.data['name'],
      code: document.data['code'],
      flagIcon: document.data['flag_icon'],
      createdAt: document.data['created_at'] != null
          ? DateTime.parse(document.data['created_at'])
          : DateTime.parse(document.$createdAt),
      updatedAt: document.data['updated_at'] != null
          ? DateTime.parse(document.data['updated_at'])
          : DateTime.parse(document.$updatedAt),
    );
  }

  factory Language.fromMap(Map<String, dynamic> map) {
    return Language(
      id: map.containsKey('\$id') ? map['\$id'] : map['id'],
      name: map['name'],
      code: map['code'],
      flagIcon: map['flag_icon'],
      createdAt: map['created_at'] is String
          ? DateTime.parse(map['created_at'])
          : map['created_at'],
      updatedAt: map['updated_at'] is String
          ? DateTime.parse(map['updated_at'])
          : map['updated_at'],
    );
  }

  Language copyWith({
    String? id,
    String? name,
    String? code,
    String? flagIcon,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Language(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      flagIcon: flagIcon ?? this.flagIcon,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
