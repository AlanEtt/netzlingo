import 'package:flutter/foundation.dart';
import '../models/phrase.dart';
import '../services/phrase_service.dart';
import '../services/appwrite_service.dart';

class PhraseProvider with ChangeNotifier {
  final PhraseService _phraseService = PhraseService(AppwriteService());
  List<Phrase> _phrases = [];
  bool _isLoading = false;
  String? _error;
  DateTime? _lastLoadTime;

  List<Phrase> get phrases => _phrases;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fungsi untuk memuat semua frasa atau berdasarkan filter
  Future<void> loadPhrases(
      {String? userId,
      String? languageId,
      String? categoryId,
      bool? isFavorite,
      bool forceRefresh = false}) async {
    // Jika tidak force refresh dan data sudah dimuat dalam 30 detik terakhir, gunakan cache
    if (!forceRefresh &&
        _lastLoadTime != null &&
        DateTime.now().difference(_lastLoadTime!).inSeconds < 30 &&
        _phrases.isNotEmpty) {
      print("Menggunakan cache phrases (last load: $_lastLoadTime)");
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print("Loading phrases for user: $userId");
      _phrases = await _phraseService.getPhrases(
        userId: userId,
        languageId: languageId,
        categoryId: categoryId,
        isFavorite: isFavorite,
      );

      _lastLoadTime = DateTime.now();
      print("Loaded ${_phrases.length} phrases successfully");

      // Jika tidak ada frasa user ditemukan, coba dapatkan frasa default universal
      if (_phrases.isEmpty && userId != null && userId.isNotEmpty) {
        print("No phrases found for user $userId, trying universal phrases");
        _phrases = await _phraseService.getPublicPhrases(
          languageId: languageId,
          categoryId: categoryId,
        );
        print("Loaded ${_phrases.length} universal phrases as fallback");
      }
    } catch (e) {
      _error = "Gagal memuat frasa: ${e.toString()}";
      print("Error loading phrases: $_error");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fungsi untuk me-refresh data
  Future<void> refreshPhrases(
      {String? userId,
      String? languageId,
      String? categoryId,
      bool? isFavorite}) async {
    return loadPhrases(
        userId: userId,
        languageId: languageId,
        categoryId: categoryId,
        isFavorite: isFavorite,
        forceRefresh: true);
  }

  // Fungsi untuk menambahkan frasa baru
  Future<Phrase?> addPhrase(Phrase phrase) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print("Adding new phrase: ${phrase.originalText}");
      final newPhrase = await _phraseService.addPhrase(phrase);

      // Tambahkan frasa baru ke awal list untuk tampilan instant
      _phrases.insert(0, newPhrase);

      print("Phrase added successfully with id: ${newPhrase.id}");
      notifyListeners();
      return newPhrase;
    } catch (e) {
      _error = "Gagal menambahkan frasa: ${e.toString()}";
      print("Error adding phrase: $_error");
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fungsi untuk memperbarui frasa
  Future<bool> updatePhrase(Phrase phrase) async {
    try {
      print("Updating phrase: ${phrase.id}");
      final updatedPhrase = await _phraseService.updatePhrase(phrase);

      // Update frasa di list local
      final index = _phrases.indexWhere((p) => p.id == phrase.id);
      if (index != -1) {
        _phrases[index] = updatedPhrase;
        print("Phrase updated successfully in local list");
      } else {
        print("Phrase not found in local list, adding it");
        _phrases.add(updatedPhrase);
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = "Gagal memperbarui frasa: ${e.toString()}";
      print("Error updating phrase: $_error");
      notifyListeners();
      return false;
    }
  }

  // Fungsi untuk menghapus frasa
  Future<bool> deletePhrase(String id) async {
    try {
      print("Deleting phrase: $id");
      final success = await _phraseService.deletePhrase(id);

      if (success) {
        // Hapus frasa dari list local
        _phrases.removeWhere((p) => p.id == id);
        print("Phrase deleted successfully from local list");
        notifyListeners();
      }

      return success;
    } catch (e) {
      _error = "Gagal menghapus frasa: ${e.toString()}";
      print("Error deleting phrase: $_error");
      notifyListeners();
      return false;
    }
  }

  // Fungsi untuk memuat frasa berdasarkan pencarian
  Future<void> searchPhrases(String keyword, {String? userId}) async {
    if (keyword.isEmpty) {
      // Jika keyword kosong, kembali ke list semua frasa
      return loadPhrases(userId: userId);
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print("Searching phrases with keyword: '$keyword'");
      _phrases = await _phraseService.searchPhrases(keyword, userId);
      print("Found ${_phrases.length} phrases matching keyword");
    } catch (e) {
      _error = "Gagal mencari frasa: ${e.toString()}";
      print("Error searching phrases: $_error");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fungsi untuk toggle favorit
  Future<bool> toggleFavorite(Phrase phrase) async {
    try {
      print("Toggling favorite for phrase: ${phrase.id}");
      final updatedPhrase = await _phraseService.toggleFavorite(phrase);

      final index = _phrases.indexWhere((p) => p.id == phrase.id);
      if (index != -1) {
        _phrases[index] = updatedPhrase;
        print("Phrase favorite status toggled successfully in local list");
        notifyListeners();
      }

      return true;
    } catch (e) {
      _error = "Gagal mengubah status favorit: ${e.toString()}";
      print("Error toggling favorite: $_error");
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
      print("Fetching phrase by id: $id from database");
      return await _phraseService.getPhrase(id);
    } catch (e) {
      _error = "Gagal mendapatkan frasa: ${e.toString()}";
      print("Error getting phrase by ID: $_error");
      return null;
    }
  }

  // Hapus error message
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
