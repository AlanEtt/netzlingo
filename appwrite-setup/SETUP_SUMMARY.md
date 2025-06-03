# Ringkasan Setup Database AppWrite untuk NetzLingo

## Informasi Konfigurasi

- **Project ID**: `683efa6900051e415ec7`
- **Database ID**: `683efc300031f618f3c2`

## Database yang Dibuat

Database telah berhasil dibuat dengan 10 collection:

1. **Users** - Informasi pengguna aplikasi
   - Atribut: name, email, is_premium, daily_goal, preferred_language, created_at, updated_at
   - Indeks: email_index (unique)

2. **Languages** - Bahasa yang tersedia
   - Atribut: name, code, flag_icon, created_at, updated_at
   - Indeks: code_index (unique)
   - Data default: English (en), Bahasa Indonesia (id), French (fr), Spanish (es), Japanese (ja)

3. **Categories** - Kategori frasa
   - Atribut: name, description, language_id, user_id, created_at, updated_at
   - Indeks: user_id_index, user_name_index

4. **Phrases** - Frasa-frasa yang disimpan
   - Atribut: original_text, translated_text, language_id, category_id, user_id, notes, is_favorite, importance, created_at, updated_at
   - Indeks: user_id_index, language_id_index, category_id_index

5. **Tags** - Tag untuk mengkategorikan frasa
   - Atribut: name, color, user_id, created_at
   - Indeks: user_id_index, user_name_index (unique)

6. **PhraseTags** - Relasi antara frasa dan tag
   - Atribut: phrase_id, tag_id, user_id
   - Indeks: phrase_tag_index (unique), user_id_index

7. **ReviewHistory** - Riwayat review frasa
   - Atribut: phrase_id, user_id, review_date, was_correct, ease_factor, interval
   - Indeks: user_id_index, phrase_id_index, review_date_index

8. **StudySessions** - Sesi belajar pengguna
   - Atribut: user_id, start_time, end_time, total_phrases, correct_answers, session_type, language_id, category_id
   - Indeks: user_id_index, start_time_index

9. **Settings** - Pengaturan aplikasi untuk pengguna
   - Atribut: user_id, app_language, theme, is_dark_mode, enable_tts, enable_notifications, notification_time, daily_goal, daily_session_count, last_session_date, updated_at
   - Indeks: user_id_index (unique)

10. **Subscriptions** - Informasi langganan pengguna
    - Atribut: user_id, plan_type, start_date, end_date, is_active, payment_method, created_at, updated_at
    - Indeks: user_id_index (unique), end_date_index

## Script yang Digunakan

- **setup-database.js** - Script untuk membuat semua collection dan atribut
- **add-default-languages.js** - Script untuk menambahkan data bahasa default

## Cara Menjalankan Setup Lagi (Jika Diperlukan)

### Windows
```
setup.bat
```

### Linux/Mac
```
chmod +x setup.sh
./setup.sh
```

## Selanjutnya

Setelah setup selesai, Anda dapat mulai menggunakan database AppWrite di aplikasi Flutter Anda. Pastikan file konfigurasi di `lib/config/appwrite_constants.dart` memiliki nilai-nilai yang benar. 