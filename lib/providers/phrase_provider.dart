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
    // PERBAIKAN: Validasi userId untuk keamanan
    if (userId == null || userId.isEmpty) {
      print("Warning: No valid userId provided for loadPhrases");
      _error = "User ID tidak valid, hanya frasa publik yang akan ditampilkan";
      // Tetap lanjutkan dengan userId null, tapi hanya akan mendapat frasa universal
    }

    // Jika tidak force refresh dan data sudah dimuat dalam 30 detik terakhir, gunakan cache
    if (!forceRefresh &&
        _lastLoadTime != null &&
        DateTime.now().difference(_lastLoadTime!).inSeconds < 30 &&
        _phrases.isNotEmpty) {
      print("Menggunakan cache phrases (last load: $_lastLoadTime)");

      // Filter berdasarkan favorit jika parameter tersedia
      if (isFavorite != null) {
        print("Filtering cached phrases by favorite status: $isFavorite");

        // PERBAIKAN: Benar-benar filter data yang ada di cache
        if (isFavorite == true) {
          // Filter hanya frasa favorit
          List<Phrase> filteredPhrases = _phrases
              .where((phrase) =>
                  phrase.isFavorite &&
                  (phrase.userId == userId || phrase.userId == 'universal'))
              .toList();

          _phrases = filteredPhrases;
          print("Filtered to ${_phrases.length} favorite phrases from cache");
        } else {
          // Jika isFavorite false, muat ulang semua frasa
          forceRefresh = true;
        }
      }

      notifyListeners();

      if (!forceRefresh) {
        return;
      }
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print("Loading phrases for user: $userId, isFavorite: $isFavorite");

      // Ambil frasa dari server dengan filter yang sesuai
      _phrases = await _phraseService.getPhrases(
        userId: userId,
        languageId: languageId,
        categoryId: categoryId,
        isFavorite: isFavorite,
      );

      _lastLoadTime = DateTime.now();
      print("Loaded ${_phrases.length} phrases successfully");

      // Jika filter favorit aktif dan tidak ada frasa ditemukan, jangan gunakan frasa universal
      if (isFavorite == true && _phrases.isEmpty) {
        print("No favorite phrases found for user $userId");
      }
      // Jika tidak ada frasa user ditemukan dan bukan filter favorit, coba dapatkan frasa default universal
      else if (_phrases.isEmpty &&
          userId != null &&
          userId.isNotEmpty &&
          isFavorite != true) {
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

      // Perbarui UI secara optimistik (tampilkan perubahan segera)
      final index = _phrases.indexWhere((p) => p.id == phrase.id);
      if (index != -1) {
        // Buat salinan frasa dengan status favorit dibalik
        final updatedLocalPhrase =
            phrase.copyWith(isFavorite: !phrase.isFavorite);
        _phrases[index] = updatedLocalPhrase;
        notifyListeners(); // Update UI segera
      }

      // Kirim perubahan ke server
      final updatedPhrase = await _phraseService.toggleFavorite(phrase);

      // Update list lokal dengan data dari server (lebih akurat)
      final serverIndex = _phrases.indexWhere((p) => p.id == updatedPhrase.id);
      if (serverIndex != -1) {
        _phrases[serverIndex] = updatedPhrase;
        print("Phrase favorite status toggled successfully in local list");
        notifyListeners();
      }

      return true;
    } catch (e) {
      _error = "Gagal mengubah status favorit: ${e.toString()}";
      print("Error toggling favorite: $_error");

      // Kembalikan status favorit ke aslinya jika gagal
      final index = _phrases.indexWhere((p) => p.id == phrase.id);
      if (index != -1) {
        _phrases[index] = phrase; // Kembalikan ke status asli
        notifyListeners();
      }

      notifyListeners();
      return false;
    }
  }

  // Filter frasa favorit
  List<Phrase> getFavoritePhrases({String? userId}) {
    // Filter berdasarkan favorit dan user ID jika disediakan
    if (userId != null && userId.isNotEmpty) {
      return _phrases
          .where((phrase) => phrase.isFavorite && phrase.userId == userId)
          .toList();
    } else {
      return _phrases.where((phrase) => phrase.isFavorite).toList();
    }
  }

  // PERBAIKAN: Set frasa yang sudah difilter secara manual
  Future<void> setFilteredPhrases(List<Phrase> filteredPhrases) async {
    _phrases = filteredPhrases;
    notifyListeners();
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

  // PERBAIKAN: Hapus frasa yang bukan milik user dari list
  void removeNonUserPhrase(String phraseId) {
    // Hapus frasa dengan ID tertentu dari daftar lokal
    _phrases.removeWhere((phrase) => phrase.id == phraseId);
    print("Removed non-user phrase with ID $phraseId from local list");
    notifyListeners(); // Refresh UI
  }

  // Hapus error message
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
