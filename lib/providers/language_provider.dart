import 'package:flutter/foundation.dart';
import '../models/language.dart';
import '../services/language_service.dart';
import '../services/appwrite_service.dart';

class LanguageProvider with ChangeNotifier {
  final LanguageService _languageService = LanguageService(AppwriteService());
  List<Language> _languages = [];
  bool _isLoading = false;
  String? _error;

  List<Language> get languages => _languages;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadLanguages() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _languages = await _languageService.getLanguages();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      print('Error loading languages: $e');
    }
  }

  Future<Language?> getLanguageByCode(String code) async {
    try {
      // Cek dulu di list yang sudah ada
      final existingLanguage = _languages.firstWhere(
        (language) => language.code == code,
        orElse: () => Language(
          id: '',
          name: '',
          code: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      if (existingLanguage.id.isNotEmpty) {
        return existingLanguage;
      }

      // Jika tidak ada, ambil dari database
      return await _languageService.getLanguageByCode(code);
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }

  Future<Language?> getLanguageById(String id) async {
    try {
      // Cek dulu di list yang sudah ada
      final existingLanguage = _languages.firstWhere(
        (language) => language.id == id,
        orElse: () => Language(
          id: '',
          name: '',
          code: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      if (existingLanguage.id.isNotEmpty) {
        return existingLanguage;
      }

      // Jika tidak ada, ambil dari database
      return await _languageService.getLanguageById(id);
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }

  // Mendapatkan stream perubahan bahasa
  Stream<List<Language>> getLanguagesStream() {
    try {
      final stream = _languageService.subscribeToLanguages();
      return stream.map((event) {
        // Reload languages setiap kali ada perubahan
        loadLanguages();
        return _languages;
      });
    } catch (e) {
      _error = e.toString();
      return Stream.value(_languages);
    }
  }
}
