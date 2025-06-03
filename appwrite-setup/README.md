# Panduan Setup Database AppWrite untuk NetzLingo

Script ini membantu Anda membuat database AppWrite untuk aplikasi NetzLingo secara otomatis, termasuk:
- 1 database
- 10 collections (Users, Languages, Categories, Phrases, Tags, PhraseTags, ReviewHistory, StudySessions, Settings, Subscriptions)
- Semua atribut untuk masing-masing collection
- Indeks untuk pencarian dan optimasi
- Data default untuk bahasa

## Persyaratan
- Node.js (versi 14+)
- npm
- AppWrite CLI (sudah terinstal dengan perintah `npm install -g appwrite-cli`)
- jq (JSON processor, diperlukan untuk script shell)

## Cara Menggunakan

### 1. Login ke AppWrite CLI
```bash
appwrite login
```

### 2. Buat API Key di Dashboard AppWrite
- Buka dashboard AppWrite (https://cloud.appwrite.io)
- Pilih project Anda
- Buka tab "API Keys"
- Klik "Create API Key"
- Berikan nama (misalnya "NetzLingo Setup")
- Berikan izin berikut:
  - databases.read
  - databases.write
  - databases.collections.read
  - databases.collections.write
  - databases.collections.attributes.read
  - databases.collections.attributes.write
  - databases.collections.indexes.read
  - databases.collections.indexes.write
  - databases.documents.read
  - databases.documents.write
- Salin API Key yang dihasilkan

### 3. Mengambil Project ID
- Di dashboard AppWrite, pilih project Anda
- Project ID akan terlihat di overview atau di URL (format: project-xxxx)

### 4. Menjalankan Script Setup
Jalankan perintah berikut (ganti YOUR_PROJECT_ID dan YOUR_API_KEY dengan nilai yang sesuai):

```bash
cd appwrite-setup
chmod +x setup-database.sh
./setup-database.sh YOUR_PROJECT_ID YOUR_API_KEY
```

### 5. Verifikasi Hasil
- Buka dashboard AppWrite
- Pilih project Anda
- Buka tab "Databases"
- Pastikan database "NetzLingo" dengan 10 collections telah dibuat

## Pemecahan Masalah

### Error: Database already exists
Jika database sudah ada, script akan tetap melanjutkan dengan membuat collections.

### Error: Collection already exists
Jika collection sudah ada, script akan melanjutkan ke collection berikutnya.

### Error: Cannot connect to AppWrite
Pastikan Anda sudah login ke AppWrite CLI dan memiliki koneksi internet.

### Error: Permission denied
Pastikan API Key yang Anda gunakan memiliki izin yang cukup seperti disebutkan di atas.

## Konfigurasi Flutter

Setelah menjalankan script, jangan lupa untuk mengupdate file `lib/config/appwrite_constants.dart` dengan Project ID yang benar:

```dart
class AppwriteConstants {
  static const String projectId = 'YOUR_PROJECT_ID'; // Ganti dengan Project ID Anda
  static const String databaseId = 'netzlingo_db';
  static const String endpoint = 'https://cloud.appwrite.io/v1';
  // ... kode lainnya
}
``` 