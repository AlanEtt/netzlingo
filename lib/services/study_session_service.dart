import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import '../models/study_session.dart';
import '../config/appwrite_constants.dart';
import 'appwrite_service.dart';

class StudySessionService {
  final AppwriteService _appwriteService;
  late Databases _databases;

  StudySessionService(this._appwriteService) {
    _databases = _appwriteService.databases;
  }

  // Mendapatkan semua sesi belajar pengguna
  Future<List<StudySession>> getStudySessions(String userId) async {
    try {
      final documentList = await _databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.studySessionsCollection,
        queries: [
          Query.equal('user_id', userId),
          Query.orderDesc('start_time'),
        ],
      );

      return documentList.documents
          .map((doc) => StudySession.fromDocument(doc))
          .toList();
    } catch (e) {
      print("Error getting study sessions: $e");
      return []; // Return empty list instead of throwing
    }
  }

  // Mendapatkan sesi belajar berdasarkan ID
  Future<StudySession> getStudySession(String id) async {
    try {
      final document = await _databases.getDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.studySessionsCollection,
        documentId: id,
      );

      return StudySession.fromDocument(document);
    } catch (e) {
      print("Error getting study session: $e");
      rethrow;
    }
  }

  // Mendapatkan sesi belajar hari ini
  Future<List<StudySession>> getTodaySessions(String userId) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final documentList = await _databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.studySessionsCollection,
        queries: [
          Query.equal('user_id', userId),
          Query.greaterThanEqual('start_time', startOfDay.toIso8601String()),
          Query.lessThanEqual('start_time', endOfDay.toIso8601String()),
        ],
      );

      return documentList.documents
          .map((doc) => StudySession.fromDocument(doc))
          .toList();
    } catch (e) {
      print("Error getting today's sessions: $e");
      return []; // Return empty list instead of throwing
    }
  }

  // Memulai sesi belajar universal (untuk semua jenis akun)
  Future<StudySession> startUniversalStudySession({
    required String sessionType,
    String? languageId,
    String? categoryId,
  }) async {
    try {
      print("Starting universal study session");
      final studySession = StudySession(
        id: ID.unique(),
        userId: 'universal',
        startTime: DateTime.now(),
        totalPhrases: 0,
        correctAnswers: 0,
        sessionType: sessionType,
        languageId: languageId,
        categoryId: categoryId,
      );

      // Buat list permission yang benar dengan tipe List<String>
      List<String> universalPermissions = [];
      universalPermissions.add(Permission.read(Role.any()));
      universalPermissions.add(Permission.read(Role.users()));
      universalPermissions.add(Permission.read(Role.guests()));
      universalPermissions.add(Permission.update(Role.any()));

      print("Creating universal study session with permissions: $universalPermissions");
      
      final document = await _databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.studySessionsCollection,
        documentId: studySession.id,
        data: studySession.toMap(),
        // Menggunakan List<String> permissions yang sudah dibuat
        permissions: universalPermissions,
      );

      print("Universal study session created successfully: ${document.$id}");
      return StudySession.fromDocument(document);
    } catch (e) {
      print("Error starting universal study session: $e");
      
      // Fallback ke objek lokal jika gagal
      return StudySession(
        id: 'local_universal_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'universal',
        startTime: DateTime.now(),
        totalPhrases: 0,
        correctAnswers: 0,
        sessionType: sessionType,
        languageId: languageId ?? 'unknown',
        categoryId: categoryId,
      );
    }
  }

  // Memulai sesi belajar baru
  Future<StudySession> startStudySession({
    required String userId,
    required String sessionType,
    String? languageId,
    String? categoryId,
  }) async {
    try {
      // Jika userId adalah 'universal' atau 'guest', gunakan fungsi universal
      if (userId == 'universal' || userId == 'guest') {
        return await startUniversalStudySession(
          sessionType: sessionType,
          languageId: languageId,
          categoryId: categoryId,
        );
      }
      
      print("Starting study session for user: $userId");
      final studySession = StudySession(
        id: ID.unique(),
        userId: userId,
        startTime: DateTime.now(),
        totalPhrases: 0,
        correctAnswers: 0,
        sessionType: sessionType,
        languageId: languageId,
        categoryId: categoryId,
      );

      // Buat list permission dengan tipe List<String>
      List<String> sessionPermissions = [];
      sessionPermissions.add(Permission.read(Role.any()));
      sessionPermissions.add(Permission.read(Role.users()));
      sessionPermissions.add(Permission.read(Role.guests()));
      sessionPermissions.add(Permission.update(Role.user(userId)));
      sessionPermissions.add(Permission.delete(Role.user(userId)));

      print("Creating study session with permissions: $sessionPermissions");
      
      final document = await _databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.studySessionsCollection,
        documentId: studySession.id,
        data: studySession.toMap(),
        // Menggunakan List<String> permissions
        permissions: sessionPermissions,
      );

      print("Study session created successfully: ${document.$id}");
      return StudySession.fromDocument(document);
    } catch (e) {
      print("Error starting study session: $e");
      
      // Jika error adalah unauthorized, coba dengan universal mode
      if (e.toString().contains('user_unauthorized') || e.toString().contains('401')) {
        print("Permission issue detected, using universal study session");
        return await startUniversalStudySession(
          sessionType: sessionType,
          languageId: languageId,
          categoryId: categoryId,
        );
      }
      
      // Jika gagal, coba lagi tanpa permissions
      try {
        print("Trying to create study session without custom permissions");
        final studySession = StudySession(
          id: ID.unique(),
          userId: userId,
          startTime: DateTime.now(),
          totalPhrases: 0,
          correctAnswers: 0,
          sessionType: sessionType,
          languageId: languageId,
          categoryId: categoryId,
        );

        final document = await _databases.createDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.studySessionsCollection,
          documentId: studySession.id,
          data: studySession.toMap(),
          // Tanpa custom permissions
        );
        
        print("Study session created without custom permissions: ${document.$id}");
        return StudySession.fromDocument(document);
      } catch (innerError) {
        print("Error creating study session without permissions: $innerError");
        
        // Jika masih gagal, coba dengan mode universal sebagai fallback terakhir
        try {
          return await startUniversalStudySession(
            sessionType: sessionType,
            languageId: languageId,
            categoryId: categoryId,
          );
        } catch (universalError) {
          print("Error with universal session too: $universalError");
          
          // Jika segala cara gagal, kembalikan objek session lokal
          return StudySession(
            id: 'local_${DateTime.now().millisecondsSinceEpoch}',
            userId: userId,
            startTime: DateTime.now(),
            totalPhrases: 0,
            correctAnswers: 0,
            sessionType: sessionType,
            languageId: languageId ?? 'unknown',
            categoryId: categoryId,
          );
        }
      }
    }
  }

  // Mengakhiri sesi belajar
  Future<StudySession> endStudySession({
    required String sessionId,
    required int totalPhrases,
    required int correctAnswers,
  }) async {
    // Jika session lokal, return objek lokal saja
    if (sessionId.startsWith('local_')) {
      print("Local session, returning local object");
      return StudySession(
        id: sessionId,
        userId: sessionId.contains('universal') ? 'universal' : 'local_user',
        startTime: DateTime.now().subtract(const Duration(minutes: 5)),
        endTime: DateTime.now(),
        totalPhrases: totalPhrases,
        correctAnswers: correctAnswers,
        sessionType: sessionId.contains('universal') ? 'universal_mode' : 'local_mode',
        languageId: 'unknown',
      );
    }
    
    try {
      print("Ending study session: $sessionId");
      
      // Dapatkan sesi yang sedang berlangsung
      final document = await _databases.getDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.studySessionsCollection,
        documentId: sessionId,
      );

      final existingSession = StudySession.fromDocument(document);
      print("Got existing session for user: ${existingSession.userId}");

      // Update dengan hasil akhir
      final updatedSession = existingSession.copyWith(
        endTime: DateTime.now(),
        totalPhrases: totalPhrases,
        correctAnswers: correctAnswers,
      );

      // Buat array String kosong untuk permissions
      final List<String> permissionsList = [];
      
      // Tambahkan izin baca untuk semua
      permissionsList.add(Permission.read(Role.any()));
      
      // Jika universal session, tambahkan permission update untuk any
      if (existingSession.userId == 'universal') {
        print("Adding universal update permissions");
        permissionsList.add(Permission.update(Role.any()));
      } else {
        // Jika user session, tambahkan permission update untuk user tersebut
        print("Adding user-specific permissions for: ${existingSession.userId}");
        permissionsList.add(Permission.read(Role.user(existingSession.userId)));
        permissionsList.add(Permission.update(Role.user(existingSession.userId)));
      }
      
      print("Permission list created with ${permissionsList.length} items");

      // Simpan perubahan
      final updatedDocument = await _databases.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.studySessionsCollection,
        documentId: sessionId,
        data: updatedSession.toMap(),
        permissions: permissionsList,
      );

      print("Study session ended successfully: $sessionId");
      return StudySession.fromDocument(updatedDocument);
    } catch (e) {
      print("Error ending study session: $e");
      
      // Coba lagi tanpa permissions
      try {
        print("Trying to update study session without permissions");
        
        Document? document;
        try {
          document = await _databases.getDocument(
            databaseId: AppwriteConstants.databaseId,
            collectionId: AppwriteConstants.studySessionsCollection,
            documentId: sessionId,
          );
        } catch (docError) {
          print("Error getting document: $docError");
          // Fallback jika tidak bisa get document
          return StudySession(
            id: sessionId,
            userId: 'unknown',
            startTime: DateTime.now().subtract(const Duration(minutes: 5)),
            endTime: DateTime.now(),
            totalPhrases: totalPhrases,
            correctAnswers: correctAnswers,
            sessionType: 'unknown',
            languageId: 'unknown',
          );
        }
        
        if (document != null) {
          final existingSession = StudySession.fromDocument(document);
          
          // Update dengan hasil akhir
          final updatedSession = existingSession.copyWith(
            endTime: DateTime.now(),
            totalPhrases: totalPhrases,
            correctAnswers: correctAnswers,
          );
          
          // Coba update tanpa permissions
          final updatedDocument = await _databases.updateDocument(
            databaseId: AppwriteConstants.databaseId,
            collectionId: AppwriteConstants.studySessionsCollection,
            documentId: sessionId,
            data: updatedSession.toMap(),
          );
          
          print("Study session ended without permissions: $sessionId");
          return StudySession.fromDocument(updatedDocument);
        } else {
          throw Exception("Document is null");
        }
      } catch (innerError) {
        print("Error updating study session without permissions: $innerError");
        // Fallback ke local session object
        return StudySession(
          id: sessionId,
          userId: 'error_user',
          startTime: DateTime.now().subtract(const Duration(minutes: 5)),
          endTime: DateTime.now(),
          totalPhrases: totalPhrases,
          correctAnswers: correctAnswers,
          sessionType: 'unknown',
          languageId: 'unknown',
        );
      }
    }
  }

  // Mendapatkan statistik belajar
  Future<Map<String, dynamic>> getStudyStats(String userId) async {
    try {
      final allSessions = await getStudySessions(userId);
      final todaySessions = await getTodaySessions(userId);

      // Hitung total waktu belajar (dalam menit)
      int totalMinutes = 0;
      int todayMinutes = 0;
      int totalPhrases = 0;
      int correctAnswers = 0;

      for (var session in allSessions) {
        totalMinutes += session.durationMinutes;
        totalPhrases += session.totalPhrases;
        correctAnswers += session.correctAnswers;
      }

      for (var session in todaySessions) {
        todayMinutes += session.durationMinutes;
      }

      // Hitung akurasi rata-rata
      double averageAccuracy =
          totalPhrases > 0 ? (correctAnswers / totalPhrases) * 100 : 0.0;

      return {
        'total_sessions': allSessions.length,
        'today_sessions': todaySessions.length,
        'total_minutes': totalMinutes,
        'today_minutes': todayMinutes,
        'total_phrases': totalPhrases,
        'correct_answers': correctAnswers,
        'average_accuracy': averageAccuracy,
      };
    } catch (e) {
      print("Error getting study stats: $e");
      // Return default values instead of throwing
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
}
