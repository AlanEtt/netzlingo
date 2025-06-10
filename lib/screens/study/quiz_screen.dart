import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/phrase.dart';
import '../../providers/study_provider.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({Key? key}) : super(key: key);

  @override
  QuizScreenState createState() => QuizScreenState();
}

class QuizScreenState extends State<QuizScreen>
    with SingleTickerProviderStateMixin {
  bool? _isCorrectAnswer; // null berarti belum menjawab
  List<String> _currentOptions = [];
  String? _selectedOption;
  final Random _random = Random();

  // Animasi controller untuk transisi pertanyaan
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _generateOptions();

    // Inisialisasi animasi
    _animController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );

    // Jalankan animasi fade-in pada awal
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _generateOptions() {
    final studyProvider = Provider.of<StudyProvider>(context, listen: false);
    final currentPhrase = studyProvider.currentPhrase;

    if (currentPhrase == null || studyProvider.sessionPhrases.isEmpty) {
      return;
    }

    final correctAnswer = currentPhrase.translatedText;
    _currentOptions = [correctAnswer];

    // Mengambil 3 jawaban salah secara acak
    final otherPhrases = List<Phrase>.from(studyProvider.sessionPhrases)
      ..removeWhere((p) => p.id == currentPhrase.id);

    if (otherPhrases.length < 3) {
      // Jika frasa kurang dari 4, cukup gunakan yang ada
      _currentOptions.addAll(otherPhrases.map((p) => p.translatedText));
    } else {
      // Ambil 3 jawaban salah secara acak
      otherPhrases.shuffle();
      _currentOptions.addAll(
        otherPhrases.take(3).map((p) => p.translatedText),
      );
    }

    // Acak urutan opsi
    _currentOptions.shuffle();
  }

  void _checkAnswer(String selected) {
    if (_isCorrectAnswer != null) return; // Sudah menjawab

    final studyProvider = Provider.of<StudyProvider>(context, listen: false);
    final currentPhrase = studyProvider.currentPhrase;

    if (currentPhrase == null) return;

    final correctAnswer = currentPhrase.translatedText;
    final isCorrect = selected == correctAnswer;

    setState(() {
      _selectedOption = selected;
      _isCorrectAnswer = isCorrect;
    });

    // Tampilkan feedback animasi
    _showAnswerFeedback(isCorrect);

    // Tunggu sebentar untuk menampilkan jawaban benar/salah
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;

      // Tandai jawaban di provider
      studyProvider.markAnswer(isCorrect);

      // Animasi fade out
      _animController.reverse().then((_) {
        if (!mounted) return;

        // Reset state untuk pertanyaan berikutnya
        setState(() {
          _isCorrectAnswer = null;
          _selectedOption = null;
          _generateOptions();
        });

        // Cek apakah kuis sudah selesai
        if (studyProvider.currentPhraseIndex >=
            studyProvider.sessionPhrases.length - 1) {
          _showResultDialog();
        } else {
          // Jika belum selesai, animasi fade in pertanyaan berikutnya
          _animController.forward();
        }
      });
    });
  }

  // Menampilkan feedback visual dan audio untuk jawaban
  void _showAnswerFeedback(bool isCorrect) {
    // Feedback visual sudah ditangani di UI dengan perubahan warna

    // Feedback suara (bisa ditambahkan nanti)
    // Feedback haptic juga bisa ditambahkan
  }

  void _showResultDialog() {
    final studyProvider = Provider.of<StudyProvider>(context, listen: false);
    final correctAnswers = studyProvider.correctAnswers;
    final totalPhrases = studyProvider.sessionPhrases.length;
    final percentage = (correctAnswers / totalPhrases) * 100;
    final formattedPercentage = percentage.toStringAsFixed(1);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Hasil Kuis'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$correctAnswers dari $totalPhrases Benar',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildScoreIndicator(percentage),
            const SizedBox(height: 16),
            Text(
              'Skor: $formattedPercentage%',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 24),
            _buildResultFeedback(percentage),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              studyProvider.cancelSession();
              Navigator.pop(context); // Tutup dialog
              Navigator.pop(context); // Kembali ke halaman sebelumnya
            },
            child: const Text('Kembali ke Menu'),
          ),
          ElevatedButton(
            onPressed: () {
              studyProvider.cancelSession();
              Navigator.pop(context); // Tutup dialog
              Navigator.pop(context); // Kembali ke halaman sebelumnya
              // Menavigasi ke halaman belajar lagi (implementasi nanti)

              // Delay sebentar, lalu mulai sesi baru dengan mode yang sama
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted) {
                  // Logic untuk mulai ulang bisa ditambahkan di sini
                }
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Coba Lagi'),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  // Widget untuk menampilkan skor dalam bentuk visual
  Widget _buildScoreIndicator(double percentage) {
    Color progressColor;
    if (percentage >= 80) {
      progressColor = Colors.green;
    } else if (percentage >= 60) {
      progressColor = Colors.amber;
    } else {
      progressColor = Colors.red;
    }

    return Container(
      height: 120,
      width: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            height: 120,
            width: 120,
            child: CircularProgressIndicator(
              value: percentage / 100,
              strokeWidth: 12,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          Text(
            '${percentage.toInt()}%',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: progressColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultFeedback(double percentage) {
    String message;
    IconData icon;
    Color color;

    if (percentage >= 90) {
      message = 'Luar biasa!';
      icon = Icons.emoji_events;
      color = Colors.amber;
    } else if (percentage >= 70) {
      message = 'Sangat bagus!';
      icon = Icons.thumb_up;
      color = Colors.green;
    } else if (percentage >= 50) {
      message = 'Cukup baik';
      icon = Icons.sentiment_satisfied;
      color = Colors.blue;
    } else {
      message = 'Perlu latihan lagi';
      icon = Icons.sentiment_neutral;
      color = Colors.orange;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(width: 8),
        Text(
          message,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kuis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              _showHelpDialog();
            },
          ),
        ],
      ),
      body: Consumer<StudyProvider>(
        builder: (context, studyProvider, child) {
          if (studyProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (studyProvider.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Error: ${studyProvider.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (studyProvider.sessionPhrases.isEmpty) {
            return const Center(
              child: Text(
                'Tidak ada frasa yang tersedia untuk sesi ini.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            );
          }

          final currentPhrase = studyProvider.currentPhrase;
          if (currentPhrase == null) {
            return const Center(
              child: Text(
                'Tidak dapat memuat frasa saat ini.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            );
          }

          return FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // Progress bar
                LinearProgressIndicator(
                  value: studyProvider.sessionProgress,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary),
                  minHeight: 8,
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pertanyaan ${studyProvider.currentPhraseIndex + 1} dari ${studyProvider.sessionPhrases.length}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '${studyProvider.correctAnswers}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Question
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Text(
                            'Apa terjemahan dari:',
                            style: TextStyle(
                                fontSize: 16, color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            currentPhrase.originalText,
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          if (currentPhrase.categoryId != null ||
                              currentPhrase.languageId.isNotEmpty) ...[
                            SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (currentPhrase.languageId.isNotEmpty)
                                  Chip(
                                    backgroundColor: Colors.blue.shade100,
                                    label: Text(
                                      currentPhrase.languageId,
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                if (currentPhrase.categoryId != null) ...[
                                  SizedBox(width: 8),
                                  Chip(
                                    backgroundColor: Colors.green.shade100,
                                    label: Text(
                                      currentPhrase.categoryId!,
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                // Options
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _currentOptions.length,
                    itemBuilder: (context, index) {
                      final option = _currentOptions[index];
                      final isSelected = _selectedOption == option;
                      final isCorrect = option == currentPhrase.translatedText;

                      // Styling based on selection and correctness
                      Color? backgroundColor;
                      Color? borderColor;

                      if (_isCorrectAnswer != null) {
                        // Jawaban sudah dipilih
                        if (isCorrect) {
                          backgroundColor = Colors.green.withOpacity(0.2);
                          borderColor = Colors.green;
                        } else if (isSelected) {
                          backgroundColor = Colors.red.withOpacity(0.2);
                          borderColor = Colors.red;
                        }
                      } else if (isSelected) {
                        // Jawaban sedang dipilih tapi belum diperiksa
                        backgroundColor = Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.1);
                        borderColor = Theme.of(context).colorScheme.primary;
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: backgroundColor,
                        elevation: isSelected ? 4 : 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: borderColor ?? Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: InkWell(
                          onTap: _isCorrectAnswer == null
                              ? () => _checkAnswer(option)
                              : null,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 32,
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? borderColor ??
                                                Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                            : Colors.grey,
                                        width: 2,
                                      ),
                                      color: isSelected
                                          ? borderColor?.withOpacity(0.2)
                                          : Colors.transparent,
                                    ),
                                    child: Center(
                                      child: Text(
                                        String.fromCharCode(
                                            65 + index), // A, B, C, D
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? borderColor ??
                                                  Theme.of(context)
                                                      .colorScheme
                                                      .primary
                                              : Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    option,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (_isCorrectAnswer != null && isCorrect)
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 24,
                                  )
                                else if (_isCorrectAnswer != null && isSelected)
                                  Icon(
                                    Icons.cancel,
                                    color: Colors.red,
                                    size: 24,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.help_outline,
                color: Theme.of(context).colorScheme.primary),
            SizedBox(width: 8),
            Text('Cara Bermain'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('1. Baca kata/frasa yang ditampilkan.'),
            SizedBox(height: 8),
            Text('2. Pilih arti yang sesuai dari empat pilihan.'),
            SizedBox(height: 8),
            Text('3. Anda akan melihat jawaban benar setelah memilih.'),
            SizedBox(height: 8),
            Text('4. Lanjutkan hingga menyelesaikan semua pertanyaan.'),
            SizedBox(height: 8),
            Text('5. Lihat skor Anda di akhir kuis.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Mengerti'),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
