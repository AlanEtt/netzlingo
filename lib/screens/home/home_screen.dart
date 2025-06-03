import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/tag_provider.dart';
import '../phrase_management/phrase_list_screen.dart';
import '../study/study_screen.dart';
import '../statistics/statistics_screen.dart';
import '../settings/settings_screen.dart';
import '../../providers/auth_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isInitialized = false;

  final List<Widget> _screens = [
    const PhraseManagementScreen(),
    const StudyScreen(),
    const StatisticsScreen(),
    const SettingsScreen(),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Inisialisasi data dasar
    if (!_isInitialized) {
      _initializeProviders();
      _isInitialized = true;
    }
  }

  Future<void> _initializeProviders() async {
    try {
      // Memuat pengaturan dan bahasa dari database
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userId;

      if (userId.isNotEmpty) {
        final settingsProvider =
            Provider.of<SettingsProvider>(context, listen: false);
        final languageProvider =
            Provider.of<LanguageProvider>(context, listen: false);
        final categoryProvider =
            Provider.of<CategoryProvider>(context, listen: false);
        final tagProvider = Provider.of<TagProvider>(context, listen: false);

        await settingsProvider.loadSettings(userId);
        await languageProvider.loadLanguages();
        await categoryProvider.loadCategories(userId: userId);
        await tagProvider.loadTags(userId);
      }
    } catch (e) {
      print('Error initializing providers: $e');
      // Tampilkan pesan error jika diperlukan
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
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
