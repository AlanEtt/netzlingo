# Integrasi AppWrite dengan NetzLingo

Dokumen ini menjelaskan proses integrasi AppWrite dengan aplikasi NetzLingo (aplikasi latihan bahasa).

## Apa itu AppWrite?

AppWrite adalah Backend-as-a-Service (BaaS) open-source yang menyediakan berbagai layanan backend untuk aplikasi Anda, termasuk:
- Autentikasi dan manajemen user
- Database
- Storage file
- Cloud functions
- Realtime updates
- Dan lainnya

## Setup Project AppWrite

### 1. Buat Akun dan Project AppWrite
1. Buka [cloud.appwrite.io](https://cloud.appwrite.io)
2. Buat akun atau login
3. Buat project baru:
   - Nama: "NetzLingo"
   - ID: otomatis atau custom

### 2. Tambahkan Platform Flutter
1. Di dashboard project, klik "Add Platform"
2. Pilih "Flutter"
3. Nama: "NetzLingo Mobile"
4. Package name: sesuaikan dengan package aplikasi (biasanya format `com.yourdomain.netzlingo`)
5. Klik "Register"

### 3. Setup Database Otomatis
Kami telah menyiapkan script otomatis untuk membuat seluruh struktur database:

```bash
cd appwrite-setup
# Buat file script executable
chmod +x setup-database.sh
# Jalankan script dengan Project ID dan API Key Anda
./setup-database.sh YOUR_PROJECT_ID YOUR_API_KEY
```

Untuk panduan lengkap penggunaan script setup, lihat [README.md](appwrite-setup/README.md) di folder `appwrite-setup`.

## Struktur Database

Database NetzLingo terdiri dari 10 collections utama:

1. **Users** - Menyimpan data pengguna
2. **Languages** - Daftar bahasa yang tersedia
3. **Categories** - Kategori frasa (misal: Salam, Makanan, dll)
4. **Phrases** - Frasa-frasa yang disimpan pengguna
5. **Tags** - Tag untuk pengorganisasian frasa
6. **PhraseTags** - Relasi many-to-many antara Phrases dan Tags
7. **ReviewHistory** - Riwayat peninjauan frasa (untuk algoritma spaced repetition)
8. **StudySessions** - Sesi belajar pengguna
9. **Settings** - Pengaturan aplikasi per pengguna
10. **Subscriptions** - Data langganan premium

## Integrasi dengan Flutter

### 1. Tambahkan Dependency AppWrite
Tambahkan dependency AppWrite di `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  appwrite: ^11.0.0  # Sesuaikan dengan versi terbaru
```

Lalu jalankan:
```bash
flutter pub get
```

### 2. Konfigurasi AppWrite Service
Pastikan file `lib/config/appwrite_constants.dart` telah diupdate dengan Project ID yang benar.

### 3. Inisialisasi AppWrite Service
```dart
// lib/services/appwrite_service.dart
import 'package:appwrite/appwrite.dart';
import '../config/appwrite_constants.dart';

class AppwriteService {
  static final AppwriteService _instance = AppwriteService._internal();
  late final Client client;
  late final Account account;
  late final Databases databases;
  late final Storage storage;
  late final Realtime realtime;

  factory AppwriteService() {
    return _instance;
  }

  AppwriteService._internal() {
    client = Client()
        .setEndpoint(AppwriteConstants.endpoint)
        .setProject(AppwriteConstants.projectId)
        .setSelfSigned(status: true); // Set ke false di production
    
    account = Account(client);
    databases = Databases(client);
    storage = Storage(client);
    realtime = Realtime(client);
  }
}
```

## Testing Koneksi

Gunakan kode berikut untuk menguji koneksi ke AppWrite:

```dart
Future<void> testConnection() async {
  try {
    final AppwriteService appwrite = AppwriteService();
    final result = await appwrite.account.get();
    print('Koneksi berhasil: ${result.toMap()}');
  } catch (e) {
    print('Error koneksi: $e');
  }
}
```

## Security & Permissions

### 1. Document-Level Security
Semua collections sudah dikonfigurasi dengan document-level security, yang memungkinkan pengguna hanya dapat mengakses dokumen mereka sendiri.

### 2. API Keys
Untuk menggunakan script setup atau integrasi server-side, Anda perlu membuat API Key dengan permission yang sesuai.

### 3. Team Invites
Untuk kolaborasi, Anda dapat mengundang anggota tim ke project AppWrite Anda.

## Fitur Premium & Monetisasi

Collection Subscriptions digunakan untuk menyimpan data langganan premium pengguna, yang memungkinkan:
- Pelacakan status berlangganan
- Manajemen tanggal mulai dan berakhir langganan
- Pembatasan fitur berdasarkan status langganan

## Troubleshooting

### Masalah Koneksi
- Pastikan Project ID sudah benar di file constants
- Periksa platform Flutter sudah terdaftar di AppWrite
- Periksa izin CORS sudah dikonfigurasi dengan benar

### Error Database
- Pastikan nama collection dan attribute cocok dengan yang didefinisikan di constants
- Periksa permission collection sudah dikonfigurasi dengan benar

## Referensi

- [Dokumentasi AppWrite](https://appwrite.io/docs)
- [Flutter SDK AppWrite](https://appwrite.io/docs/sdks/flutter/getting-started)
- [AppWrite CLI](https://appwrite.io/docs/tooling/command-line/getting-started)

---

Dibuat untuk NetzLingo oleh [Rizki Alan Habibi] 