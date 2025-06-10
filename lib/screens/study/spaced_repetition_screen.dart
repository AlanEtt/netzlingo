import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/phrase.dart';
import '../../providers/study_provider.dart';
import '../../services/tts_service.dart';

class SpacedRepetitionScreen extends StatefulWidget {
  const SpacedRepetitionScreen({Key? key}) : super(key: key);

  @override
  SpacedRepetitionScreenState createState() => SpacedRepetitionScreenState();
}

class SpacedRepetitionScreenState extends State<SpacedRepetitionScreen>
    with SingleTickerProviderStateMixin {
  bool _isShowingAnswer = false;
  int? _selectedQuality;
  final TTSService _ttsService = TTSService();

  // Animasi controller untuk transisi pertanyaan
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Inisialisasi animasi
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _showAnswer() {
    setState(() {
      _isShowingAnswer = true;
    });
  }

  void _rateAnswer(int quality) {
    setState(() {
      _selectedQuality = quality;
    });

    // Proses jawaban dengan algoritma spaced repetition
    final studyProvider = Provider.of<StudyProvider>(context, listen: false);
    studyProvider.processSpacedRepetitionAnswer(quality);

    // Reset state untuk kartu berikutnya
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isShowingAnswer = false;
          _selectedQuality = null;
        });

        // Animasi fade in untuk kartu berikutnya
        _animController.reset();
        _animController.forward();
      }
    });
  }

  // Fungsi untuk mendapatkan deskripsi kualitas jawaban
  String _getQualityDescription(int quality) {
    switch (quality) {
      case 0:
        return 'Tidak Tahu';
      case 1:
        return 'Salah';
      case 2:
        return 'Hampir';
      case 3:
        return 'Sulit';
      case 4:
        return 'Benar';
      case 5:
        return 'Sangat Mudah';
      default:
        return '';
    }
  }

  // Fungsi untuk mendapatkan warna kualitas jawaban
  Color _getQualityColor(int quality) {
    switch (quality) {
      case 0:
        return Colors.red[900]!;
      case 1:
        return Colors.red[700]!;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.yellow[700]!;
      case 4:
        return Colors.lightGreen;
      case 5:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final studyProvider = Provider.of<StudyProvider>(context);

    if (studyProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (studyProvider.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Error: ${studyProvider.error}',
                style: TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Kembali'),
              ),
            ],
          ),
        ),
      );
    }

    if (studyProvider.sessionPhrases.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Tidak ada frasa untuk direview saat ini.',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Kembali'),
              ),
            ],
          ),
        ),
      );
    }

    if (studyProvider.currentPhraseIndex >=
        studyProvider.sessionPhrases.length) {
      // Sesi selesai
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Sesi review selesai!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Jawaban benar: ${studyProvider.correctAnswers} dari ${studyProvider.sessionPhrases.length}',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text('Selesai', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      );
    }

    // Tampilkan kartu review
    final Phrase currentPhrase =
        studyProvider.sessionPhrases[studyProvider.currentPhraseIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spaced Repetition'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              _showHelpDialog(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: studyProvider.currentPhraseIndex /
                studyProvider.sessionPhrases.length,
            backgroundColor: Colors.grey[200],
            valueColor:
                AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
          ),

          // Counter
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              '${studyProvider.currentPhraseIndex + 1} / ${studyProvider.sessionPhrases.length}',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),

          // Card content
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Language and category badges
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (currentPhrase.languageId.isNotEmpty)
                              Chip(
                                label: Text(currentPhrase.languageId),
                                backgroundColor: Colors.blue[100],
                              ),
                            const SizedBox(width: 8),
                            if (currentPhrase.categoryId != null)
                              Chip(
                                label: Text(currentPhrase.categoryId!),
                                backgroundColor: Colors.green[100],
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Original text
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

                        const SizedBox(height: 8),

                        // TTS button
                        IconButton(
                          icon: const Icon(Icons.volume_up),
                          onPressed: () {
                            _ttsService.speak(currentPhrase.originalText);
                          },
                        ),

                        const Spacer(),

                        // Answer section
                        if (_isShowingAnswer) ...[
                          const Divider(),
                          const SizedBox(height: 16),

                          // Translation
                          Text(
                            currentPhrase.translatedText,
                            style: Theme.of(context).textTheme.titleLarge,
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 24),

                          // Rating buttons
                          const Text(
                            'Seberapa baik Anda mengingat ini?',
                            style: TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 16),

                          // Quality buttons
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: List.generate(6, (index) {
                              return ElevatedButton(
                                onPressed: _selectedQuality == null
                                    ? () => _rateAnswer(index)
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _getQualityColor(index),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                child: Text(
                                  '${index} - ${_getQualityDescription(index)}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              );
                            }),
                          ),
                        ] else ...[
                          const Spacer(),

                          // Show answer button
                          ElevatedButton(
                            onPressed: _showAnswer,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                            ),
                            child: const Text(
                              'Lihat Jawaban',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bantuan Spaced Repetition'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'Spaced Repetition adalah teknik belajar yang mengatur interval pengulangan berdasarkan seberapa baik Anda mengingat suatu informasi.',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 16),
              Text('Cara menggunakan:'),
              SizedBox(height: 8),
              Text('1. Lihat kata/frasa dan coba ingat artinya'),
              Text('2. Klik "Lihat Jawaban" untuk melihat terjemahan'),
              Text('3. Nilai seberapa baik Anda mengingatnya (0-5):'),
              SizedBox(height: 8),
              Text('• 0 - Tidak Tahu: Sama sekali tidak ingat'),
              Text('• 1 - Salah: Ingat tapi salah'),
              Text('• 2 - Hampir: Ingat sebagian'),
              Text('• 3 - Sulit: Ingat dengan usaha keras'),
              Text('• 4 - Benar: Ingat dengan sedikit usaha'),
              Text('• 5 - Sangat Mudah: Ingat dengan sempurna'),
              SizedBox(height: 16),
              Text(
                'Sistem akan mengatur kapan Anda perlu mengulang kata/frasa ini lagi berdasarkan penilaian Anda.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}
