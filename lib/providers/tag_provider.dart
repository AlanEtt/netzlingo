import 'package:flutter/foundation.dart';
import '../models/tag.dart';
import '../services/tag_service.dart';
import '../services/appwrite_service.dart';

class TagProvider with ChangeNotifier {
  final TagService _tagService = TagService(AppwriteService());
  List<Tag> _tags = [];
  Map<String, List<Tag>> _phraseTags =
      {}; // Menyimpan tag berdasarkan phrase_id
  bool _isLoading = false;
  String? _error;

  List<Tag> get tags => _tags;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Memuat semua tag yang tersedia
  Future<void> loadTags(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _tags = await _tagService.getTags(userId);
      // Urutkan tag berdasarkan nama
      _tags.sort((a, b) => a.name.compareTo(b.name));
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Menambah tag baru
  Future<Tag?> addTag(Tag tag) async {
    try {
      final newTag = await _tagService.addTag(tag);
      _tags.add(newTag);
      // Urutkan tag berdasarkan nama
      _tags.sort((a, b) => a.name.compareTo(b.name));
      notifyListeners();

      return newTag;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Memperbarui tag
  Future<bool> updateTag(Tag tag) async {
    try {
      final updatedTag = await _tagService.updateTag(tag);

      final index = _tags.indexWhere((t) => t.id == tag.id);
      if (index != -1) {
        _tags[index] = updatedTag;
        // Urutkan tag berdasarkan nama
        _tags.sort((a, b) => a.name.compareTo(b.name));
        notifyListeners();
      }

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Menghapus tag
  Future<bool> deleteTag(String id) async {
    try {
      await _tagService.deleteTag(id);

      _tags.removeWhere((t) => t.id == id);

      // Update cache phrase_tags jika ada
      _phraseTags.forEach((phraseId, tags) {
        _phraseTags[phraseId] = tags.where((t) => t.id != id).toList();
      });

      notifyListeners();

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Memuat tag untuk frasa tertentu
  Future<List<Tag>> getTagsForPhrase(String phraseId, String userId) async {
    try {
      // Cek cache dulu
      if (_phraseTags.containsKey(phraseId)) {
        return _phraseTags[phraseId]!;
      }

      final tagList = await _tagService.getTagsForPhrase(phraseId, userId);

      // Simpan ke cache
      _phraseTags[phraseId] = tagList;

      return tagList;
    } catch (e) {
      _error = e.toString();
      return [];
    }
  }

  // Menyimpan tag untuk frasa tertentu
  Future<bool> saveTagsForPhrase(
      String phraseId, String userId, List<Tag> tags) async {
    try {
      // Hapus semua tag yang ada untuk phrase ini dan tambahkan yang baru
      for (var tag in tags) {
        // Pastikan tag sudah ada di database
        if (tag.id.isEmpty) {
          final newTag = await addTag(tag);
          if (newTag != null) {
            await _tagService.addTagToPhrase(phraseId, newTag.id, userId);
          }
        } else {
          await _tagService.addTagToPhrase(phraseId, tag.id, userId);
        }
      }

      // Update cache
      _phraseTags[phraseId] = [...tags];

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  // Menambahkan tag ke frasa
  Future<bool> addTagToPhrase(
      String phraseId, String tagId, String userId) async {
    try {
      await _tagService.addTagToPhrase(phraseId, tagId, userId);

      // Update cache jika ada
      if (_phraseTags.containsKey(phraseId)) {
        final tag = await _tagService.getTag(tagId);
        if (!_phraseTags[phraseId]!.any((t) => t.id == tagId)) {
          _phraseTags[phraseId]!.add(tag);
          notifyListeners();
        }
      }

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  // Menghapus tag dari frasa
  Future<bool> removeTagFromPhrase(
      String phraseId, String tagId, String userId) async {
    try {
      await _tagService.removeTagFromPhrase(phraseId, tagId, userId);

      // Update cache jika ada
      if (_phraseTags.containsKey(phraseId)) {
        _phraseTags[phraseId] =
            _phraseTags[phraseId]!.where((t) => t.id != tagId).toList();
        notifyListeners();
      }

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  // Mendapatkan tag berdasarkan ID
  Future<Tag?> getTagById(String id) async {
    try {
      // Cek dulu di list yang sudah ada
      final existingTag = _tags.firstWhere(
        (tag) => tag.id == id,
        orElse: () => Tag(
          id: '',
          name: '',
          userId: '',
          createdAt: DateTime.now(),
        ),
      );

      if (existingTag.id.isNotEmpty) {
        return existingTag;
      }

      // Jika tidak ada, ambil dari database
      return await _tagService.getTag(id);
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }

  // Reset error
  void resetError() {
    _error = null;
    notifyListeners();
  }
}
