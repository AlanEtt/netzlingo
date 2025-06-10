import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'providers/language_provider.dart';
import 'providers/phrase_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/study_provider.dart';
import 'providers/category_provider.dart';
import 'providers/tag_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'utils/app_theme.dart';
import 'services/appwrite_service.dart';
import 'services/phrase_service.dart';
import 'services/settings_service.dart';
import 'providers/subscription_provider.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi AppWrite
  final appwriteService = AppwriteService();
  appwriteService.initialize();

  // Inisialisasi data universal untuk aksesibilitas publik
  try {
    print("Initializing universal data");
    // 1. Inisialisasi frasa universal
    final phraseService = PhraseService(appwriteService);
    await phraseService.createUniversalPublicPhrases();

    // 2. Inisialisasi pengaturan universal
    final settingsService = SettingsService(appwriteService);
    await settingsService.getOrCreateUniversalSettings();

    print("Universal data initialized successfully");
  } catch (e) {
    print("Error initializing universal data: $e");
    // Tetap lanjutkan aplikasi meski gagal inisialisasi data universal
  }

  // Jalankan aplikasi
  runApp(const NetzLingoApp());
}

class NetzLingoApp extends StatefulWidget {
  const NetzLingoApp({Key? key}) : super(key: key);

  @override
  State<NetzLingoApp> createState() => _NetzLingoAppState();
}

class _NetzLingoAppState extends State<NetzLingoApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => TagProvider()),
        ChangeNotifierProvider(create: (_) => PhraseProvider()),
        ChangeNotifierProvider(create: (_) => StudyProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
      ],
      child: Consumer2<AuthProvider, SettingsProvider>(
        builder: (context, authProvider, settingsProvider, child) {
          // Default ke light theme jika terjadi error
          bool isDarkMode = false;

          try {
            // Gunakan tema berdasarkan pengaturan user atau default (light theme)
            isDarkMode = authProvider.isAuthenticated &&
                    settingsProvider.settings != null
                ? settingsProvider.isDarkMode
                : false;
            print('Theme mode: ${isDarkMode ? 'dark' : 'light'}');
          } catch (e) {
            print('Error getting theme mode: $e');
          }

          final themeData =
              isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme;

          return MaterialApp(
            title: 'NetzLingo',
            theme: themeData,
            darkTheme: AppTheme.darkTheme,
            themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('id', 'ID'), // Indonesian
              Locale('en', 'US'), // English
            ],
            home: const SplashScreen(),
            routes: {
              '/login': (context) => const LoginScreen(),
              '/home': (context) => const HomeScreen(),
            },
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

// Wrapper untuk cek status autentikasi
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();

    // Cek status autentikasi
    _checkAuthStatus();

    // Tampilkan pesan khusus jika dalam mode web
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _showPlatformLimitationDialog(context);
        });
      });
    }
  }

  Future<void> _checkAuthStatus() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.initialize();

      // Jika user sudah login, muat pengaturan
      if (authProvider.isAuthenticated && authProvider.userId.isNotEmpty) {
        print(
            'User authenticated - loading settings for user: ${authProvider.userId}');

        try {
          // Muat pengaturan
          final settingsProvider =
              Provider.of<SettingsProvider>(context, listen: false);
          await settingsProvider.loadSettings(authProvider.userId);
          print('Settings loaded successfully');
        } catch (settingsError) {
          print('Error loading settings: $settingsError');
          // Lanjutkan meskipun terjadi error pada settings
        }

        try {
          // Muat juga data langganan
          final subscriptionProvider =
              Provider.of<SubscriptionProvider>(context, listen: false);
          await subscriptionProvider.loadSubscriptions(authProvider.userId);
          print('Subscription loaded successfully');
        } catch (subscriptionError) {
          print('Error loading subscription: $subscriptionError');
          // Lanjutkan meskipun terjadi error pada subscription
        }
      }
    } catch (e) {
      print('Error in _checkAuthStatus: $e');

      // Coba tangani error sesi yang mungkin terjadi
      if (e.toString().contains('user_session_already_exists')) {
        try {
          print('Mencoba menghapus sesi yang bermasalah...');
          final authProvider =
              Provider.of<AuthProvider>(context, listen: false);
          await authProvider.clearAllSessions();
          _error = 'Sesi sebelumnya telah dihapus. Silakan login kembali.';
        } catch (clearError) {
          print('Gagal menghapus sesi: $clearError');
          _error =
              'Terjadi masalah pada sesi aplikasi. Restart aplikasi dan coba lagi.';
        }
      } else {
        _error = e.toString();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showPlatformLimitationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Versi Web Terbatas'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Anda menggunakan versi web aplikasi NetzLingo yang memiliki beberapa keterbatasan:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text('• Penyimpanan data lokal terbatas'),
              Text('• Beberapa fitur mungkin tidak berfungsi dengan baik'),
              Text('• Performa mungkin lebih lambat'),
              SizedBox(height: 12),
              Text(
                'Untuk pengalaman terbaik, silakan unduh dan pasang aplikasi NetzLingo di perangkat Android atau iOS Anda.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Mengerti'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Memuat Aplikasi...', style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Terjadi kesalahan saat memuat aplikasi',
                  style: TextStyle(fontSize: 18)),
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _checkAuthStatus(),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    // Gunakan Consumer untuk memastikan UI diperbarui ketika status autentikasi berubah
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        print("AuthWrapper: isAuthenticated = ${authProvider.isAuthenticated}");
        return authProvider.isAuthenticated
            ? const HomeScreen()
            : const LoginScreen();
      },
    );
  }
}
