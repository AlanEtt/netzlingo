import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/tag_provider.dart';
import '../../providers/phrase_provider.dart'; // Tambahkan ini
import '../phrase_management/phrase_list_screen.dart';
import '../study/study_screen.dart';
import '../statistics/statistics_screen.dart';
import '../settings/settings_screen.dart';
import '../../providers/auth_provider.dart';
import '../../utils/async_helper.dart';
import 'dart:async'; // Untuk throttle

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _error;
  DateTime _lastRefreshTime =
      DateTime.now().subtract(const Duration(minutes: 5));
  bool _isRefreshing = false;

  // Simpan screens sebagai list statis untuk menghindari rebuild berlebihan
  final List<Widget> _screens = [
    const PhraseListScreen(),
    const StudyScreen(),
    const StatisticsScreen(),
    const SettingsScreen(),
  ];

  // PERBAIKAN: Perbaiki _getScreenForIndex agar tidak memanggil refresh pada build
  Widget _getScreenForIndex(int index) {
    return _screens[index];
  }

  @override
  void initState() {
    super.initState();
    // Jadwalkan refresh beberapa saat setelah widget dibuat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _throttledRefresh();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Inisialisasi data dasar
    if (!_isInitialized) {
      _initializeProviders();
      _isInitialized = true;
    }
  }

  // PERBAIKAN: Tambahkan throttle untuk refresh
  void _throttledRefresh() {
    final now = DateTime.now();
    final difference = now.difference(_lastRefreshTime);

    // Hanya refresh jika sudah berlalu lebih dari 30 detik sejak refresh terakhir
    // Dan tidak sedang dalam proses refresh
    if (difference.inSeconds > 30 && !_isRefreshing) {
      _refreshUserData();
      _lastRefreshTime = now;
    }
  }

  // PERBAIKAN: Gunakan AsyncHelper untuk mengelola state dengan aman
  Future<void> _refreshUserData() async {
    if (_isRefreshing) return;
    _isRefreshing = true;

    try {
      AsyncHelper.runWithMounted(
        state: this,
        operation: () async {
          setState(() {
            _isLoading = true;
            _error = null;
          });

          final authProvider =
              Provider.of<AuthProvider>(context, listen: false);

          // Cek apakah user masih authenticated
          if (!authProvider.isAuthenticated || authProvider.userId.isEmpty) {
            // Coba refresh session
            await authProvider.refreshSession();
            print(
                'Session refreshed, authenticated: ${authProvider.isAuthenticated}, userId: ${authProvider.userId}');
          }

          // Jika masih authenticated, refresh semua data
          if (authProvider.isAuthenticated && authProvider.userId.isNotEmpty) {
            final userId = authProvider.userId;

            // Refresh settings
            final settingsProvider =
                Provider.of<SettingsProvider>(context, listen: false);
            await settingsProvider.loadSettings(userId);

            // Refresh language, category, dan tag data
            final languageProvider =
                Provider.of<LanguageProvider>(context, listen: false);
            final categoryProvider =
                Provider.of<CategoryProvider>(context, listen: false);
            final tagProvider =
                Provider.of<TagProvider>(context, listen: false);
            final phraseProvider =
                Provider.of<PhraseProvider>(context, listen: false);

            await languageProvider.loadLanguages();
            await categoryProvider.loadCategories(userId: userId);
            await tagProvider.loadTags(userId);
            await phraseProvider.loadPhrases(userId: userId);

            print('All user data refreshed for userId: $userId');
          }

          return null;
        },
        onComplete: (_) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _isRefreshing = false;
            });
          }
        },
        onError: (e) {
          print('Error refreshing user data: $e');
          if (mounted) {
            setState(() {
              _error = e.toString();
              _isLoading = false;
              _isRefreshing = false;
            });
          }
        },
      );
    } catch (e) {
      print('Error in _refreshUserData outer block: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _initializeProviders() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Memuat pengaturan dan bahasa dari database
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // PERBAIKAN: Pastikan session user valid
      await authProvider.refreshSession();

      final userId = authProvider.userId;
      print(
          'Initializing providers for userId: $userId, authenticated: ${authProvider.isAuthenticated}');

      if (userId.isNotEmpty) {
        final settingsProvider =
            Provider.of<SettingsProvider>(context, listen: false);
        final languageProvider =
            Provider.of<LanguageProvider>(context, listen: false);
        final categoryProvider =
            Provider.of<CategoryProvider>(context, listen: false);
        final tagProvider = Provider.of<TagProvider>(context, listen: false);
        final phraseProvider =
            Provider.of<PhraseProvider>(context, listen: false);

        await settingsProvider.loadSettings(userId);
        await languageProvider.loadLanguages();
        await categoryProvider.loadCategories(userId: userId);
        await tagProvider.loadTags(userId);
        await phraseProvider.loadPhrases(userId: userId);

        print('All providers initialized successfully');
      } else {
        print('No userId available, skipping provider initialization');
      }
    } catch (e) {
      print('Error initializing providers: $e');
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // PERBAIKAN: Tambahkan penangan error dan loading state
      body: _isLoading && !_isInitialized
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text('Error: $_error', textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _refreshUserData,
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              :
              // Tampilkan screen sesuai tab yang dipilih
              _getScreenForIndex(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          // PERBAIKAN: Hanya refresh data jika pindah ke tab baru
          if (_selectedIndex != index) {
            _throttledRefresh();
          }
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.translate), label: 'Frasa'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Belajar'),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Statistik',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Pengaturan',
          ),
        ],
      ),
    );
  }
}
