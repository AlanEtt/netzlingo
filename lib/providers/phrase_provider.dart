import 'package:flutter/foundation.dart';
import '../models/phrase.dart';
import '../services/phrase_service.dart';
import '../services/appwrite_service.dart';

class PhraseProvider with ChangeNotifier {
  final PhraseService _phraseService = PhraseService(AppwriteService());
  List<Phrase> _phrases = [];
  bool _isLoading = false;
  String? _error;

  List<Phrase> get phrases => _phrases;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fungsi untuk memuat semua frasa atau berdasarkan filter
  Future<void> loadPhrases(
      {String? userId,
      String? languageId,
      String? categoryId,
      bool? isFavorite}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _phrases = await _phraseService.getPhrases(
        userId: userId,
        languageId: languageId,
        categoryId: categoryId,
        isFavorite: isFavorite,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fungsi untuk menambahkan frasa baru
  Future<Phrase?> addPhrase(Phrase phrase) async {
    try {
      final newPhrase = await _phraseService.addPhrase(phrase);
      _phrases.insert(0, newPhrase);
      notifyListeners();
      return newPhrase;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Fungsi untuk memperbarui frasa
  Future<bool> updatePhrase(Phrase phrase) async {
    try {
      final updatedPhrase = await _phraseService.updatePhrase(phrase);

      final index = _phrases.indexWhere((p) => p.id == phrase.id);
      if (index != -1) {
        _phrases[index] = updatedPhrase;
        notifyListeners();
      }

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Fungsi untuk menghapus frasa
  Future<bool> deletePhrase(String id) async {
    try {
      await _phraseService.deletePhrase(id);

      _phrases.removeWhere((p) => p.id == id);
      notifyListeners();

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Fungsi untuk memuat frasa berdasarkan pencarian
  Future<void> searchPhrases(String keyword, {String? userId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _phrases = await _phraseService.searchPhrases(keyword, userId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fungsi untuk toggle favorit
  Future<bool> toggleFavorite(Phrase phrase) async {
    try {
      final updatedPhrase = await _phraseService.toggleFavorite(phrase);

      final index = _phrases.indexWhere((p) => p.id == phrase.id);
      if (index != -1) {
        _phrases[index] = updatedPhrase;
        notifyListeners();
      }

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Mendapatkan frasa berdasarkan ID
  Future<Phrase?> getPhraseById(String id) async {
    try {
      // Cek dulu di list yang sudah ada
      final existingPhrase = _phrases.firstWhere(
        (phrase) => phrase.id == id,
        orElse: () => Phrase(
          id: '',
          originalText: '',
          translatedText: '',
          languageId: '',
          userId: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      if (existingPhrase.id.isNotEmpty) {
        return existingPhrase;
      }

      // Jika tidak ada, ambil dari database
      return await _phraseService.getPhrase(id);
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }
}
