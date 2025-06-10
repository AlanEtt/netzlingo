import 'package:flutter/foundation.dart';
import '../models/phrase.dart';
import '../models/study_session.dart';
import '../models/review_history.dart';
import '../services/study_session_service.dart';
import '../services/phrase_service.dart';
import '../services/review_history_service.dart';
import '../services/spaced_repetition_service.dart';
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
  final SpacedRepetitionService _spacedRepetitionService =
      SpacedRepetitionService(AppwriteService());

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
      if (e.toString().contains('user_unauthorized') ||
          e.toString().contains('401')) {
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
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Cek apakah pengguna premium atau masih memiliki sesi gratis
      if (!_isUniversalMode && !_isPremium && _remainingSessions <= 0) {
        _error =
            'Anda telah mencapai batas sesi belajar gratis. Upgrade ke premium untuk sesi tak terbatas.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Jika mode adalah spaced repetition, gunakan metode khusus
      if (sessionType.contains('spacedRepetition')) {
        return await startSpacedRepetitionSession(
          languageId: languageId,
          categoryId: categoryId,
          maxPhrases: phraseCount,
          userId: _userId,
        );
      }

      // Untuk mode lainnya, gunakan metode standar
      return await startStudySession(
        sessionType: sessionType,
        languageId: languageId,
        categoryId: categoryId,
        maxPhrases: phraseCount,
        userId: _userId,
      );
    } catch (e) {
      print('Error starting new session: $e');
      _error = 'Gagal memulai sesi belajar: $e';
      _isLoading = false;
      notifyListeners();
      return false;
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

  // Metode untuk memulai sesi belajar
  Future<bool> startStudySession({
    required String sessionType,
    String? languageId,
    String? categoryId,
    int maxPhrases = 10,
    String? userId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final effectiveUserId = userId ?? _userId ?? 'universal';
      _isUniversalMode = effectiveUserId == 'universal';

      // Cek apakah pengguna premium atau masih memiliki sesi gratis
      if (!_isUniversalMode && !_isPremium && _remainingSessions <= 0) {
        _error =
            'Anda telah mencapai batas sesi belajar gratis. Upgrade ke premium untuk sesi tak terbatas.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Mulai sesi belajar baru
      _currentSession = await _studySessionService.startStudySession(
        userId: effectiveUserId,
        sessionType: sessionType,
        languageId: languageId,
        categoryId: categoryId,
      );

      print('Sesi belajar dimulai: ${_currentSession?.id}');

      // Dapatkan frasa untuk sesi belajar
      _sessionPhrases = await _phraseService.getPhrases(
        userId: effectiveUserId,
        languageId: languageId,
        categoryId: categoryId,
      );

      // Batasi jumlah frasa
      if (_sessionPhrases.length > maxPhrases) {
        _sessionPhrases = _sessionPhrases.sublist(0, maxPhrases);
      }

      // Acak urutan frasa
      _sessionPhrases.shuffle();

      _currentPhraseIndex = 0;
      _correctAnswers = 0;

      // Kurangi jumlah sesi yang tersisa jika bukan mode universal dan bukan premium
      if (!_isUniversalMode && !_isPremium) {
        _remainingSessions--;
        // Simpan jumlah sesi yang tersisa
        await _updateRemainingSessions();
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Error memulai sesi belajar: $e');
      _error = 'Gagal memulai sesi belajar: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Metode untuk mengakhiri sesi belajar
  Future<bool> endStudySession() async {
    if (_currentSession == null) {
      return false;
    }

    try {
      await _studySessionService.endStudySession(
        sessionId: _currentSession!.id,
        totalPhrases: _sessionPhrases.length,
        correctAnswers: _correctAnswers,
      );

      _currentSession = null;
      notifyListeners();
      return true;
    } catch (e) {
      print('Error mengakhiri sesi belajar: $e');
      _error = 'Gagal mengakhiri sesi belajar: $e';
      notifyListeners();
      return false;
    }
  }

  // Metode untuk memperbarui jumlah sesi yang tersisa
  Future<void> _updateRemainingSessions() async {
    try {
      // Simpan jumlah sesi yang tersisa di settings
      if (_userId != null) {
        await _settingsService.updateSetting(
            _userId!, 'remaining_sessions', _remainingSessions.toString());
      }
    } catch (e) {
      print('Error memperbarui jumlah sesi tersisa: $e');
    }
  }

  // Metode untuk memulai sesi review dengan algoritma spaced repetition
  Future<bool> startSpacedRepetitionSession({
    String? languageId,
    String? categoryId,
    int maxPhrases = 10,
    String? userId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final effectiveUserId = userId ?? _userId ?? 'universal';
      _isUniversalMode = effectiveUserId == 'universal';

      // Cek apakah pengguna premium atau masih memiliki sesi gratis
      if (!_isUniversalMode && !_isPremium && _remainingSessions <= 0) {
        _error =
            'Anda telah mencapai batas sesi belajar gratis. Upgrade ke premium untuk sesi tak terbatas.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Mulai sesi belajar baru
      _currentSession = await _studySessionService.startStudySession(
        userId: effectiveUserId,
        sessionType: 'spaced_repetition',
        languageId: languageId,
        categoryId: categoryId,
      );

      print('Sesi spaced repetition dimulai: ${_currentSession?.id}');

      // Dapatkan frasa untuk sesi review dengan algoritma spaced repetition
      _sessionPhrases =
          await _spacedRepetitionService.getPhrasesForReviewSession(
        effectiveUserId,
        limit: maxPhrases,
        languageId: languageId,
        categoryId: categoryId,
      );

      // Jika tidak ada frasa yang ditemukan, coba dapatkan frasa acak sebagai fallback
      if (_sessionPhrases.isEmpty) {
        print(
            'Tidak ada frasa untuk review, menggunakan frasa acak sebagai fallback');
        _sessionPhrases = await _phraseService.getPhrases(
          userId: effectiveUserId,
          languageId: languageId,
          categoryId: categoryId,
        );

        // Batasi jumlah frasa
        if (_sessionPhrases.length > maxPhrases) {
          _sessionPhrases = _sessionPhrases.sublist(0, maxPhrases);
        }

        // Acak urutan frasa
        _sessionPhrases.shuffle();
      }

      _currentPhraseIndex = 0;
      _correctAnswers = 0;

      // Kurangi jumlah sesi yang tersisa jika bukan mode universal dan bukan premium
      if (!_isUniversalMode && !_isPremium) {
        _remainingSessions--;
        await _updateRemainingSessions();
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Error memulai sesi spaced repetition: $e');
      _error = 'Gagal memulai sesi belajar: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Metode untuk memproses jawaban dalam mode spaced repetition
  Future<void> processSpacedRepetitionAnswer(int quality) async {
    if (_currentPhraseIndex >= _sessionPhrases.length ||
        _currentSession == null) {
      return;
    }

    final currentPhrase = _sessionPhrases[_currentPhraseIndex];
    final effectiveUserId = _userId ?? 'universal';

    try {
      // Proses jawaban dengan algoritma spaced repetition
      final result = await _spacedRepetitionService.processAnswer(
        currentPhrase.id,
        effectiveUserId,
        quality,
      );

      // Update jumlah jawaban yang benar
      if (result['was_correct'] as bool) {
        _correctAnswers++;
      }

      // Pindah ke frasa berikutnya
      _currentPhraseIndex++;
      notifyListeners();

      // Jika sudah selesai semua frasa, akhiri sesi
      if (_currentPhraseIndex >= _sessionPhrases.length) {
        await endStudySession();
      }
    } catch (e) {
      print('Error memproses jawaban: $e');
      _error = 'Gagal memproses jawaban: $e';
      notifyListeners();
    }
  }

  // Metode untuk mendapatkan statistik review
  Future<Map<String, dynamic>> getReviewStats() async {
    final effectiveUserId = _userId ?? 'universal';

    try {
      return await _spacedRepetitionService.getUserReviewStats(effectiveUserId);
    } catch (e) {
      print('Error mendapatkan statistik review: $e');
      return {
        'total_reviews': 0,
        'correct_reviews': 0,
        'accuracy': 0.0,
        'phrases_reviewed': 0,
        'phrases_learned': 0,
        'total_phrases': 0,
        'progress_percentage': 0.0,
      };
    }
  }

  // Metode untuk mendapatkan statistik review untuk frasa tertentu
  Future<Map<String, dynamic>> getPhraseReviewStats(String phraseId) async {
    final effectiveUserId = _userId ?? 'universal';

    try {
      return await _spacedRepetitionService.getPhraseReviewStats(
        phraseId,
        effectiveUserId,
      );
    } catch (e) {
      print('Error mendapatkan statistik review frasa: $e');
      return {
        'total_reviews': 0,
        'correct_reviews': 0,
        'accuracy': 0.0,
        'last_review_date': null,
        'next_review_date': null,
        'current_interval': 0,
        'ease_factor': 2.5,
      };
    }
  }
}
