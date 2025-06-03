import 'package:appwrite/models.dart';

class PhraseTag {
  final String id;
  final String phraseId;
  final String tagId;
  final String userId;

  PhraseTag({
    required this.id,
    required this.phraseId,
    required this.tagId,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'phrase_id': phraseId,
      'tag_id': tagId,
      'user_id': userId,
    };
  }

  factory PhraseTag.fromDocument(Document document) {
    return PhraseTag(
      id: document.$id,
      phraseId: document.data['phrase_id'],
      tagId: document.data['tag_id'],
      userId: document.data['user_id'],
    );
  }

  factory PhraseTag.fromMap(Map<String, dynamic> map) {
    return PhraseTag(
      id: map.containsKey('\$id') ? map['\$id'] : map['id'],
      phraseId: map['phrase_id'],
      tagId: map['tag_id'],
      userId: map['user_id'],
    );
  }

  PhraseTag copyWith({
    String? id,
    String? phraseId,
    String? tagId,
    String? userId,
  }) {
    return PhraseTag(
      id: id ?? this.id,
      phraseId: phraseId ?? this.phraseId,
      tagId: tagId ?? this.tagId,
      userId: userId ?? this.userId,
    );
  }
}
