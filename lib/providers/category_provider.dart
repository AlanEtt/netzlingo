import 'package:flutter/foundation.dart' hide Category;
import '../models/category.dart';
import '../services/category_service.dart';
import '../services/appwrite_service.dart';

class CategoryProvider with ChangeNotifier {
  final CategoryService _categoryService = CategoryService(AppwriteService());
  List<Category> _categories = [];
  bool _isLoading = false;
  String? _error;

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Memuat semua kategori atau berdasarkan bahasa
  Future<void> loadCategories(
      {required String userId, String? languageId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _categories = await _categoryService.getCategories(
        userId: userId,
        languageId: languageId,
      );

      // Urutkan kategori berdasarkan nama
      _categories.sort((a, b) => a.name.compareTo(b.name));
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Menambah kategori baru
  Future<Category?> addCategory(Category category) async {
    try {
      final newCategory = await _categoryService.addCategory(category);
      _categories.add(newCategory);

      // Urutkan kategori berdasarkan nama
      _categories.sort((a, b) => a.name.compareTo(b.name));
      notifyListeners();

      return newCategory;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Memperbarui kategori
  Future<bool> updateCategory(Category category) async {
    try {
      final updatedCategory = await _categoryService.updateCategory(category);

      final index = _categories.indexWhere((c) => c.id == category.id);
      if (index != -1) {
        _categories[index] = updatedCategory;
        // Urutkan kategori berdasarkan nama
        _categories.sort((a, b) => a.name.compareTo(b.name));
        notifyListeners();
      }

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Menghapus kategori
  Future<bool> deleteCategory(String id) async {
    try {
      await _categoryService.deleteCategory(id);

      _categories.removeWhere((c) => c.id == id);
      notifyListeners();

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Mendapatkan kategori berdasarkan ID
  Future<Category?> getCategoryById(String id) async {
    try {
      // Cek dulu di list yang sudah ada
      final existingCategory = _categories.firstWhere(
        (category) => category.id == id,
        orElse: () => Category(
          id: '',
          name: '',
          userId: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      if (existingCategory.id.isNotEmpty) {
        return existingCategory;
      }

      // Jika tidak ada, ambil dari database
      return await _categoryService.getCategory(id);
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
