import 'package:appwrite/models.dart';

class Phrase {
  final String id;
  final String originalText;
  final String translatedText;
  final String languageId;
  final String? categoryId;
  final String userId;
  final String? notes;
  final bool isFavorite;
  final int importance;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPublic;
  final List<String>? tags; // Tambahkan properti tags

  Phrase({
    required this.id,
    required this.originalText,
    required this.translatedText,
    required this.languageId,
    this.categoryId,
    required this.userId,
    this.notes,
    this.isFavorite = false,
    this.importance = 1,
    required this.createdAt,
    required this.updatedAt,
    this.isPublic = false,
    this.tags, // Tambahkan tags di constructor
  });

  Map<String, dynamic> toMap() {
    return {
      'original_text': originalText,
      'translated_text': translatedText,
      'language_id': languageId,
      'category_id': categoryId,
      'user_id': userId,
      'notes': notes ?? '',
      'is_favorite': isFavorite,
      'importance': importance,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_public': isPublic,
      'tags': tags ?? [], // Tambahkan tags ke map
    };
  }

  factory Phrase.fromDocument(Document document) {
    // Parse tags jika ada
    List<String>? parsedTags;
    if (document.data['tags'] != null) {
      if (document.data['tags'] is List) {
        parsedTags = List<String>.from(document.data['tags']);
      }
    }

    return Phrase(
      id: document.$id,
      originalText: document.data['original_text'],
      translatedText: document.data['translated_text'],
      languageId: document.data['language_id'],
      categoryId: document.data['category_id'],
      userId: document.data['user_id'],
      notes: document.data['notes'],
      isFavorite: document.data['is_favorite'] ?? false,
      importance: document.data['importance'] ?? 1,
      createdAt: document.data['created_at'] != null
          ? DateTime.parse(document.data['created_at'])
          : DateTime.parse(document.$createdAt),
      updatedAt: document.data['updated_at'] != null
          ? DateTime.parse(document.data['updated_at'])
          : DateTime.parse(document.$updatedAt),
      isPublic: document.data['is_public'] ?? false,
      tags: parsedTags, // Tambahkan tags dari dokumen
    );
  }

  factory Phrase.fromMap(Map<String, dynamic> map) {
    // Parse tags jika ada
    List<String>? parsedTags;
    if (map['tags'] != null) {
      if (map['tags'] is List) {
        parsedTags = List<String>.from(map['tags']);
      }
    }

    return Phrase(
      id: map.containsKey('\$id') ? map['\$id'] : map['id'],
      originalText: map['original_text'],
      translatedText: map['translated_text'],
      languageId: map['language_id'],
      categoryId: map['category_id'],
      userId: map['user_id'],
      notes: map['notes'],
      isFavorite: map['is_favorite'] ?? false,
      importance: map['importance'] ?? 1,
      createdAt: map['created_at'] is String
          ? DateTime.parse(map['created_at'])
          : map['created_at'],
      updatedAt: map['updated_at'] is String
          ? DateTime.parse(map['updated_at'])
          : map['updated_at'],
      isPublic: map['is_public'] ?? false,
      tags: parsedTags, // Tambahkan tags dari map
    );
  }

  Phrase copyWith({
    String? id,
    String? originalText,
    String? translatedText,
    String? languageId,
    String? categoryId,
    String? userId,
    String? notes,
    bool? isFavorite,
    int? importance,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPublic,
    List<String>? tags, // Tambahkan tags
  }) {
    return Phrase(
      id: id ?? this.id,
      originalText: originalText ?? this.originalText,
      translatedText: translatedText ?? this.translatedText,
      languageId: languageId ?? this.languageId,
      categoryId: categoryId ?? this.categoryId,
      userId: userId ?? this.userId,
      notes: notes ?? this.notes,
      isFavorite: isFavorite ?? this.isFavorite,
      importance: importance ?? this.importance,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPublic: isPublic ?? this.isPublic,
      tags: tags ?? this.tags, // Tambahkan tags
    );
  }

  // Metode utuk membuat Phrase menjadi publik
  Phrase makePublic() {
    return copyWith(isPublic: true);
  }

  // Mendapatkan daftar frasa default publik
  static List<Phrase> getDefaultPublicPhrases() {
    final now = DateTime.now();
    return [
      Phrase(
        id: 'default_1',
        userId: 'system',
        languageId: 'en',
        categoryId: 'basics',
        originalText: 'Hello, how are you?',
        translatedText: 'Halo, apa kabar?',
        notes: 'Greeting in English',
        isFavorite: false,
        createdAt: now,
        updatedAt: now,
        isPublic: true,
      ),
      Phrase(
        id: 'default_2',
        userId: 'system',
        languageId: 'en',
        categoryId: 'basics',
        originalText: 'Thank you very much',
        translatedText: 'Terima kasih banyak',
        notes: 'Expression of gratitude',
        isFavorite: false,
        createdAt: now,
        updatedAt: now,
        isPublic: true,
      ),
      Phrase(
        id: 'default_3',
        userId: 'system',
        languageId: 'en',
        categoryId: 'basics',
        originalText: 'My name is...',
        translatedText: 'Nama saya...',
        notes: 'Self introduction',
        isFavorite: false,
        createdAt: now,
        updatedAt: now,
        isPublic: true,
      ),
      Phrase(
        id: 'default_4',
        userId: 'system',
        languageId: 'en',
        categoryId: 'basics',
        originalText: 'I would like to learn this language',
        translatedText: 'Saya ingin belajar bahasa ini',
        notes: 'Expressing interest in learning',
        isFavorite: false,
        createdAt: now,
        updatedAt: now,
        isPublic: true,
      ),
      Phrase(
        id: 'default_5',
        userId: 'system',
        languageId: 'en',
        categoryId: 'basics',
        originalText: 'Where is the bathroom?',
        translatedText: 'Di mana kamar mandinya?',
        notes: 'Common travel question',
        isFavorite: false,
        createdAt: now,
        updatedAt: now,
        isPublic: true,
      ),
      // Tambahkan frasa dasar Indonesia-English
      Phrase(
        id: 'default_6',
        userId: 'system',
        languageId: 'id',
        categoryId: 'basics',
        originalText: 'Selamat pagi',
        translatedText: 'Good morning',
        notes: 'Morning greeting in Indonesian',
        isFavorite: false,
        createdAt: now,
        updatedAt: now,
        isPublic: true,
      ),
      Phrase(
        id: 'default_7',
        userId: 'system',
        languageId: 'id',
        categoryId: 'basics',
        originalText: 'Apa kabar?',
        translatedText: 'How are you?',
        notes: 'Asking well-being in Indonesian',
        isFavorite: false,
        createdAt: now,
        updatedAt: now,
        isPublic: true,
      ),
      Phrase(
        id: 'default_8',
        userId: 'system',
        languageId: 'id',
        categoryId: 'basics',
        originalText: 'Saya lapar',
        translatedText: 'I am hungry',
        notes: 'Expressing hunger in Indonesian',
        isFavorite: false,
        createdAt: now,
        updatedAt: now,
        isPublic: true,
      ),
    ];
  }
}
