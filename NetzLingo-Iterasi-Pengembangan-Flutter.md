# Rencana Iterasi & Progress MVP Aplikasi NetzLingo (Revisi)

Penyusun: [Rizki Alan Habibi - 221240001238] Tanggal Update Terakhir: [10-07-2025]

## Pra-Iterasi: Persiapan & Setup Awal (Selesai)

- Progress Iterasi: 100% ✅
  - ✅ Setup Lingkungan Flutter (SDK, Editor, Emulator/Device)
  - ✅ Setup Project NetzLingo (Instalasi Lokal)
  - ✅ Buat Struktur Project Flutter Awal (Folders, Basic Files)
  - ✅ Integrasi Provider State Management
  - ✅ Setup AppWrite & Project Configuration
  - ✅ Konfigurasi Authentication System

## Iterasi 1: Autentikasi & Manajemen Frasa Dasar (Fokus: CRUD yang Bekerja) ✅

- Progress Iterasi: 100% (Selesai)
  - ✅ Implementasi User Authentication (Register, Login, Logout)
  - ✅ UI: Form Tambah & Edit Frasa
  - ✅ UI: List Frasa dengan Card
  - ✅ Fitur Hapus Frasa
  - ✅ Perbaikan CRUD Frasa
  - ✅ Perbaikan Permissions AppWrite untuk isolasi data antar pengguna
  - ✅ Implementasi Sistem Fallback Data Universal
  - ✅ Penyempurnaan UI Manajemen Frasa
  - ✅ Validasi Kepemilikan Data (User ID Filtering)
  - ✅ Optimasi State Management dengan AsyncHelper

## Iterasi 2: Kategori, Organisasi & UX (Fokus: Fitur Pengorganisasian) ✅

- Progress Iterasi: 100% (Selesai)
  - ✅ Implementasi Kategori untuk Frasa
  - ✅ Implementasi Tag untuk Frasa (kemudian diredesain)
  - ✅ Fitur Pencarian dengan debouncing
  - ✅ Filter Frasa Berdasarkan Kategori
  - ✅ Filter Frasa Berdasarkan Bahasa
  - ✅ Manajemen Bahasa
  - ✅ Optimasi Performa Database Query
  - ✅ Perbaikan UI untuk PhraseCard
  - ✅ Implementasi Text-to-Speech
  - ✅ Navigasi yang lebih intuitif
  - ✅ Sistem notifikasi untuk feedback operasi CRUD

## Iterasi 3: Mode Pembelajaran & Performa 🟡

- Progress Iterasi: 75% (Sedang Berjalan)
  - ✅ Mode Latihan: Flashcard Sederhana
  - ✅ Mode Latihan: Quiz Pilihan Ganda
  - ✅ Mode Latihan: Pengetikan
  - ✅ Implementasi TTS (Text-to-Speech) 
  - ✅ Transisi Antar Kartu yang Mulus
  - ✅ Tampilan Skor dan Progres Latihan
  - ✅ Akses Universal untuk Mode Latihan
  - ✅ Implementasi Statistik Pembelajaran
  - ✅ Grafik Performa Belajar dengan FL Chart
  - ✅ Tema Terang/Gelap
  - ✅ Persistensi Login & State Management
  - 🟡 **Optimasi Performa Aplikasi**
    - ✅ Optimasi refresh state dan throttling
    - ✅ Pencegahan setState berulang saat build
    - ✅ Pengurangan network request dengan cached data
    - 🟡 Optimasi renderisasi komponen UI
  - 🟡 **Testing & Debugging**
    - ✅ Perbaikan error StudyProvider
    - ✅ Perbaikan error dari setstate berulang
    - 🟡 Uji performa pada berbagai device

## Iterasi 4: Penyempurnaan UI/UX & Deployment ⬜

- Progress Iterasi: 25% (Awal pengerjaan)
  - ✅ Perbaikan UI Secara Keseluruhan
  - ✅ Implementasi Tema Terang/Gelap
  - 🟡 Optimasi untuk Berbagai Ukuran Layar
  - 🟡 Optimasi Kinerja Aplikasi
  - ⬜ Testing Fungsional Menyeluruh
  - ⬜ Perbaikan Bug Final
  - ⬜ Dokumentasi Pengguna
  - ⬜ Deployment ke Play Store (Alpha/Beta)

## Gantt Chart Timeline (Diperbarui)

```mermaid
gantt
    title Alur Iterasi Pengembangan MVP NetzLingo (Update Juli 2025)
    dateFormat  YYYY-MM-DD
    section Persiapan
    Setup Lingkungan & AppWrite   :done, a1, 2025-06-01, 5d
    section Pengembangan
    Iterasi 1: Autentikasi & CRUD Frasa    :done, b1, 2025-06-06, 14d
    Iterasi 2: Kategori & Organisasi       :done, b2, 2025-06-20, 10d
    Iterasi 3: Mode Pembelajaran & Performa:active, b3, 2025-06-30, 14d
    Iterasi 4: Penyempurnaan & Deployment  :b4, 2025-07-14, 14d
    section Testing
    Testing Internal & Bug Fixing          :c1, 2025-07-21, 10d
```

## Pencapaian & Perbaikan Utama

### 1. Perbaikan Performa Aplikasi
- ✅ **Optimasi State Management**: Implementasi AsyncHelper untuk mencegah setState saat build
- ✅ **Throttling & Debouncing**: Mencegah refresh data berlebihan dan UI lag
- ✅ **Pengurangan Network Request**: Menghindari forceRefresh yang tidak perlu
- ✅ **Flag Anti-Overlapping Operations**: Mencegah operasi berulang yang menyebabkan lag

### 2. Keamanan & Isolasi Data
- ✅ **Strict User ID Filtering**: Memastikan pengguna hanya melihat data milik mereka
- ✅ **Permission Management**: Struktur permission AppWrite yang lebih konsisten
- ✅ **Session Validation**: Otomatis memvalidasi dan refresh session yang kedaluwarsa

### 3. Pengalaman Pengguna
- ✅ **Text-to-Speech**: Memungkinkan pengguna mendengar pengucapan frasa
- ✅ **Mode Pembelajaran Interaktif**: Multiple learning modes (flashcard, quiz, typing)
- ✅ **UI Responsif**: Feedback visual untuk setiap aksi pengguna
- ✅ **Mode Tema**: Dukungan tema terang dan gelap

### 4. Arsitektur Data
- ✅ **Data Universal Fallback**: Sistem data berlapis untuk memastikan konten selalu tersedia
- ✅ **Pencegahan Data Crosstalk**: Validasi ketat untuk mencegah data pengguna tercampur
- ✅ **Robust Error Handling**: Penanganan error yang lebih baik dengan fallback state

## Fitur Tambahan yang Diimplementasikan
1. **Statistik Pembelajaran**: Tracking performa belajar dengan visualisasi data
2. **Session Management**: Sistem yang mempertahankan state login di seluruh app
3. **Validasi Lanjutan**: Memastikan integritas data di sisi client

## Fitur yang Ditunda/Dihapus
1. ~~Algoritma Spaced Repetition yang kompleks~~ (Disederhanakan untuk MVP)
2. ~~Model Subscription Premium~~ (Ditunda untuk fase berikutnya)
3. ~~Fitur Import/Export Data~~ (Ditunda)
4. ~~Notifikasi Push~~ (Ditunda)
