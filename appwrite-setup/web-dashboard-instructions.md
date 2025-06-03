# Petunjuk Setup Database AppWrite menggunakan Web Dashboard

Karena ada masalah dengan script CLI, mari kita gunakan Web Dashboard AppWrite untuk mengatur database dengan cepat.

## 1. Login ke AppWrite Dashboard

1. Buka [https://cloud.appwrite.io/console](https://cloud.appwrite.io/console)
2. Login dengan akun yang Anda gunakan

## 2. Pilih Project NetzLingo

1. Pilih project "NetzLingo" (dengan Project ID: 683efa6900051e415ec7)
2. Pastikan platform Flutter sudah terdaftar (jika belum, tambahkan dengan mengklik "Add Platform")

## 3. Menggunakan Database yang Sudah Dibuat

1. Klik "Databases" di sidebar kiri
2. Anda akan melihat database dengan ID: 683efc300031f618f3c2
3. Pastikan "Enable Document Security" dicentang (penting untuk keamanan)

## 4. Buat Collection dan Atribut

Sekarang buat 10 collection berikut (satu per satu):

### Collection 1: Users
1. Klik "Create Collection"
2. Isi informasi:
   - Name: Users
   - Collection ID: users
   - Enable Document Security: Dicentang
3. Klik "Create"
4. Tambahkan atribut-atribut berikut:
   - name (string, required)
   - email (string, required)
   - is_premium (boolean, default: false)
   - daily_goal (integer, default: 10)
   - preferred_language (string, default: "id")
   - created_at (datetime, default: now())
   - updated_at (datetime, default: now())
5. Tambahkan index:
   - email_index (unique, field: email)

### Collection 2: Languages
1. Klik "Create Collection"
2. Isi informasi:
   - Name: Languages
   - Collection ID: languages
   - Enable Document Security: Dicentang
3. Klik "Create"
4. Tambahkan atribut-atribut berikut:
   - name (string, required)
   - code (string, required)
   - flag_icon (string, optional)
   - created_at (datetime, default: now())
   - updated_at (datetime, default: now())
5. Tambahkan index:
   - code_index (unique, field: code)
6. Tambahkan 5 dokumen bahasa:
   - English (en, 🇬🇧)
   - Bahasa Indonesia (id, 🇮🇩)
   - French (fr, 🇫🇷)
   - Spanish (es, 🇪🇸)
   - Japanese (ja, 🇯🇵)

### Collection 3: Categories
1. Klik "Create Collection"
2. Isi informasi:
   - Name: Categories
   - Collection ID: categories
   - Enable Document Security: Dicentang
3. Klik "Create"
4. Tambahkan atribut-atribut berikut:
   - name (string, required)
   - description (string, default: "")
   - language_id (string, optional)
   - user_id (string, required)
   - created_at (datetime, default: now())
   - updated_at (datetime, default: now())
5. Tambahkan index:
   - user_id_index (key, field: user_id)
   - user_name_index (key, fields: user_id, name)

### Collection 4: Phrases
1. Klik "Create Collection"
2. Isi informasi:
   - Name: Phrases
   - Collection ID: phrases
   - Enable Document Security: Dicentang
3. Klik "Create"
4. Tambahkan atribut-atribut berikut:
   - original_text (string, required)
   - translated_text (string, required)
   - language_id (string, required)
   - category_id (string, optional)
   - user_id (string, required)
   - notes (string, default: "")
   - is_favorite (boolean, default: false)
   - importance (integer, default: 1)
   - created_at (datetime, default: now())
   - updated_at (datetime, default: now())
5. Tambahkan index:
   - user_id_index (key, field: user_id)
   - language_id_index (key, field: language_id)
   - category_id_index (key, field: category_id)

### Collection 5: Tags
1. Klik "Create Collection"
2. Isi informasi:
   - Name: Tags
   - Collection ID: tags
   - Enable Document Security: Dicentang
3. Klik "Create"
4. Tambahkan atribut-atribut berikut:
   - name (string, required)
   - color (string, default: "#2196F3")
   - user_id (string, required)
   - created_at (datetime, default: now())
5. Tambahkan index:
   - user_id_index (key, field: user_id)
   - user_name_index (unique, fields: user_id, name)

### Collection 6: PhraseTags
1. Klik "Create Collection"
2. Isi informasi:
   - Name: PhraseTags
   - Collection ID: phrase_tags
   - Enable Document Security: Dicentang
3. Klik "Create"
4. Tambahkan atribut-atribut berikut:
   - phrase_id (string, required)
   - tag_id (string, required)
   - user_id (string, required)
5. Tambahkan index:
   - phrase_tag_index (unique, fields: phrase_id, tag_id)
   - user_id_index (key, field: user_id)

### Collection 7: ReviewHistory
1. Klik "Create Collection"
2. Isi informasi:
   - Name: ReviewHistory
   - Collection ID: review_history
   - Enable Document Security: Dicentang
3. Klik "Create"
4. Tambahkan atribut-atribut berikut:
   - phrase_id (string, required)
   - user_id (string, required)
   - review_date (datetime, required)
   - was_correct (boolean, required)
   - ease_factor (double, default: 2.5)
   - interval (integer, default: 1)
5. Tambahkan index:
   - user_id_index (key, field: user_id)
   - phrase_id_index (key, field: phrase_id)
   - review_date_index (key, field: review_date)

### Collection 8: StudySessions
1. Klik "Create Collection"
2. Isi informasi:
   - Name: StudySessions
   - Collection ID: study_sessions
   - Enable Document Security: Dicentang
3. Klik "Create"
4. Tambahkan atribut-atribut berikut:
   - user_id (string, required)
   - start_time (datetime, required)
   - end_time (datetime, optional)
   - total_phrases (integer, required)
   - correct_answers (integer, required)
   - session_type (string, required)
   - language_id (string, optional)
   - category_id (string, optional)
5. Tambahkan index:
   - user_id_index (key, field: user_id)
   - start_time_index (key, field: start_time)

### Collection 9: Settings
1. Klik "Create Collection"
2. Isi informasi:
   - Name: Settings
   - Collection ID: settings
   - Enable Document Security: Dicentang
3. Klik "Create"
4. Tambahkan atribut-atribut berikut:
   - user_id (string, required)
   - app_language (string, default: "id")
   - theme (string, default: "light")
   - is_dark_mode (boolean, default: false)
   - enable_tts (boolean, default: true)
   - enable_notifications (boolean, default: true)
   - notification_time (string, default: "20:00")
   - daily_goal (integer, default: 10)
   - daily_session_count (integer, default: 0)
   - last_session_date (datetime, optional)
   - updated_at (datetime, default: now())
5. Tambahkan index:
   - user_id_index (unique, field: user_id)

### Collection 10: Subscriptions
1. Klik "Create Collection"
2. Isi informasi:
   - Name: Subscriptions
   - Collection ID: subscriptions
   - Enable Document Security: Dicentang
3. Klik "Create"
4. Tambahkan atribut-atribut berikut:
   - user_id (string, required)
   - plan_type (string, required)
   - start_date (datetime, required)
   - end_date (datetime, required)
   - is_active (boolean, default: true)
   - payment_method (string, optional)
   - created_at (datetime, default: now())
   - updated_at (datetime, default: now())
5. Tambahkan index:
   - user_id_index (unique, field: user_id)
   - end_date_index (key, field: end_date)

## 5. Mengatur Permissions

Untuk setiap collection, atur permission:
1. Klik pada collection
2. Klik tab "Settings"
3. Klik "Permissions"
4. Tambahkan role "any authenticated user" dengan akses Create, Read, Update, Delete untuk document level

## 6. Verifikasi Integrasi

1. Jalankan aplikasi Flutter
2. Test koneksi dengan fitur "Send a ping"
3. Verifikasi bahwa aplikasi dapat terhubung ke AppWrite

Dengan mengikuti langkah-langkah di atas, Anda akan memiliki database AppWrite yang sepenuhnya dikonfigurasi untuk NetzLingo! 