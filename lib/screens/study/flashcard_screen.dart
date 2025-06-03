import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/phrase.dart';
import '../../providers/study_provider.dart';
import '../../services/tts_service.dart';

class FlashcardScreen extends StatefulWidget {
  const FlashcardScreen({Key? key}) : super(key: key);

  @override
  FlashcardScreenState createState() => FlashcardScreenState();
}

class FlashcardScreenState extends State<FlashcardScreen> {
  bool _isShowingTranslation = false;
  final TTSService _ttsService = TTSService();

  @override
  void initState() {
    super.initState();
    _ttsService.initialize();
  }

  void _nextCard(StudyProvider provider) {
    if (provider.currentPhraseIndex < provider.sessionPhrases.length - 1) {
      provider.markAnswer(true); // Flashcard selalu dianggap benar
      setState(() {
        _isShowingTranslation = false;
      });
    } else {
      // Selesai dengan semua kartu
      _showCompletionDialog();
    }
  }

  void _previousCard() {
    final provider = Provider.of<StudyProvider>(context, listen: false);
    if (provider.currentPhraseIndex > 0) {
      setState(() {
        // Tidak ada metode untuk kembali di StudyProvider,
        // jadi kita perlu membuat logic tambahan jika diperlukan
        _isShowingTranslation = false;
      });
    }
  }

  void _toggleTranslation() {
    setState(() {
      _isShowingTranslation = !_isShowingTranslation;
    });
  }

  void _speakText(Phrase? phrase) {
    if (phrase != null) {
      _ttsService.speak(phrase.originalText);
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Sesi Selesai'),
        content: const Text(
          'Anda telah menyelesaikan semua kartu flashcard!',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Provider.of<StudyProvider>(context, listen: false)
                  .cancelSession();
              Navigator.pop(context); // Tutup dialog
              Navigator.pop(context); // Kembali ke halaman sebelumnya
            },
            child: const Text('Kembali ke Menu'),
          ),
          ElevatedButton(
            onPressed: () {
              Provider.of<StudyProvider>(context, listen: false)
                  .cancelSession();
              Navigator.pop(context); // Tutup dialog
              Navigator.pop(context); // Kembali ke halaman utama
              // Implementasi ulangi bisa ditambahkan nanti
            },
            child: const Text('Ulangi Sesi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashcards'),
        actions: [
          Consumer<StudyProvider>(
            builder: (context, provider, child) {
              return IconButton(
                icon: const Icon(Icons.volume_up),
                onPressed: () => _speakText(provider.currentPhrase),
                tooltip: 'Ucapkan',
              );
            },
          ),
        ],
      ),
      body: Consumer<StudyProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Error: ${provider.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (provider.sessionPhrases.isEmpty) {
            return const Center(
              child: Text(
                'Tidak ada frasa yang tersedia untuk sesi ini.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            );
          }

          final currentPhrase = provider.currentPhrase;
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
                value: provider.sessionProgress,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Kartu ${provider.currentPhraseIndex + 1} dari ${provider.sessionPhrases.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),

              // Card
              Expanded(
                child: GestureDetector(
                  onTap: _toggleTranslation,
                  child: Card(
                    margin: const EdgeInsets.all(16),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isShowingTranslation
                                  ? currentPhrase.translatedText
                                  : currentPhrase.originalText,
                              style: Theme.of(context).textTheme.headlineMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              _isShowingTranslation
                                  ? 'Terjemahan'
                                  : 'Ketuk untuk melihat terjemahan',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            if (currentPhrase.notes != null &&
                                _isShowingTranslation) ...[
                              const SizedBox(height: 24),
                              const Divider(),
                              const SizedBox(height: 16),
                              Text(
                                'Catatan:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                currentPhrase.notes!,
                                style: TextStyle(
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
                ),
              ),

              // Navigation buttons
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: provider.currentPhraseIndex > 0
                          ? _previousCard
                          : null,
                      tooltip: 'Sebelumnya',
                      iconSize: 36,
                    ),
                    IconButton(
                      icon: const Icon(Icons.flip),
                      onPressed: _toggleTranslation,
                      tooltip: 'Balik Kartu',
                      iconSize: 36,
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: () => _nextCard(provider),
                      tooltip: 'Selanjutnya',
                      iconSize: 36,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
