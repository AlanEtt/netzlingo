# Panduan Troubleshooting AppWrite untuk NetzLingo

Dokumen ini berisi panduan untuk mengatasi masalah umum yang mungkin Anda temui saat mengembangkan NetzLingo dengan AppWrite.

## Masalah Umum dan Solusi

### 1. Masalah Permissions

#### Gejala:
- Error 401 (Unauthorized)
- Error 403 (Forbidden)
- Pengguna tidak dapat menambah/mengedit frasa
- Error "User is not authorized" saat CRUD operasi

#### Solusi:

##### A. Periksa Collection Permissions
1. Buka [AppWrite Console](https://cloud.appwrite.io)
2. Pilih project NetzLingo
3. Pilih **Database** → pilih database yang digunakan
4. Pilih collection (misalnya "phrases")
5. Buka tab **Settings** → **Permissions**
6. Pastikan setidaknya ada permission berikut:
   - `read("any")`: Untuk memungkinkan pembacaan oleh siapa saja
   - `read("users")`: Untuk pengguna yang terotentikasi
   - `create("users")`: Untuk pengguna yang terotentikasi

##### B. Document-Level Permissions
1. Saat membuat dokumen baru, hindari menggunakan permission kompleks
2. Gunakan pendekatan fallback seperti di `phrase_service.dart`:
   ```dart
   try {
     // Coba buat dokumen tanpa permissions kustom dulu
     final document = await _databases.createDocument(
       databaseId: AppwriteConstants.databaseId,
       collectionId: AppwriteConstants.phrasesCollection,
       documentId: documentId,
       data: data,
     );
     return Phrase.fromDocument(document);
   } catch (e) {
     // Coba pendekatan lain jika gagal
     // ...
   }
   ```

### 2. Error Saat Pembuatan Dokumen

#### Gejala:
- Error "Document creation failed"
- Error "Missing required attribute"
- Error format data

#### Solusi:

1. **Validasi Data Sebelum Dikirim**:
   ```dart
   // Contoh validasi data
   if (phrase.originalText.isEmpty || phrase.translatedText.isEmpty) {
     throw Exception('Teks asli dan terjemahan tidak boleh kosong');
   }
   ```

2. **Log Data yang Dikirim untuk Debug**:
   ```dart
   print("Sending data to AppWrite: ${phrase.toMap()}");
   ```

3. **Gunakan Try-Catch dengan Informasi Detail**:
   ```dart
   try {
     // Kode untuk membuat dokumen
   } catch (e) {
     print("Error detail: $e");
     if (e.toString().contains("duplicate")) {
       // Handle duplicate error
     } else if (e.toString().contains("required")) {
       // Handle missing required field
     }
     // ...dan seterusnya
   }
   ```

### 3. Masalah Sinkronisasi Data

#### Gejala:
- Data tidak muncul setelah ditambahkan
- Perubahan tidak terlihat segera

#### Solusi:

1. **Pastikan UI Diperbarui**:
   ```dart
   // Memastikan UI diperbarui dengan data terbaru
   setState(() {
     // Update UI state
   });
   ```

2. **Gunakan Realtime untuk Pembaruan Langsung**:
   ```dart
   // Di dalam class yang menggunakan AppWrite
   void subscribeToChanges() {
     final subscription = appwriteService.realtime.subscribe([
       'databases.${AppwriteConstants.databaseId}.collections.${AppwriteConstants.phrasesCollection}.documents'
     ]);

     subscription.stream.listen((event) {
       if (event.events.contains('databases.*.collections.*.documents.*')) {
         // Refresh data
         loadPhrases();
       }
     });
   }
   ```

### 4. Masalah Konversi Tipe Data

#### Gejala:
- Error tipe data saat parsing dokumen
- Error "type 'String' is not a subtype of type 'int'"
- Error "Expected List<String> but got List<dynamic>"

#### Solusi:

1. **Gunakan Casting yang Aman**:
   ```dart
   // Contoh untuk konversi List<dynamic> ke List<String>
   permissions: original.$permissions != null 
       ? original.$permissions.cast<String>() 
       : null
   ```

2. **Validasi Tipe Data saat Parsing**:
   ```dart
   factory Phrase.fromDocument(Document document) {
     return Phrase(
       // ...
       importance: document.data['importance'] is int 
           ? document.data['importance'] 
           : int.tryParse(document.data['importance'].toString()) ?? 1,
       // ...
     );
   }
   ```

### 5. Masalah Autentikasi

#### Gejala:
- Error "Session expired"
- Error "Invalid session"
- User terus-menerus diminta login

#### Solusi:

1. **Implementasikan Auto-Refresh Token**:
   ```dart
   // Di auth_provider.dart
   Future<void> refreshSession() async {
     try {
       await _appwriteService.account.getSession(sessionId: 'current');
     } catch (e) {
       if (e.toString().contains('Session expired')) {
         // Logout dan arahkan ke halaman login
         await logout();
         // ... navigate to login
       }
     }
   }
   ```

2. **Tangani Sesi yang Sudah Ada**:
   ```dart
   try {
     await _appwriteService.account.createEmailSession(
       email: email,
       password: password,
     );
   } catch (e) {
     if (e.toString().contains('user_session_already_exists')) {
       try {
         await _appwriteService.account.deleteSessions();
         // Coba login lagi
         await _appwriteService.account.createEmailSession(
           email: email,
           password: password,
         );
       } catch (innerError) {
         // Handle inner error
       }
     }
   }
   ```

## Tips Penggunaan AppWrite

1. **Gunakan ID.unique()**:
   ```dart
   final documentId = ID.unique();
   ```

2. **Batasi Query untuk Performa**:
   ```dart
   queries.add(Query.limit(20));
   ```

3. **Implementasikan Caching**:
   ```dart
   // Simpan hasil query terakhir di memory
   List<Phrase> _cachedPhrases = [];
   DateTime _lastFetch;

   Future<List<Phrase>> getPhrases() async {
     // Gunakan cache jika masih baru (kurang dari 1 menit)
     if (_cachedPhrases.isNotEmpty && 
         DateTime.now().difference(_lastFetch).inMinutes < 1) {
       return _cachedPhrases;
     }
     
     // Jika cache kedaluwarsa, ambil data baru
     try {
       final result = await _fetchPhrasesFromAPI();
       _cachedPhrases = result;
       _lastFetch = DateTime.now();
       return result;
     } catch (e) {
       // Jika gagal, masih menggunakan cache (jika ada)
       if (_cachedPhrases.isNotEmpty) {
         return _cachedPhrases;
       }
       rethrow;
     }
   }
   ```

4. **Gunakan Mode Fallback untuk Keandalan**:
   - Data Pribadi → Data Universal → Data Statis
   - Ini memastikan aplikasi tetap berfungsi meskipun terjadi error

## Alur Debugging

1. Periksa log console (`print` statements) untuk melihat detail error
2. Periksa AppWrite Console → Functions → Logs untuk error server-side
3. Periksa status aplikasi di AppWrite Console → Overview
4. Validasi struktur Collection dan Index di Database

## Kontak Bantuan

Jika Anda mengalami masalah yang tidak tercakup dalam panduan ini, hubungi:

- **Pengembang**: Rizki Alan Habibi
- **Email**: [email_pengembang@example.com] 