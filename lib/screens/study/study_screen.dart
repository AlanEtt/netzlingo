import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/phrase.dart';
import '../../providers/study_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/session_limit_service.dart';
import '../../services/tts_service.dart';
import 'flashcard_screen.dart';
import 'quiz_screen.dart';
import 'typing_screen.dart';
import 'spaced_repetition_screen.dart';

enum StudyMode { flashcard, quiz, typing, spacedRepetition }

class StudyScreen extends StatefulWidget {
  const StudyScreen({Key? key}) : super(key: key);

  @override
  StudyScreenState createState() => StudyScreenState();
}

class StudyScreenState extends State<StudyScreen> {
  final SessionLimitService _sessionLimitService = SessionLimitService();
  bool _isLoading = false;
  int _remainingSessions = 0;
  String? _selectedLanguageId;
  String? _selectedCategoryId;
  int _phraseCount = 10;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRemainingSessionCount();

    // Inisialisasi provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProviders();
    });
  }

  void _initializeProviders() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userId;

      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Pendekatan universal - semua jenis akun bisa mengakses
      await _initializeUniversalAccess(userId.isEmpty ? 'guest' : userId);
    } catch (e) {
      print('Error in _initializeProviders: $e');
      if (mounted) {
        setState(() {
          _error = 'Terjadi kesalahan: $e';
          _isLoading = false;
        });
      }
    }
  }

  // Pendekatan akses universal yang bekerja untuk semua jenis akun
  Future<void> _initializeUniversalAccess(String userId) async {
    try {
      print("Initializing with universal access approach for user: $userId");

      // Inisialisasi provider dengan userId (guest atau user asli)
      try {
        await Provider.of<StudyProvider>(context, listen: false)
            .initialize(userId);
      } catch (e) {
        print('Error initializing StudyProvider: $e');
        // Jika gagal dengan user ID asli, coba dengan 'universal'
        await Provider.of<StudyProvider>(context, listen: false)
            .initialize('universal');
      }

      // Load bahasa
      try {
        await Provider.of<LanguageProvider>(context, listen: false)
            .loadLanguages();
      } catch (e) {
        print('Error loading languages: $e');
        // Langsung lanjutkan meski gagal
      }

      // Load kategori
      try {
        await Provider.of<CategoryProvider>(context, listen: false)
            .loadCategories(userId: userId);
      } catch (e) {
        print('Error loading categories for $userId: $e');
        // Coba dengan kategori default/universal
        try {
          await Provider.of<CategoryProvider>(context, listen: false)
              .loadCategories(userId: 'universal');
        } catch (innerError) {
          print('Error loading universal categories: $innerError');
          // Lanjutkan meski gagal
        }
      }
    } catch (e) {
      print('Error in universal access initialization: $e');
      setState(() {
        _error = 'Gagal memuat data belajar: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadRemainingSessionCount() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final subscriptionProvider = Provider.of<SubscriptionProvider>(
        context,
        listen: false,
      );
      final remainingSessions = await _sessionLimitService
          .getRemainingSessionsToday(subscriptionProvider.isPremium);

      setState(() {
        _remainingSessions = remainingSessions;
      });
    } catch (e) {
      print('Error loading session count: $e');
      setState(() {
        _error = 'Gagal memuat sesi tersisa: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool> _canStartNewSession() async {
    try {
      final subscriptionProvider = Provider.of<SubscriptionProvider>(
        context,
        listen: false,
      );
      return _sessionLimitService
          .canStartNewSession(subscriptionProvider.isPremium);
    } catch (e) {
      print('Error checking session: $e');
      _showErrorSnackbar('Gagal memeriksa sesi: $e');
      return false;
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _startStudySession(StudyMode mode) async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final studyProvider = Provider.of<StudyProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userId;

      // Gunakan pendekatan universal untuk semua jenis akun
      bool started = false;
      String? errorMessage;

      try {
        // Pendekatan 1: Coba langsung dengan userId
        if (userId.isNotEmpty) {
          print('Trying to start session with user ID: $userId');
          started = await studyProvider.startNewSession(
            sessionType: mode.toString(),
            languageId: _selectedLanguageId,
            categoryId: _selectedCategoryId,
            phraseCount: _phraseCount,
          );
        } else {
          // Jika tidak ada userId, langsung mulai sesi dengan mode universal
          print('User not logged in, using universal mode');
          _showUniversalStudyModeDialog(mode);
          setState(() => _isLoading = false);
          return;
        }
      } catch (e) {
        print('Error starting session with standard approach: $e');
        errorMessage = e.toString();

        // Pendekatan 2: Jika gagal karena unauthorized, coba dengan universal mode
        if (errorMessage.contains('user_unauthorized') ||
            errorMessage.contains('401') ||
            errorMessage.contains('permission denied')) {
          print('Permission issue detected, using universal mode');
          _showUniversalStudyModeDialog(mode);
          setState(() => _isLoading = false);
          return;
        }
      }

      setState(() => _isLoading = false);

      if (!started) {
        String displayError =
            studyProvider.error ?? errorMessage ?? 'Gagal memulai sesi belajar';

        // Tampilkan dialog untuk universal mode
        if (displayError.contains('user_unauthorized') ||
            displayError.contains('401') ||
            displayError.contains('permission')) {
          _showUniversalStudyModeDialog(mode);
        } else {
          _showErrorSnackbar(displayError);
        }
        return;
      }

      if (studyProvider.sessionPhrases.isEmpty) {
        _showErrorSnackbar('Tidak ada frasa yang tersedia untuk belajar');
        return;
      }

      // Navigasi ke screen sesuai mode yang dipilih
      Widget screenToShow;
      switch (mode) {
        case StudyMode.flashcard:
          screenToShow = const FlashcardScreen();
          break;
        case StudyMode.quiz:
          screenToShow = const QuizScreen();
          break;
        case StudyMode.typing:
          screenToShow = const TypingScreen();
          break;
        case StudyMode.spacedRepetition:
          screenToShow = const SpacedRepetitionScreen();
          break;
      }

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => screenToShow),
      ).then((_) {
        // Refresh data setelah kembali dari sesi belajar
        _loadRemainingSessionCount();
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error starting study session: $e');
      _showErrorSnackbar('Terjadi kesalahan: $e');
    }
  }

  // Dialog untuk mode pembelajaran universal
  void _showUniversalStudyModeDialog(StudyMode mode) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Mode Pembelajaran Universal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Anda akan mengakses mode pembelajaran universal yang tersedia untuk semua pengguna. Mode ini menggunakan frasa publik yang telah disediakan oleh sistem.',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: const Text(
                      'Mode ini tidak memerlukan login dan tidak menyimpan progres belajar Anda secara permanen.',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              setState(() => _isLoading = true);

              // Gunakan ID universal dan mulai sesi
              final studyProvider =
                  Provider.of<StudyProvider>(context, listen: false);

              try {
                // Inisialisasi dengan 'universal' sebagai userId
                await studyProvider.initialize('universal');

                // Memulai sesi belajar
                final started = await studyProvider.startNewSession(
                  sessionType: mode.toString(),
                  languageId: _selectedLanguageId,
                  categoryId: _selectedCategoryId,
                  phraseCount: _phraseCount,
                );

                setState(() => _isLoading = false);

                if (started) {
                  // Navigasi ke screen sesuai mode yang dipilih
                  Widget screenToShow;
                  switch (mode) {
                    case StudyMode.flashcard:
                      screenToShow = const FlashcardScreen();
                      break;
                    case StudyMode.quiz:
                      screenToShow = const QuizScreen();
                      break;
                    case StudyMode.typing:
                      screenToShow = const TypingScreen();
                      break;
                    case StudyMode.spacedRepetition:
                      screenToShow = const SpacedRepetitionScreen();
                      break;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => screenToShow),
                  );
                } else {
                  String errorMsg = studyProvider.error ??
                      'Gagal memulai sesi belajar universal';
                  _showErrorSnackbar(errorMsg);
                }
              } catch (e) {
                setState(() => _isLoading = false);
                _showErrorSnackbar('Error: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Mulai Belajar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Belajar'), centerTitle: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorView()
              : Consumer<StudyProvider>(
                  builder: (context, studyProvider, child) {
                    if (studyProvider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (studyProvider.error != null) {
                      return _buildStudyProviderError(studyProvider);
                    }

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Session limit info
                          if (!studyProvider.isPremium) ...[
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.info_outline,
                                          color: Colors.blue,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            studyProvider.remainingSessions > 0
                                                ? 'Anda memiliki ${studyProvider.remainingSessions} sesi belajar tersisa hari ini.'
                                                : 'Anda telah mencapai batas sesi belajar harian.',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (studyProvider.remainingSessions <=
                                        0) ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Text(
                                            'Upgrade ke premium untuk sesi tak terbatas',
                                          ),
                                          const SizedBox(width: 8),
                                          TextButton(
                                            onPressed: () {
                                              // Navigasi ke halaman premium
                                            },
                                            child: const Text('Upgrade'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Study modes
                          Text(
                            'Mode Belajar',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 16),

                          // Flashcard mode
                          _buildStudyModeCard(
                            context: context,
                            title: 'Flashcards',
                            description:
                                'Pelajari frasa dengan kartu interaktif',
                            icon: Icons.flip,
                            onTap: () =>
                                _startStudySession(StudyMode.flashcard),
                          ),
                          const SizedBox(height: 12),

                          // Quiz mode
                          _buildStudyModeCard(
                            context: context,
                            title: 'Kuis',
                            description:
                                'Uji pengetahuan Anda dengan pertanyaan acak',
                            icon: Icons.quiz,
                            onTap: () => _startStudySession(StudyMode.quiz),
                          ),
                          const SizedBox(height: 12),

                          // Typing mode
                          _buildStudyModeCard(
                            context: context,
                            title: 'Ketik Jawaban',
                            description:
                                'Latih ingatan dengan mengetik terjemahan yang benar',
                            icon: Icons.keyboard,
                            onTap: () => _startStudySession(StudyMode.typing),
                          ),

                          // Spaced Repetition mode
                          _buildStudyModeCard(
                            context: context,
                            title: 'Pengulangan',
                            description:
                                'Latihan pengulangan untuk meningkatkan ingatan',
                            icon: Icons.repeat,
                            onTap: () =>
                                _startStudySession(StudyMode.spacedRepetition),
                          ),

                          const SizedBox(height: 24),

                          // Study options
                          Text(
                            'Pengaturan Latihan',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 16),

                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Language selection
                                  _buildLanguageSelector(context),
                                  const SizedBox(height: 16),

                                  // Category selection
                                  _buildCategorySelector(context),
                                  const SizedBox(height: 16),

                                  // Phrase count selection
                                  _buildPhraseCountSelector(context),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          const Text('Terjadi kesalahan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _error = null;
                _isLoading = true;
              });
              _initializeProviders();
              _loadRemainingSessionCount();
            },
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildStudyProviderError(StudyProvider provider) {
    // Cek jika error berkaitan dengan unauthorized
    bool isAuthError = provider.error != null &&
        (provider.error!.contains('user_unauthorized') ||
            provider.error!.contains('401'));

    String displayError = isAuthError
        ? 'Anda tidak memiliki izin yang diperlukan untuk mengakses fitur belajar. Silakan coba masuk kembali atau periksa koneksi internet Anda.'
        : provider.error!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isAuthError ? Icons.lock : Icons.error_outline,
              size: 48, color: Colors.red),
          const SizedBox(height: 16),
          const Text('Kesalahan Provider Belajar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              displayError,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  final authProvider =
                      Provider.of<AuthProvider>(context, listen: false);
                  provider.initialize(authProvider.userId);
                  _loadRemainingSessionCount();
                },
                child: const Text('Coba Lagi'),
              ),
              if (isAuthError) ...[
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () async {
                    final authProvider =
                        Provider.of<AuthProvider>(context, listen: false);
                    try {
                      await authProvider.refreshSession();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Sesi berhasil diperbarui'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      provider.initialize(authProvider.userId);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Gagal memperbarui sesi: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Refresh Sesi'),
                ),
              ],
            ],
          ),
          if (isAuthError) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: () async {
                // Logout dan navigasi ke login screen
                try {
                  final authProvider =
                      Provider.of<AuthProvider>(context, listen: false);
                  await authProvider.logout();

                  // Navigasi ke login screen
                  // Perlu disesuaikan dengan navigasi aplikasi
                  Navigator.pushReplacementNamed(context, '/login');
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal logout: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Login Ulang'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStudyModeCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 36, color: Theme.of(context).primaryColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(description),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSelector(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bahasa',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
              ),
              child: DropdownButton<String>(
                value: _selectedLanguageId,
                hint: const Text('Semua Bahasa'),
                isExpanded: true,
                underline: const SizedBox(),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Semua Bahasa'),
                  ),
                  ...languageProvider.languages.map((language) {
                    return DropdownMenuItem<String>(
                      value: language.id,
                      child: Text(language.name),
                    );
                  }).toList(),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedLanguageId = value;
                  });
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategorySelector(BuildContext context) {
    return Consumer<CategoryProvider>(
      builder: (context, categoryProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kategori',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
              ),
              child: DropdownButton<String>(
                value: _selectedCategoryId,
                hint: const Text('Semua Kategori'),
                isExpanded: true,
                underline: const SizedBox(),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Semua Kategori'),
                  ),
                  ...categoryProvider.categories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category.id,
                      child: Text(category.name),
                    );
                  }).toList(),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCategoryId = value;
                  });
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPhraseCountSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Jumlah Frasa:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('10'),
            Expanded(
              child: Slider(
                value: _phraseCount.toDouble(),
                min: 5,
                max: 20,
                divisions: 3,
                label: _phraseCount.toString(),
                onChanged: (value) {
                  setState(() {
                    _phraseCount = value.toInt();
                  });
                },
              ),
            ),
            const Text('20'),
          ],
        ),
        Center(
          child: Text(
            '$_phraseCount frasa',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
