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

class QuizScreenState extends State<QuizScreen> {
  bool? _isCorrectAnswer; // null berarti belum menjawab
  List<String> _currentOptions = [];
  String? _selectedOption;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _generateOptions();
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

    // Tunggu sebentar untuk menampilkan jawaban benar/salah
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;

      // Tandai jawaban di provider
      studyProvider.markAnswer(isCorrect);

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
      }
    });
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
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Skor: $formattedPercentage%',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
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
              // Implementasi ulangi bisa ditambahkan nanti
            },
            child: const Text('Coba Lagi'),
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
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 8),
        Text(
          message,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
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

          return Column(
            children: [
              // Progress bar
              LinearProgressIndicator(
                value: studyProvider.sessionProgress,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Pertanyaan ${studyProvider.currentPhraseIndex + 1} dari ${studyProvider.sessionPhrases.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
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
                        const Text(
                          'Apa terjemahan dari:',
                          style: TextStyle(fontSize: 16),
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
                              Expanded(
                                child: Text(
                                  option,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                              if (_isCorrectAnswer != null && isCorrect)
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                )
                              else if (_isCorrectAnswer != null && isSelected)
                                const Icon(
                                  Icons.cancel,
                                  color: Colors.red,
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
          );
        },
      ),
    );
  }
}
