import 'package:flutter/foundation.dart';
import '../models/phrase.dart';
import '../models/study_session.dart';
import '../models/review_history.dart';
import '../services/study_session_service.dart';
import '../services/phrase_service.dart';
import '../services/review_history_service.dart';
import '../services/subscription_service.dart';
import '../services/settings_service.dart';
import '../services/appwrite_service.dart';

class StudyProvider with ChangeNotifier {
  final AppwriteService _appwriteService = AppwriteService();
  final StudySessionService _studySessionService =
      StudySessionService(AppwriteService());
  final PhraseService _phraseService = PhraseService(AppwriteService());
  final ReviewHistoryService _reviewHistoryService =
      ReviewHistoryService(AppwriteService());
  final SubscriptionService _subscriptionService =
      SubscriptionService(AppwriteService());
  final SettingsService _settingsService = SettingsService(AppwriteService());

  List<Phrase> _sessionPhrases = [];
  int _currentPhraseIndex = 0;
  bool _isLoading = false;
  String? _error;
  bool _isPremium = false;
  int _remainingSessions = 10;
  StudySession? _currentSession;
  int _correctAnswers = 0;
  String? _userId;
  bool _isUniversalMode = false;

  // Getters
  List<Phrase> get sessionPhrases => _sessionPhrases;
  int get currentPhraseIndex => _currentPhraseIndex;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isPremium => _isPremium;
  int get remainingSessions => _remainingSessions;
  bool get isSessionActive => _currentSession != null;
  int get correctAnswers => _correctAnswers;
  bool get isUniversalMode => _isUniversalMode;

  // Mendapatkan frasa saat ini
  Phrase? get currentPhrase =>
      _sessionPhrases.isNotEmpty && _currentPhraseIndex < _sessionPhrases.length
          ? _sessionPhrases[_currentPhraseIndex]
          : null;

  // Mendapatkan progres sesi saat ini
  double get sessionProgress => _sessionPhrases.isEmpty
      ? 0.0
      : (_currentPhraseIndex + 1) / _sessionPhrases.length;

  // Inisialisasi provider
  Future<void> initialize(String userId) async {
    _isLoading = true;
    _userId = userId;
    _isUniversalMode = (userId == 'universal' || userId == 'guest');
    notifyListeners();

    try {
      // Cek status premium - universal mode selalu dianggap free
      if (_isUniversalMode) {
        _isPremium = false;
        _remainingSessions = 999; // Tidak ada batasan untuk mode universal
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      // Cek status premium untuk user login
      _isPremium = await _subscriptionService.hasPremiumSubscription(userId);

      // Cek sesi tersisa
      try {
        final settings = await _settingsService.getSettings(userId);
        _remainingSessions = _isPremium ? 999 : 10 - settings.dailySessionCount;
      } catch (settingsError) {
        print('Error loading settings: $settingsError');
        // Default ke nilai yang memungkinkan tetap bisa belajar
        _remainingSessions = _isPremium ? 999 : 5;
      }
    } catch (e) {
      print('Error in initialize: $e');
      _error = e.toString();
      
      // Jika error berkaitan dengan izin, aktifkan mode universal
      if (e.toString().contains('user_unauthorized') || e.toString().contains('401')) {
        print('Activating universal mode due to permission error');
        _isUniversalMode = true;
        _isPremium = false;
        _remainingSessions = 999; // Tidak ada batasan untuk mode universal
        _error = null; // Reset error karena sudah ditangani
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Memulai sesi belajar baru
  Future<bool> startNewSession({
    required String sessionType,
    String? languageId,
    String? categoryId,
    int phraseCount = 10,
  }) async {
    if (_userId == null) {
      _error = 'User ID tidak ditemukan. Silakan login terlebih dahulu.';
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Reset state
      _currentPhraseIndex = 0;
      _correctAnswers = 0;

      // Untuk mode universal, langsung gunakan frasa-frasa publik tanpa cek sesi
      if (_isUniversalMode) {
        print("Universal mode active - using public phrases");
        try {
          final publicPhrases = await _phraseService.getPublicPhrases(
            languageId: languageId,
            categoryId: categoryId,
            limit: phraseCount * 2,
          );
          
          if (publicPhrases.isEmpty) {
            // Jika tidak ada frasa publik di database, gunakan frasa statis
            print("No public phrases found in database, using static phrases");
            _sessionPhrases = _phraseService.getDefaultStaticPhrases();
            if (_sessionPhrases.length > phraseCount) {
              _sessionPhrases = _sessionPhrases.sublist(0, phraseCount);
            }
          } else {
            // Gunakan frasa publik dari database
            publicPhrases.shuffle();
            _sessionPhrases = publicPhrases.take(phraseCount).toList();
          }
          
          // Buat sesi universal
          _currentSession = await _studySessionService.startUniversalStudySession(
            sessionType: sessionType,
            languageId: languageId,
            categoryId: categoryId,
          );
          
          _isLoading = false;
          notifyListeners();
          return true;
        } catch (e) {
          print("Error in universal mode: $e");
          // Fallback ke static phrases
          _sessionPhrases = _phraseService.getDefaultStaticPhrases();
          if (_sessionPhrases.length > phraseCount) {
            _sessionPhrases = _sessionPhrases.sublist(0, phraseCount);
          }
          
          // Gunakan sesi lokal
          _currentSession = StudySession(
            id: 'local_universal_${DateTime.now().millisecondsSinceEpoch}',
            userId: 'universal',
            startTime: DateTime.now(),
            endTime: null,
            totalPhrases: _sessionPhrases.length,
            correctAnswers: 0,
            sessionType: sessionType,
            languageId: languageId ?? 'unknown',
            categoryId: categoryId,
          );
          
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }

      // Mode normal (user login) - periksa batasan sesi
      try {
        final settings =
            await _settingsService.resetDailySessionCountIfNeeded(_userId!);

        if (!_isPremium && settings.dailySessionCount >= 10) {
          _error =
              'Anda telah mencapai batas 10 sesi latihan harian. Upgrade ke premium untuk latihan tak terbatas!';
          _isLoading = false;
          notifyListeners();
          return false;
        }

        // Update jumlah sesi hari ini (optimize: ubah urutan untuk handling error)
        await _settingsService.updateDailySessionCount(
          _userId!,
          settings.dailySessionCount + 1,
        );

        // Update sesi tersisa
        _remainingSessions =
            _isPremium ? 999 : 10 - (settings.dailySessionCount + 1);
      } catch (e) {
        print("Error checking session limits: $e");
        // Fallback: tetap boleh belajar meski ada error
        _remainingSessions = _isPremium ? 999 : 5; // Asumsi masih ada sesi tersisa
      }

      // Dapatkan frasa untuk sesi ini
      List<String> phraseIds = [];
      bool usePublicMode = false;

      try {
        if (sessionType == 'review') {
          try {
            // Dapatkan frasa untuk direview
            phraseIds =
                await _reviewHistoryService.getPhrasesToReviewToday(_userId!);

            // Batasi jumlah frasa
            if (phraseIds.length > phraseCount) {
              phraseIds = phraseIds.sublist(0, phraseCount);
            }
            
            // Jika tidak ada frasa untuk direview, gunakan frasa publik
            if (phraseIds.isEmpty) {
              print("No phrases to review, using public phrases instead");
              usePublicMode = true;
            }
          } catch (e) {
            print("Error getting phrases to review: $e");
            // Jika error unauthorized, gunakan frasa publik
            if (e.toString().contains('user_unauthorized') || e.toString().contains('401')) {
              usePublicMode = true;
            } else {
              rethrow;
            }
          }
        } 
        
        if (!sessionType.contains('review') || usePublicMode) {
          try {
            // Dapatkan frasa berdasarkan filter
            final phrases = await _phraseService.getPhrases(
              userId: _userId!,
              languageId: languageId,
              categoryId: categoryId,
            );

            if (phrases.isEmpty) {
              print("No phrases found with filter, trying public phrases");
              // Coba dapatkan frasa publik
              final publicPhrases = await _phraseService.getPublicPhrases(
                languageId: languageId,
                categoryId: categoryId,
                limit: phraseCount * 2, // Ambil lebih banyak untuk memungkinkan seleksi acak
              );
              
              if (publicPhrases.isEmpty) {
                _error = 'Tidak ada frasa yang tersedia untuk belajar. Tambahkan frasa terlebih dahulu atau coba kategori lain.';
                _isLoading = false;
                notifyListeners();
                return false;
              }
              
              // Ambil secara acak dari frasa publik
              publicPhrases.shuffle();
              final selectedPhrases = publicPhrases.take(phraseCount).toList();
              phraseIds = selectedPhrases.map((p) => p.id).toList();
              _sessionPhrases = selectedPhrases;
            } else {
              // Ambil secara acak
              phrases.shuffle();
              final selectedPhrases = phrases.take(phraseCount).toList();
              phraseIds = selectedPhrases.map((p) => p.id).toList();
              _sessionPhrases = selectedPhrases;
            }
          } catch (e) {
            print("Error getting user phrases: $e");
            // Jika error unauthorized, gunakan frasa publik
            if (e.toString().contains('user_unauthorized') || e.toString().contains('401')) {
              print("Unauthorized access, using public phrases");
              final publicPhrases = await _phraseService.getPublicPhrases(
                languageId: languageId,
                categoryId: categoryId,
                limit: phraseCount * 2,
              );
              
              if (publicPhrases.isEmpty) {
                throw Exception('Tidak ada frasa publik yang tersedia untuk belajar');
              }
              
              publicPhrases.shuffle();
              final selectedPhrases = publicPhrases.take(phraseCount).toList();
              phraseIds = selectedPhrases.map((p) => p.id).toList();
              _sessionPhrases = selectedPhrases;
            } else {
              rethrow;
            }
          }
        }

        // Jika menggunakan review dan belum diisi
        if (sessionType == 'review' && phraseIds.isNotEmpty && _sessionPhrases.isEmpty) {
          _sessionPhrases = [];
          for (var id in phraseIds) {
            try {
              final phrase = await _phraseService.getPhrase(id);
              _sessionPhrases.add(phrase);
            } catch (e) {
              print("Error getting phrase $id: $e");
              // Lanjutkan dengan frasa berikutnya
            }
          }
        }
      } catch (e) {
        print("Error loading phrases: $e");
        
        // Sebagai fallback terakhir, coba gunakan frasa statis default
        if (e.toString().contains('user_unauthorized') || e.toString().contains('401')) {
          try {
            _sessionPhrases = _phraseService.getDefaultStaticPhrases();
            if (_sessionPhrases.length > phraseCount) {
              _sessionPhrases = _sessionPhrases.sublist(0, phraseCount);
            }
            print("Using static default phrases as last resort");
          } catch (innerError) {
            _error = 'Terjadi kesalahan saat memuat frasa: ${e.toString()}. Silakan coba lagi.';
            _isLoading = false;
            notifyListeners();
            return false;
          }
        } else {
          _error = 'Terjadi kesalahan saat memuat frasa: ${e.toString()}. Silakan coba lagi.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }
      
      if (_sessionPhrases.isEmpty) {
        _error = 'Tidak ada frasa yang tersedia untuk dipelajari dengan filter yang dipilih';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Buat record sesi baru - jika gagal, gunakan sesi lokal
      try {
        _currentSession = await _studySessionService.startStudySession(
          userId: _userId!,
          sessionType: sessionType,
          languageId: languageId,
          categoryId: categoryId,
        );
      } catch (e) {
        print("Error creating session record: $e");
        
        // Jika error berkaitan dengan izin, coba dengan mode universal
        if (e.toString().contains('user_unauthorized') || e.toString().contains('401')) {
          print("Permission issue detected, trying universal study session");
          try {
            _currentSession = await _studySessionService.startUniversalStudySession(
              sessionType: sessionType,
              languageId: languageId,
              categoryId: categoryId,
            );
          } catch (universalError) {
            print("Error with universal session too: $universalError");
            // Meskipun gagal mencatat sesi, tetap lanjutkan belajar dengan sesi lokal
            _currentSession = StudySession(
              id: 'local_session_${DateTime.now().millisecondsSinceEpoch}',
              userId: 'universal',
              sessionType: sessionType,
              languageId: languageId ?? 'unknown',
              categoryId: categoryId,
              startTime: DateTime.now(),
              endTime: null,
              totalPhrases: 0,
              correctAnswers: 0,
            );
          }
        } else {
          // Meskipun gagal mencatat sesi, tetap lanjutkan belajar
          _currentSession = StudySession(
            id: 'local_session_${DateTime.now().millisecondsSinceEpoch}',
            userId: _userId!,
            sessionType: sessionType,
            languageId: languageId ?? 'unknown',
            categoryId: categoryId,
            startTime: DateTime.now(),
            endTime: null,
            totalPhrases: 0,
            correctAnswers: 0,
          );
        }
      }

      return true;
    } catch (e) {
      print("Unexpected error in startNewSession: $e");
      _error = 'Terjadi kesalahan: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Menandai jawaban untuk frasa saat ini
  Future<void> markAnswer(bool isCorrect) async {
    if (currentPhrase == null || _currentSession == null || _userId == null)
      return;

    try {
      // Jika mode universal, jangan update review history
      if (!_isUniversalMode && !_currentSession!.id.startsWith('local_')) {
        // Update history review untuk frasa ini
        try {
          final nextReview = await _reviewHistoryService.calculateNextReview(
            currentPhrase!.id,
            _userId!,
            isCorrect,
          );
  
          // Tambahkan review history baru
          await _reviewHistoryService.addReviewHistory(
            ReviewHistory(
              id: '',
              phraseId: currentPhrase!.id,
              userId: _userId!,
              reviewDate: DateTime.now(),
              wasCorrect: isCorrect,
              easeFactor: nextReview['ease_factor'],
              interval: nextReview['interval'],
            ),
          );
        } catch (e) {
          print("Error updating review history: $e");
          // Lanjutkan meski gagal update review history
        }
      }

      // Tambah jawaban benar jika benar
      if (isCorrect) {
        _correctAnswers++;
      }

      // Lanjut ke frasa berikutnya
      if (_currentPhraseIndex < _sessionPhrases.length - 1) {
        _currentPhraseIndex++;
      } else {
        // Selesaikan sesi jika ini frasa terakhir
        await _finishSession();
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Menyelesaikan sesi belajar
  Future<void> _finishSession() async {
    if (_currentSession == null) return;

    try {
      // Update record sesi
      await _studySessionService.endStudySession(
        sessionId: _currentSession!.id,
        totalPhrases: _sessionPhrases.length,
        correctAnswers: _correctAnswers,
      );

      _currentSession = null;
    } catch (e) {
      _error = e.toString();
    }
  }

  // Membatalkan sesi belajar saat ini
  Future<void> cancelSession() async {
    if (_currentSession == null) return;

    try {
      await _finishSession();

      // Reset state
      _sessionPhrases = [];
      _currentPhraseIndex = 0;
      _correctAnswers = 0;

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Mendapatkan statistik belajar
  Future<Map<String, dynamic>> getStudyStats() async {
    if (_userId == null) {
      return {
        'total_sessions': 0,
        'today_sessions': 0,
        'total_minutes': 0,
        'today_minutes': 0,
        'total_phrases': 0,
        'correct_answers': 0,
        'average_accuracy': 0.0,
      };
    }

    try {
      return await _studySessionService.getStudyStats(_userId!);
    } catch (e) {
      _error = e.toString();
      return {
        'total_sessions': 0,
        'today_sessions': 0,
        'total_minutes': 0,
        'today_minutes': 0,
        'total_phrases': 0,
        'correct_answers': 0,
        'average_accuracy': 0.0,
      };
    }
  }

  // Reset error
  void resetError() {
    _error = null;
    notifyListeners();
  }
}
