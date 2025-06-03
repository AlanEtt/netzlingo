# Konfigurasi AppWrite untuk NetzLingo

Dokumen ini menjelaskan cara mengatur AppWrite untuk mendukung aplikasi NetzLingo, termasuk pengaturan izin yang diperlukan.

## Struktur Database

NetzLingo menggunakan koleksi-koleksi berikut:
- `users`: Informasi pengguna
- `languages`: Daftar bahasa yang didukung
- `categories`: Kategori frasa
- `phrases`: Frasa yang dipelajari
- `tags`: Tag untuk frasa
- `phrase_tags`: Relasi antara frasa dan tag
- `review_history`: Riwayat pembelajaran
- `study_sessions`: Sesi belajar
- `settings`: Pengaturan pengguna
- `subscriptions`: Informasi langganan

## Pengaturan Izin

### 1. Izin Koleksi 

Untuk memastikan data dapat diakses oleh semua jenis akun (termasuk guest), setiap koleksi harus memiliki izin berikut:

**Collection Permissions:**
- Role: `any` - Permission: `read`
- Role: `users` - Permission: `read`, `create`, `update`, `delete` 
- Role: `guests` - Permission: `read`

### 2. Izin Dokumen

Saat membuat dokumen, tambahkan izin spesifik:

```dart
// Pastikan permissions dideklarasikan sebagai List<String>
List<String> permissions = [];
permissions.add(Permission.read(Role.any()));
permissions.add(Permission.read(Role.users()));
permissions.add(Permission.read(Role.guests()));
permissions.add(Permission.update(Role.user(userId)));
permissions.add(Permission.delete(Role.user(userId)));

// Kemudian gunakan saat membuat dokumen
final document = await databases.createDocument(
  // ...
  permissions: permissions,
);
```

> **PENTING:** Selalu gunakan tipe data `List<String>` untuk permissions, bukan `List<dynamic>`. AppWrite SDK mengharapkan tipe yang tepat untuk fungsi ini.

### 3. Dokumen Universal

Untuk dokumen universal yang harus bisa diakses/diupdate oleh semua:

```dart
List<String> permissions = [];
permissions.add(Permission.read(Role.any()));
permissions.add(Permission.read(Role.users()));
permissions.add(Permission.read(Role.guests()));
permissions.add(Permission.update(Role.any()));
```

## Mode Universal

NetzLingo menggunakan pendekatan "akses universal" untuk memungkinkan akses fitur pembelajaran bahkan untuk pengguna yang tidak login atau mengalami masalah izin:

1. Aplikasi akan menyediakan "frasa publik universal" yang diberi userId = 'universal'
2. Ketika terjadi error izin (401 user_unauthorized), aplikasi akan secara otomatis beralih ke mode universal
3. Mode universal menggunakan data publik atau statis yang tersedia untuk semua jenis pengguna

## Pemecahan Masalah Umum

### Error Tipe Data Permissions

Jika Anda mengalami error seperti:
```
The argument type 'List<dynamic>' can't be assigned to the parameter type 'List<String>?'
```

Pastikan untuk:
1. Selalu mendeklarasikan permission list sebagai `List<String>`, bukan `List<dynamic>`
2. Menambahkan permission satu per satu dengan `.add()` daripada menggunakan literal list
3. Hindari penggunaan `.addAll()` dengan literal list

### Error Unauthorized (401)

Jika masih muncul error "Kesalahan Provider Belajar" dengan pesan unauthorized:

1. Pastikan semua koleksi memiliki izin `read` untuk role `any` dan `guests`
2. Hapus cache aplikasi (uninstall lalu install ulang)
3. Periksa pengaturan koleksi di dashboard AppWrite dan pastikan permissions sudah diatur dengan benar
4. Jika menggunakan emulator, restart emulator dan AppWrite server

### Error pada Login/Register

1. Pastikan bahwa layanan AppWrite Account berjalan dengan baik
2. Periksa konfigurasi autentikasi di dashboard AppWrite
3. Pastikan project ID dan endpoint sudah benar di `appwrite_constants.dart`

## Cara Mengatur Dashboard AppWrite

1. Buka dashboard AppWrite di [https://cloud.appwrite.io/console/](https://cloud.appwrite.io/console/)
2. Pilih project "NetzLingo"
3. Buka tab "Database" dan pilih masing-masing koleksi
4. Pada setiap koleksi, klik tab "Settings", lalu "Permissions"
5. Tambahkan izin untuk role `any`, `users`, dan `guests` seperti yang dijelaskan di atas
6. Simpan perubahan

![Contoh Pengaturan Izin](https://i.ibb.co/Hqs9Z5M/appwrite-permissions.png) 