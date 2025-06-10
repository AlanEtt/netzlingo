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

class TypingScreenState extends State<TypingScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _answerController = TextEditingController();
  final TTSService _ttsService = TTSService();
  String? _feedback;
  Color? _feedbackColor;
  bool _isChecking = false;
  bool _showTranslation = false;
  bool _showHint = false;

  // Animasi controller untuk transisi pertanyaan
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _ttsService.initialize();

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
    _answerController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _checkAnswer() {
    if (_isChecking) return;

    final provider = Provider.of<StudyProvider>(context, listen: false);
    final currentPhrase = provider.currentPhrase;

    if (currentPhrase == null) return;

    // Dapatkan jawaban dari input
    final userAnswer = _answerController.text.trim();

    // Jika jawaban kosong, tampilkan peringatan
    if (userAnswer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan masukkan jawaban terlebih dahulu'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Bandingkan dengan jawaban yang benar
    final correctAnswer = currentPhrase.translatedText;
    final isCorrect = _isCorrectAnswer(userAnswer, correctAnswer);

    setState(() {
      _isChecking = true;
      _feedbackColor = isCorrect ? Colors.green : Colors.red;
      _feedback =
          isCorrect ? 'Benar!' : 'Salah! Jawaban yang benar: $correctAnswer';
      _showTranslation = true;
      _showHint = false;
    });

    // Tandai jawaban di provider dan lanjut ke frasa berikutnya setelah delay
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;

      provider.markAnswer(isCorrect);

      // Animasi fade out
      _animController.reverse().then((_) {
        if (!mounted) return;

        setState(() {
          _isChecking = false;
          _feedback = null;
          _showTranslation = false;
          _showHint = false;
          _answerController.clear();
        });

        // Cek apakah sudah selesai
        if (provider.currentPhraseIndex >= provider.sessionPhrases.length - 1) {
          _showResultDialog();
        } else {
          // Jika belum selesai, animasi fade in pertanyaan berikutnya
          _animController.forward();
        }
      });
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

  // Menampilkan petunjuk (huruf pertama dari jawaban)
  void _toggleHint() {
    final provider = Provider.of<StudyProvider>(context, listen: false);
    final currentPhrase = provider.currentPhrase;

    if (currentPhrase == null) return;

    setState(() {
      _showHint = !_showHint;
    });
  }

  // Mendapatkan teks petunjuk
  String _getHintText(String answer) {
    if (answer.isEmpty) return '';

    final words = answer.split(' ');
    final hintWords = words.map((word) {
      if (word.length <= 1) return word;
      return '${word[0]}${word.substring(1).replaceAll(RegExp(r'[^\s]'), '_')}';
    }).join(' ');

    return 'Petunjuk: $hintWords';
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
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              _showHelpDialog();
            },
            tooltip: 'Bantuan',
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
                          if (currentPhrase.languageId.isNotEmpty ||
                              currentPhrase.categoryId != null) ...[
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
                  child: Column(
                    children: [
                      TextField(
                        controller: _answerController,
                        decoration: InputDecoration(
                          labelText: 'Ketik jawaban Anda',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  _showHint
                                      ? Icons.lightbulb
                                      : Icons.lightbulb_outline,
                                  color: _showHint ? Colors.amber : null,
                                ),
                                onPressed: _isChecking ? null : _toggleHint,
                                tooltip: 'Petunjuk',
                              ),
                              IconButton(
                                icon: const Icon(Icons.send),
                                onPressed: _isChecking ? null : _checkAnswer,
                                tooltip: 'Periksa Jawaban',
                              ),
                            ],
                          ),
                        ),
                        enabled: !_isChecking,
                        autofocus: true,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _checkAnswer(),
                      ),
                      if (_showHint && !_showTranslation) ...[
                        SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: Text(
                            _getHintText(currentPhrase.translatedText),
                            style: TextStyle(
                              color: Colors.amber.shade800,
                            ),
                          ),
                        ),
                      ],
                    ],
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
                        border: Border.all(
                          color: _feedbackColor?.withOpacity(0.5) ??
                              Colors.transparent,
                        ),
                      ),
                      child: Text(
                        _feedback!,
                        style: TextStyle(
                          color: _feedbackColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                const Spacer(),

                // Hints
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info_outline,
                          size: 16, color: Colors.grey[600]),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Ketik terjemahan yang tepat dari frasa di atas. Kesalahan ketik kecil masih diperbolehkan.',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
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
            Text('2. Ketikkan terjemahan yang benar di kotak input.'),
            SizedBox(height: 8),
            Text('3. Tekan ikon kirim atau Enter untuk memeriksa jawaban.'),
            SizedBox(height: 8),
            Text('4. Gunakan ikon petunjuk (bohlam) jika Anda kesulitan.'),
            SizedBox(height: 8),
            Text('5. Tekan ikon suara untuk mendengar pengucapan frasa.'),
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
