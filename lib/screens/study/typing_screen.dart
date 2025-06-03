import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/phrase.dart';
import '../../providers/study_provider.dart';
import '../../services/tts_service.dart';

class TypingScreen extends StatefulWidget {
  const TypingScreen({Key? key}) : super(key: key);

  @override
  TypingScreenState createState() => TypingScreenState();
}

class TypingScreenState extends State<TypingScreen> {
  final TextEditingController _answerController = TextEditingController();
  final TTSService _ttsService = TTSService();
  String? _feedback;
  Color? _feedbackColor;
  bool _isChecking = false;
  bool _showTranslation = false;

  @override
  void initState() {
    super.initState();
    _ttsService.initialize();
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  void _checkAnswer() {
    if (_isChecking) return;

    final provider = Provider.of<StudyProvider>(context, listen: false);
    final currentPhrase = provider.currentPhrase;

    if (currentPhrase == null) return;

    // Dapatkan jawaban dari input
    final userAnswer = _answerController.text.trim();

    // Bandingkan dengan jawaban yang benar
    final correctAnswer = currentPhrase.translatedText;
    final isCorrect = _isCorrectAnswer(userAnswer, correctAnswer);

    setState(() {
      _isChecking = true;
      _feedbackColor = isCorrect ? Colors.green : Colors.red;
      _feedback =
          isCorrect ? 'Benar!' : 'Salah! Jawaban yang benar: $correctAnswer';
      _showTranslation = true;
    });

    // Tandai jawaban di provider dan lanjut ke frasa berikutnya setelah delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;

      provider.markAnswer(isCorrect);

      setState(() {
        _isChecking = false;
        _feedback = null;
        _showTranslation = false;
        _answerController.clear();
      });

      // Cek apakah sudah selesai
      if (provider.currentPhraseIndex >= provider.sessionPhrases.length - 1) {
        _showResultDialog();
      }
    });
  }

  // Pengecekan jawaban dengan toleransi typo ringan
  bool _isCorrectAnswer(String userAnswer, String correctAnswer) {
    // Normalisasi jawaban (lowercase, tanpa tanda baca)
    final normalizedUser =
        userAnswer.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
    final normalizedCorrect =
        correctAnswer.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');

    // Cek kesamaan persis setelah normalisasi
    if (normalizedUser == normalizedCorrect) {
      return true;
    }

    // Toleransi typo ringan (jika panjang jawaban berbeda tidak lebih dari 2 karakter)
    if ((normalizedUser.length - normalizedCorrect.length).abs() <= 2) {
      // Hitung jarak Levenshtein (edit distance)
      final distance = _levenshteinDistance(normalizedUser, normalizedCorrect);
      // Toleransi kesalahan maksimal 20% dari panjang jawaban atau 2 karakter, mana yang lebih kecil
      final maxErrors = [2, (correctAnswer.length * 0.2).round()].reduce(min);

      if (distance <= maxErrors) {
        return true;
      }
    }

    return false;
  }

  // Algoritma Levenshtein Distance untuk mengukur perbedaan antar string
  int _levenshteinDistance(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    List<int> v0 = List<int>.filled(t.length + 1, 0);
    List<int> v1 = List<int>.filled(t.length + 1, 0);

    for (int i = 0; i < v0.length; i++) {
      v0[i] = i;
    }

    for (int i = 0; i < s.length; i++) {
      v1[0] = i + 1;

      for (int j = 0; j < t.length; j++) {
        int cost = (s[i] == t[j]) ? 0 : 1;
        v1[j + 1] = [v1[j] + 1, v0[j + 1] + 1, v0[j] + cost].reduce(min);
      }

      for (int j = 0; j < v0.length; j++) {
        v0[j] = v1[j];
      }
    }

    return v1[t.length];
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
        title: const Text('Hasil Latihan'),
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
        title: const Text('Ketik Jawaban'),
        actions: [
          Consumer<StudyProvider>(
            builder: (context, provider, child) {
              return IconButton(
                icon: const Icon(Icons.volume_up),
                onPressed: () => _ttsService
                    .speak(provider.currentPhrase?.originalText ?? ''),
                tooltip: 'Ucapkan',
              );
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
                        if (_showTranslation) ...[
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 8),
                          Text(
                            currentPhrase.translatedText,
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[700],
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              // Answer input
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _answerController,
                  decoration: InputDecoration(
                    labelText: 'Ketik jawaban Anda',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _isChecking ? null : _checkAnswer,
                    ),
                  ),
                  enabled: !_isChecking,
                  autofocus: true,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _checkAnswer(),
                ),
              ),

              // Feedback
              if (_feedback != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _feedbackColor?.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _feedback!,
                      style: TextStyle(
                        color: _feedbackColor,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

              const Spacer(),

              // Hints
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Ketik terjemahan yang tepat dari frasa di atas.',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
 