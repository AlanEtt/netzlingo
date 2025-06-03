import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_tts/flutter_tts.dart';

enum TtsState { playing, stopped, paused, continued }

class TTSService {
  static final TTSService _instance = TTSService._internal();

  factory TTSService() => _instance;

  TTSService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isSupported = true;
  TtsState _ttsState = TtsState.stopped;

  // Inisialisasi TTS
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Cek apakah platform mendukung TTS
      if (kIsWeb) {
        // Web platform memerlukan penanganan khusus
        var isSupported = await _flutterTts.isLanguageAvailable("en-US");
        _isSupported = isSupported;

        if (!_isSupported) {
          print('TTS tidak didukung di browser ini');
          return;
        }
      }

      // Siapkan event handlers
      _flutterTts.setStartHandler(() {
        _ttsState = TtsState.playing;
      });

      _flutterTts.setCompletionHandler(() {
        _ttsState = TtsState.stopped;
      });

      _flutterTts.setErrorHandler((msg) {
        _ttsState = TtsState.stopped;
        print("TTS Error: $msg");
      });

      // Cek kemampuan TTS
      final available = await _flutterTts.isLanguageAvailable("id-ID");
      if (available) {
        await _flutterTts.setLanguage("id-ID");
      } else {
        // Fallback ke bahasa default
        final voices = await _flutterTts.getVoices;
        if (voices is List && voices.isNotEmpty) {
          await _flutterTts.setLanguage("en-US");
        }
      }

      await _flutterTts.setSpeechRate(0.5); // Kecepatan bicara (0.0 - 1.0)
      await _flutterTts.setVolume(1.0); // Volume (0.0 - 1.0)
      await _flutterTts.setPitch(1.0); // Pitch (0.5 - 2.0)

      _isInitialized = true;
    } catch (e) {
      print('Error initializing TTS: $e');
      _isSupported = false;
    }
  }

  // Mengubah bahasa TTS
  Future<bool> setLanguage(String langCode) async {
    if (!_isSupported) return false;

    try {
      final available = await _flutterTts.isLanguageAvailable(langCode);
      if (available) {
        await _flutterTts.setLanguage(langCode);
        return true;
      }
      return false;
    } catch (e) {
      print('Error setting TTS language: $e');
      return false;
    }
  }

  // Berbicara teks
  Future<void> speak(String text) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (!_isSupported) {
      print('TTS tidak didukung pada platform ini');
      return;
    }

    if (_ttsState == TtsState.playing) {
      await _flutterTts.stop();
    }

    try {
      await _flutterTts.speak(text);
    } catch (e) {
      print('Error speaking text: $e');
    }
  }

  // Menghentikan TTS
  Future<void> stop() async {
    if (!_isSupported) return;

    try {
      await _flutterTts.stop();
      _ttsState = TtsState.stopped;
    } catch (e) {
      print('Error stopping TTS: $e');
    }
  }

  // Mendapatkan daftar bahasa yang tersedia
  Future<List<String>> getAvailableLanguages() async {
    if (!_isSupported) return [];

    if (!_isInitialized) {
      await initialize();
    }

    try {
      final voices = await _flutterTts.getVoices;
      if (voices is List) {
        final Set<String> languageCodes = {};

        for (final voice in voices) {
          if (voice is Map && voice.containsKey('locale')) {
            languageCodes.add(voice['locale'] as String);
          }
        }

        return languageCodes.toList();
      }
    } catch (e) {
      print('Error getting TTS languages: $e');
    }

    return [];
  }

  // Disposal
  Future<void> dispose() async {
    if (!_isSupported) return;

    try {
      await _flutterTts.stop();
    } catch (e) {
      print('Error disposing TTS: $e');
    }
  }
}
