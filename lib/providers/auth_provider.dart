import 'package:flutter/foundation.dart';
import 'package:appwrite/models.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../services/appwrite_service.dart';
import '../services/phrase_service.dart'; // Tambahkan import

class AuthProvider with ChangeNotifier {
  final UserService _userService = UserService(AppwriteService());
  final PhraseService _phraseService =
      PhraseService(AppwriteService()); // Tambahkan PhraseService

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

        // Buat frasa default untuk pengguna jika belum ada
        await _createDefaultPhrasesIfNeeded(_currentAccount!.$id);
      }
    } catch (e) {
      _error = null; // Tidak perlu error karena ini normal jika belum login
      _isAuthenticated = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fungsi untuk membuat frasa default jika belum ada
  Future<void> _createDefaultPhrasesIfNeeded(String userId) async {
    try {
      print("Creating default phrases for user: $userId if needed");
      await _phraseService.createUserDefaultPhrases(userId);
    } catch (e) {
      print("Error creating default phrases for user $userId: $e");
      // Tidak perlu throw error ke user karena ini hanya fitur tambahan
    }
  }

  // Login
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('Mencoba login untuk email: $email');

      // Cek jika sudah ada sesi aktif, hapus dulu
      try {
        // Coba dapatkan sesi saat ini, jika ada
        final currentSessions = await _userService.getActiveSessions();

        if (currentSessions.isNotEmpty) {
          print(
              'Sesi aktif ditemukan: ${currentSessions.length}. Menghapus semua sesi...');
          // Hapus semua sesi yang ada untuk mencegah error user_session_already_exists
          await _userService.logoutAll();
          // Tunggu sebentar untuk memastikan sesi benar-benar terhapus
          await Future.delayed(const Duration(milliseconds: 500));
        }
      } catch (sessionError) {
        // Abaikan error saat mencoba mendapatkan sesi
        print('Error saat mencoba mendapatkan sesi aktif: $sessionError');
      }

      // Sekarang coba login
      await _userService.login(email, password);

      // Dapatkan data user setelah login
      _currentAccount = await _userService.getCurrentUser();
      _currentUser = await _userService.getUserModel(_currentAccount!.$id);
      _isAuthenticated = true;

      // Buat frasa default untuk pengguna jika belum ada
      try {
        await _createDefaultPhrasesIfNeeded(_currentAccount!.$id);
      } catch (phraseError) {
        // Jika gagal membuat frasa default, jangan gagalkan login
        print("Error creating default phrases: $phraseError");
        // Terus login meski gagal membuat frasa default
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      // Tangani berbagai jenis error
      if (e.toString().contains('user_session_already_exists')) {
        _error =
            "Anda sudah login di perangkat lain. Silakan logout terlebih dahulu.";
      } else if (e.toString().contains('user_invalid_credentials')) {
        _error = "Email atau password salah. Silakan coba lagi.";
      } else if (e.toString().contains('general_unauthorized')) {
        _error = "Akses tidak diizinkan. Cek email dan password Anda.";
      } else if (e.toString().contains('document_already_exists')) {
        // Jika error adalah document_already_exists, coba login lagi tanpa membuat frasa
        try {
          print("Mencoba login ulang tanpa membuat frasa default...");
          // Logout dulu untuk memastikan
          await _userService.logoutAll();
          await Future.delayed(const Duration(milliseconds: 500));

          // Login lagi
          await _userService.login(email, password);

          // Ambil data user tanpa membuat frasa default
          _currentAccount = await _userService.getCurrentUser();
          _currentUser = await _userService.getUserModel(_currentAccount!.$id);
          _isAuthenticated = true;

          _isLoading = false;
          notifyListeners();
          return true;
        } catch (retryError) {
          _error = "Login gagal: ${retryError.toString()}";
        }
      } else {
        _error = "Login gagal: ${e.toString()}";
      }

      print("Login error: $_error");
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
      print("User berhasil dibuat dengan ID: ${user.$id}");

      // Tunggu sebentar sebelum melakukan login untuk menghindari konflik sesi
      await Future.delayed(const Duration(milliseconds: 300));

      // Login manual setelah signup
      try {
        await _userService.login(email, password);

        // Dapatkan data user setelah login
        _currentAccount = await _userService.getCurrentUser();
        _currentUser = await _userService.getUserModel(_currentAccount!.$id);
        _isAuthenticated = true;

        // Buat frasa default untuk pengguna baru (ini penting untuk user baru)
        print(
            "Membuat frasa default untuk user baru dengan ID: ${_currentAccount!.$id}");
        await _createDefaultPhrasesIfNeeded(_currentAccount!.$id);

        _isLoading = false;
        notifyListeners();
        return true;
      } catch (loginError) {
        print("Error during post-signup login: $loginError");
        _error =
            "Registrasi berhasil tetapi gagal masuk otomatis. Silakan login manual.";
        _isLoading = false;
        notifyListeners();
        // Meskipun login gagal, registrasi berhasil, jadi tetap return true
        return true;
      }
    } catch (e) {
      if (e.toString().contains('user_session_already_exists')) {
        _error =
            "Email sudah terdaftar dan sedang aktif. Silakan logout dari perangkat lain atau gunakan email lain.";
      } else if (e.toString().contains('email already exists')) {
        _error =
            "Email sudah terdaftar. Silakan gunakan email lain atau login.";
      } else {
        _error = "Registrasi gagal: ${e.toString()}";
      }
      print("Signup error: $_error");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    _isLoading = true;
    print('AuthProvider: Logout process started...');
    notifyListeners();

    try {
      print('AuthProvider: Calling UserService.logout()...');
      await _userService.logout();
      print('AuthProvider: UserService.logout() completed successfully');

      _currentAccount = null;
      _currentUser = null;
      _isAuthenticated = false;
      print('AuthProvider: User state reset to logged out');
    } catch (e) {
      print('AuthProvider: Error during logout: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      print('AuthProvider: Logout process completed, notifying listeners');
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

  // Memaksa reset state login (untuk kondisi darurat saat logout gagal)
  void forceResetState() {
    print('AuthProvider: Forcing state reset to logged out');
    _currentAccount = null;
    _currentUser = null;
    _isAuthenticated = false;
    _error = null;
    _isLoading = false;
    notifyListeners();
    print('AuthProvider: State has been forcibly reset');
  }

  // Menghapus semua sesi aktif
  Future<void> clearAllSessions() async {
    try {
      print('Attempting to clear all active sessions');
      await _userService.logoutAll();

      // Reset state
      _currentAccount = null;
      _currentUser = null;
      _isAuthenticated = false;
      _error = null;

      notifyListeners();
      print('All sessions cleared successfully');
    } catch (e) {
      print('Error clearing sessions: $e');
      rethrow;
    }
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
