import 'package:flutter/foundation.dart';
import 'package:appwrite/models.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../services/appwrite_service.dart';

class AuthProvider with ChangeNotifier {
  final UserService _userService = UserService(AppwriteService());

  User? _currentAccount;
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;

  User? get currentAccount => _currentAccount;
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;
  String get userId => _currentUser?.id ?? '';

  // Inisialisasi provider
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Cek apakah user sudah login
      _currentAccount = await _userService.getCurrentUser();

      if (_currentAccount != null) {
        _isAuthenticated = true;
        // Dapatkan data user dari database
        _currentUser = await _userService.getUserModel(_currentAccount!.$id);
      }
    } catch (e) {
      _error = null; // Tidak perlu error karena ini normal jika belum login
      _isAuthenticated = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Login
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _userService.login(email, password);

      // Dapatkan data user setelah login
      _currentAccount = await _userService.getCurrentUser();
      _currentUser = await _userService.getUserModel(_currentAccount!.$id);
      _isAuthenticated = true;

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Signup
  Future<bool> signup(String name, String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Daftar akun baru
      final user = await _userService.signup(email, password, name);

      // Login otomatis setelah signup
      await _userService.login(email, password);

      // Dapatkan data user setelah login
      _currentAccount = await _userService.getCurrentUser();
      _currentUser = await _userService.getUserModel(_currentAccount!.$id);
      _isAuthenticated = true;

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _userService.logout();

      _currentAccount = null;
      _currentUser = null;
      _isAuthenticated = false;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _userService.resetPassword(email);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update profile
  Future<bool> updateProfile({String? name, String? email}) async {
    if (!_isAuthenticated) {
      _error = 'Anda harus login terlebih dahulu';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Update profile
      final updatedAccount = await _userService.updateProfile(
        name: name,
        email: email,
      );

      // Update state
      _currentAccount = updatedAccount;
      _currentUser = await _userService.getUserModel(_currentAccount!.$id);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update user settings
  Future<bool> updateUserSettings({
    int? dailyGoal,
    String? preferredLanguage,
  }) async {
    if (!_isAuthenticated || _currentUser == null) {
      _error = 'Anda harus login terlebih dahulu';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Update settings
      final updatedUser = await _userService.updateUserSettings(
        userId: _currentUser!.id,
        dailyGoal: dailyGoal,
        preferredLanguage: preferredLanguage,
      );

      // Update state
      _currentUser = updatedUser;

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Reset error
  void resetError() {
    _error = null;
    notifyListeners();
  }

  // Refresh session untuk mengatasi user_unauthorized
  Future<bool> refreshSession() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      print('Attempting to refresh user session');
      
      // Dapatkan data user yang fresh
      _currentAccount = await _userService.getCurrentUser();
      
      if (_currentAccount != null) {
        print('Session refreshed successfully');
        _isAuthenticated = true;
        
        // Refresh data user model juga
        try {
          _currentUser = await _userService.getUserModel(_currentAccount!.$id);
        } catch (userModelError) {
          print('Error refreshing user model: $userModelError');
          // Tetap lanjutkan meski gagal dapat user model
        }
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        throw Exception('Failed to refresh session - user is null');
      }
    } catch (e) {
      print('Error refreshing session: $e');
      _error = 'Gagal memperbarui sesi: $e';
      _isAuthenticated = false;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
