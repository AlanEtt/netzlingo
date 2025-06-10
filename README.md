# netzlingo

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## NetzLingo - Aplikasi Belajar Bahasa dengan Spaced Repetition

NetzLingo adalah aplikasi pembelajaran bahasa yang menggunakan teknik spaced repetition untuk membantu pengguna mengingat kata dan frasa dengan lebih efektif.

### Fitur Terbaru

1. **Algoritma Spaced Repetition**
   - Implementasi algoritma SuperMemo-2 (SM-2) untuk pengaturan interval pengulangan
   - Sistem penilaian kualitas ingatan dengan skala 0-5
   - Perhitungan otomatis interval dan ease factor berdasarkan performa pengguna

2. **Mode Latihan**
   - Flashcard: Latihan dengan kartu bolak-balik
   - Quiz: Latihan dengan pilihan ganda
   - Typing: Latihan dengan mengetik jawaban
   - Spaced Repetition: Latihan dengan interval pengulangan adaptif

3. **Akses Universal**
   - Akses ke fitur belajar untuk semua jenis akun (termasuk tanpa login)
   - Data universal yang tersedia untuk akses publik
   - Sistem fallback bertingkat untuk memastikan aplikasi tetap berfungsi

### Progress Pengembangan

- **Iterasi 1: Autentikasi & Struktur Dasar** - ✅ Selesai (100%)
- **Iterasi 2: Sistem Pembelajaran & Kategori** - 🟡 Sedang Berjalan (78%)
- **Iterasi 3: Premium Features & Monetisasi** - 🔴 Belum Dimulai (0%)
- **Iterasi 4: Notifikasi & TTS** - 🔴 Belum Dimulai (0%)
- **Iterasi 5: Import/Export & UI/UX** - 🔴 Belum Dimulai (0%)

### Teknologi yang Digunakan

- Flutter untuk pengembangan cross-platform
- Appwrite sebagai backend cloud
- Provider untuk state management
- Flutter TTS untuk text-to-speech

### Instalasi

```bash
# Clone repository
git clone https://github.com/username/netzlingo.git

# Masuk ke direktori proyek
cd netzlingo

# Install dependencies
flutter pub get

# Jalankan aplikasi
flutter run
```

### Kontributor

- Rizki Alan Habibi - 221240001238
