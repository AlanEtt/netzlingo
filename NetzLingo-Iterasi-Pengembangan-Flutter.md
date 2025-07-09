# Rencana Iterasi & Progress MVP Aplikasi NetzLingo (Revisi)

Penyusun: [Rizki Alan Habibi - 221240001238] Tanggal Update Terakhir: [08-06-2025]

## Pra-Iterasi: Persiapan & Setup Awal (Selesai)

- Progress Iterasi: 100% ✅
  - ✅ Setup Lingkungan Flutter (SDK, Editor, Emulator/Device)
  - ✅ Setup Project NetzLingo (Instalasi Lokal)
  - ✅ Buat Struktur Project Flutter Awal (Folders, Basic Files)
  - ✅ Integrasi Provider State Management
  - ✅ Setup AppWrite & Project Configuration
  - ✅ Konfigurasi Authentication System

## Iterasi 1: Autentikasi & Manajemen Frasa Dasar (Fokus: CRUD yang Bekerja) 🟡

- Progress Iterasi: 70% (Sedang Berjalan)
  - ✅ Implementasi User Authentication (Register, Login, Logout)
  - ✅ UI: Form Tambah & Edit Frasa
  - ✅ UI: List Frasa dengan Card
  - ✅ Fitur Hapus Frasa
  - 🟡 **Perbaikan CRUD Frasa** (Prioritas: memperbaiki bug saat menambah frasa)
  - 🟡 **Perbaikan Permissions AppWrite** (untuk memastikan akses pengguna berfungsi)
  - 🟡 Implementasi Sistem Fallback Data Universal
  - ⬜ Penyempurnaan UI Manajemen Frasa

## Iterasi 2: Kategori & Organisasi (Fokus: Fitur Pengorganisasian) ⬜

- Progress Iterasi: 0% (Belum dimulai)
  - ⬜ Implementasi Kategori untuk Frasa (dengan UI yang intuitif)
  - ⬜ Implementasi Tag untuk Frasa
  - ⬜ Fitur Pencarian Sederhana
  - ⬜ Filter Frasa Berdasarkan Kategori
  - ⬜ Filter Frasa Berdasarkan Bahasa
  - ⬜ Manajemen Bahasa
  - ⬜ Optimasi Performa Database Query

## Iterasi 3: Mode Pembelajaran Dasar ⬜

- Progress Iterasi: 0% (Belum dimulai)
  - ⬜ Mode Latihan: Flashcard Sederhana
  - ⬜ Mode Latihan: Quiz Pilihan Ganda
  - ⬜ Mode Latihan: Pengetikan
  - ⬜ Implementasi TTS Dasar (Text-to-Speech)
  - ⬜ Transisi Antar Kartu yang Mulus
  - ⬜ Tampilan Skor dan Progres Latihan
  - ⬜ Akses Universal untuk Mode Latihan

## Iterasi 4: Penyempurnaan UI/UX & Deployment ⬜

- Progress Iterasi: 0% (Belum dimulai)
  - ⬜ Penyempurnaan UI Secara Keseluruhan
  - ⬜ Implementasi Tema Terang/Gelap
  - ⬜ Optimasi untuk Berbagai Ukuran Layar
  - ⬜ Optimasi Kinerja Aplikasi
  - ⬜ Testing Fungsional Menyeluruh
  - ⬜ Perbaikan Bug Final
  - ⬜ Dokumentasi Pengguna
  - ⬜ Deployment ke Play Store (Alpha/Beta)

## Gantt Chart Timeline

```mermaid
gantt
    title Alur Iterasi Pengembangan MVP NetzLingo (Revisi)
    dateFormat  YYYY-MM-DD
    section Persiapan
    Setup Lingkungan & AppWrite   :done, a1, 2025-06-01, 5d
    section Pengembangan
    Iterasi 1: Autentikasi & CRUD Frasa    :active, b1, 2025-06-06, 14d
    Iterasi 2: Kategori & Organisasi       :b2, after b1, 14d
    Iterasi 3: Mode Pembelajaran Dasar     :b3, after b2, 14d
    Iterasi 4: Penyempurnaan & Deployment  :b4, after b3, 14d
    section Testing
    Testing Internal & Bug Fixing          :c1, 2025-08-01, 7d
```

## Fokus Perbaikan Utama

### Perbaikan CRUD Frasa
1. **Permasalahan Permissions**: Terdapat masalah dengan izin Appwrite saat menambah/mengubah frasa
   - Solusi: Perbaiki struktur permissions dengan format yang konsisten
   - Implementasi fallback ke mode tanpa permissions jika gagal

2. **Manajemen Error yang Lebih Baik**:
   - Tambahkan penanganan error khusus untuk kasus umum
   - Berikan pesan error yang lebih informatif kepada pengguna
   - Implementasi sistem fallback bertingkat

3. **Optimasi Performa Kueri**:
   - Batasi jumlah kueri database
   - Implementasi caching untuk data yang sering diakses

### Arsitektur Data Universal

Untuk memastikan pengguna selalu memiliki akses ke frasa, kami mengimplementasikan sistem data berlapis:

1. **Layer 1**: Data pribadi pengguna (user_id = ID pengguna)
2. **Layer 2**: Data universal (user_id = 'universal')
3. **Layer 3**: Data statis bawaan aplikasi (fallback terakhir)

## Fitur yang Ditunda/Dihapus

Fitur berikut telah ditunda atau dihapus dari MVP untuk menyederhanakan pengembangan:

1. ~~Algoritma Spaced Repetition yang kompleks~~
2. ~~Fitur Statistik Pembelajaran~~
3. ~~Model Subscription Premium~~
4. ~~Fitur Import/Export Data~~
5. ~~Fitur Notifikasi~~

## Prioritas Sekarang

1. **Perbaikan CRUD Frasa**: Memastikan pengguna dapat menambah, mengubah, dan menghapus frasa dengan andal
2. **UI yang Sederhana namun Intuitif**: Fokus pada kemudahan penggunaan
3. **Mode Pembelajaran Dasar**: Implementasi fitur pembelajaran yang fungsional tanpa kompleksitas berlebihan
4. **Kestabilan Aplikasi**: Memastikan aplikasi berjalan tanpa crash
