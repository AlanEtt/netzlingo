const sdk = require('node-appwrite');

// Inisialisasi client AppWrite
const client = new sdk.Client();
const databases = new sdk.Databases(client);

// PENTING: Ganti dengan nilai Project ID dan Database ID Anda
const projectId = '683efa6900051e415ec7';
const databaseId = '683efc300031f618f3c2';
// PENTING: Buat API key di AppWrite dashboard dengan permission databases.write
const apiKey = 'standard_369ed0490b9625fa11a888319757d81c6b3fda9ca3997decd8aa38908496d84d27b197cd6acac0130f09795e803c49ddc5c839fb54786a81e6129b1dac968021e20b92e977aa4dc227c2b6c81fb0b6be774f552e0d89f16dd8da481985dc4b51ea7fc8cbed941d80043a5ee19a331fb1bcf97d0307c6de529b581846d3e507d9';

client
  .setEndpoint('https://cloud.appwrite.io/v1')
  .setProject(projectId)
  .setKey(apiKey);

// Fungsi untuk membuat collection
async function createCollection(collectionId, name) {
  try {
    // Dalam versi terbaru, permissions tidak perlu di-set pada pembuatan collection
    const result = await databases.createCollection(
      databaseId,
      collectionId,
      name
    );
    
    console.log(`✅ Collection berhasil dibuat: ${name}`);
    return result;
  } catch (error) {
    if (error.code === 409) {
      console.log(`⚠️ Collection ${name} sudah ada, melanjutkan...`);
      return { $id: collectionId };
    } else {
      console.error(`❌ Gagal membuat collection ${name}:`, error.message);
      throw error;
    }
  }
}

// Fungsi untuk membuat atribut string
async function createStringAttribute(collectionId, key, size, required, defaultValue = null, array = false) {
  try {
    // Pastikan size tidak melebihi batas maksimum
    const validSize = Math.min(size, 1073741824); // Batas maksimum yang diizinkan AppWrite
    
    const result = await databases.createStringAttribute(
      databaseId,
      collectionId,
      key,
      validSize,
      required,
      defaultValue,
      array
    );
    console.log(`  ✓ Atribut string berhasil dibuat: ${key}`);
    return result;
  } catch (error) {
    if (error.code === 409) {
      console.log(`  ⚠️ Atribut ${key} sudah ada, melanjutkan...`);
    } else {
      console.error(`  ❌ Gagal membuat atribut ${key}:`, error.message);
    }
  }
}

// Fungsi untuk membuat atribut integer
async function createIntegerAttribute(collectionId, key, required, min = null, max = null, defaultValue = null, array = false) {
  try {
    const result = await databases.createIntegerAttribute(
      databaseId,
      collectionId,
      key,
      required,
      min,
      max,
      defaultValue,
      array
    );
    console.log(`  ✓ Atribut integer berhasil dibuat: ${key}`);
    return result;
  } catch (error) {
    if (error.code === 409) {
      console.log(`  ⚠️ Atribut ${key} sudah ada, melanjutkan...`);
    } else {
      console.error(`  ❌ Gagal membuat atribut ${key}:`, error.message);
    }
  }
}

// Fungsi untuk membuat atribut boolean
async function createBooleanAttribute(collectionId, key, required, defaultValue = null, array = false) {
  try {
    const result = await databases.createBooleanAttribute(
      databaseId,
      collectionId,
      key,
      required,
      defaultValue,
      array
    );
    console.log(`  ✓ Atribut boolean berhasil dibuat: ${key}`);
    return result;
  } catch (error) {
    if (error.code === 409) {
      console.log(`  ⚠️ Atribut ${key} sudah ada, melanjutkan...`);
    } else {
      console.error(`  ❌ Gagal membuat atribut ${key}:`, error.message);
    }
  }
}

// Fungsi untuk membuat atribut datetime
async function createDatetimeAttribute(collectionId, key, required, defaultValue = null, array = false) {
  try {
    // Jika defaultValue adalah "now()", kita ganti dengan tanggal saat ini dalam ISO string
    if (defaultValue === 'now()') {
      defaultValue = new Date().toISOString();
    }
    
    const result = await databases.createDatetimeAttribute(
      databaseId,
      collectionId,
      key,
      required,
      defaultValue,
      array
    );
    console.log(`  ✓ Atribut datetime berhasil dibuat: ${key}`);
    return result;
  } catch (error) {
    if (error.code === 409) {
      console.log(`  ⚠️ Atribut ${key} sudah ada, melanjutkan...`);
    } else {
      console.error(`  ❌ Gagal membuat atribut ${key}:`, error.message);
    }
  }
}

// Fungsi untuk membuat atribut float/double
async function createFloatAttribute(collectionId, key, required, min = null, max = null, defaultValue = null, array = false) {
  try {
    const result = await databases.createFloatAttribute(
      databaseId,
      collectionId,
      key,
      required,
      min,
      max,
      defaultValue,
      array
    );
    console.log(`  ✓ Atribut float berhasil dibuat: ${key}`);
    return result;
  } catch (error) {
    if (error.code === 409) {
      console.log(`  ⚠️ Atribut ${key} sudah ada, melanjutkan...`);
    } else {
      console.error(`  ❌ Gagal membuat atribut ${key}:`, error.message);
    }
  }
}

// Fungsi untuk membuat indeks
async function createIndex(collectionId, key, type, attributes) {
  try {
    const result = await databases.createIndex(
      databaseId,
      collectionId,
      key,
      type,
      attributes
    );
    console.log(`  ✓ Indeks berhasil dibuat: ${key}`);
    return result;
  } catch (error) {
    if (error.code === 409) {
      console.log(`  ⚠️ Indeks ${key} sudah ada, melanjutkan...`);
    } else {
      console.error(`  ❌ Gagal membuat indeks ${key}:`, error.message);
    }
  }
}

// Fungsi untuk menunggu (karena kita perlu menunggu atribut selesai dibuat sebelum membuat indeks)
function waitFor(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

// Fungsi utama untuk setup database
async function setupDatabase() {
  console.log('🚀 Mulai setup database...');
  
  try {
    // 1. Collection Users
    console.log('\n📊 Membuat collection Users...');
    const usersCollection = await createCollection('users', 'Users');
    
    await createStringAttribute('users', 'name', 255, true);
    await createStringAttribute('users', 'email', 255, true);
    await createBooleanAttribute('users', 'is_premium', false, false);
    await createIntegerAttribute('users', 'daily_goal', false, 0, null, 10);
    await createStringAttribute('users', 'preferred_language', 10, false, 'id');
    await createDatetimeAttribute('users', 'created_at', false, new Date().toISOString());
    await createDatetimeAttribute('users', 'updated_at', false, new Date().toISOString());
    
    // Tunggu atribut selesai dibuat sebelum membuat indeks
    await waitFor(2000);
    
    await createIndex('users', 'email_index', 'unique', ['email']);
    
    // 2. Collection Languages
    console.log('\n📊 Membuat collection Languages...');
    const languagesCollection = await createCollection('languages', 'Languages');
    
    await createStringAttribute('languages', 'name', 255, true);
    await createStringAttribute('languages', 'code', 10, true);
    await createStringAttribute('languages', 'flag_icon', 10, false);
    await createDatetimeAttribute('languages', 'created_at', false, new Date().toISOString());
    await createDatetimeAttribute('languages', 'updated_at', false, new Date().toISOString());
    
    await waitFor(2000);
    
    await createIndex('languages', 'code_index', 'unique', ['code']);
    
    // 3. Collection Categories
    console.log('\n📊 Membuat collection Categories...');
    const categoriesCollection = await createCollection('categories', 'Categories');
    
    await createStringAttribute('categories', 'name', 255, true);
    await createStringAttribute('categories', 'description', 1000, false, '');
    await createStringAttribute('categories', 'language_id', 36, false);
    await createStringAttribute('categories', 'user_id', 36, true);
    await createDatetimeAttribute('categories', 'created_at', false, new Date().toISOString());
    await createDatetimeAttribute('categories', 'updated_at', false, new Date().toISOString());
    
    await waitFor(2000);
    
    await createIndex('categories', 'user_id_index', 'key', ['user_id']);
    await createIndex('categories', 'user_name_index', 'key', ['user_id', 'name']);
    
    // 4. Collection Phrases
    console.log('\n📊 Membuat collection Phrases...');
    const phrasesCollection = await createCollection('phrases', 'Phrases');
    
    await createStringAttribute('phrases', 'original_text', 1000, true);
    await createStringAttribute('phrases', 'translated_text', 1000, true);
    await createStringAttribute('phrases', 'language_id', 36, true);
    await createStringAttribute('phrases', 'category_id', 36, false);
    await createStringAttribute('phrases', 'user_id', 36, true);
    await createStringAttribute('phrases', 'notes', 1000, false, '');
    await createBooleanAttribute('phrases', 'is_favorite', false, false);
    await createIntegerAttribute('phrases', 'importance', false, 1, 5, 1);
    await createDatetimeAttribute('phrases', 'created_at', false, new Date().toISOString());
    await createDatetimeAttribute('phrases', 'updated_at', false, new Date().toISOString());
    
    await waitFor(2000);
    
    await createIndex('phrases', 'user_id_index', 'key', ['user_id']);
    await createIndex('phrases', 'language_id_index', 'key', ['language_id']);
    await createIndex('phrases', 'category_id_index', 'key', ['category_id']);
    
    // 5. Collection Tags
    console.log('\n📊 Membuat collection Tags...');
    const tagsCollection = await createCollection('tags', 'Tags');
    
    await createStringAttribute('tags', 'name', 100, true);
    await createStringAttribute('tags', 'color', 20, false, '#2196F3');
    await createStringAttribute('tags', 'user_id', 36, true);
    await createDatetimeAttribute('tags', 'created_at', false, new Date().toISOString());
    
    await waitFor(2000);
    
    await createIndex('tags', 'user_id_index', 'key', ['user_id']);
    await createIndex('tags', 'user_name_index', 'unique', ['user_id', 'name']);
    
    // 6. Collection PhraseTags
    console.log('\n📊 Membuat collection PhraseTags...');
    const phraseTagsCollection = await createCollection('phrase_tags', 'PhraseTags');
    
    await createStringAttribute('phrase_tags', 'phrase_id', 36, true);
    await createStringAttribute('phrase_tags', 'tag_id', 36, true);
    await createStringAttribute('phrase_tags', 'user_id', 36, true);
    
    await waitFor(2000);
    
    await createIndex('phrase_tags', 'phrase_tag_index', 'unique', ['phrase_id', 'tag_id']);
    await createIndex('phrase_tags', 'user_id_index', 'key', ['user_id']);
    
    // 7. Collection ReviewHistory
    console.log('\n📊 Membuat collection ReviewHistory...');
    const reviewHistoryCollection = await createCollection('review_history', 'ReviewHistory');
    
    await createStringAttribute('review_history', 'phrase_id', 36, true);
    await createStringAttribute('review_history', 'user_id', 36, true);
    await createDatetimeAttribute('review_history', 'review_date', true);
    await createBooleanAttribute('review_history', 'was_correct', true);
    await createFloatAttribute('review_history', 'ease_factor', false, 1.0, 3.0, 2.5);
    await createIntegerAttribute('review_history', 'interval', false, 1, null, 1);
    
    await waitFor(2000);
    
    await createIndex('review_history', 'user_id_index', 'key', ['user_id']);
    await createIndex('review_history', 'phrase_id_index', 'key', ['phrase_id']);
    await createIndex('review_history', 'review_date_index', 'key', ['review_date']);
    
    // 8. Collection StudySessions
    console.log('\n📊 Membuat collection StudySessions...');
    const studySessionsCollection = await createCollection('study_sessions', 'StudySessions');
    
    await createStringAttribute('study_sessions', 'user_id', 36, true);
    await createDatetimeAttribute('study_sessions', 'start_time', true);
    await createDatetimeAttribute('study_sessions', 'end_time', false);
    await createIntegerAttribute('study_sessions', 'total_phrases', true);
    await createIntegerAttribute('study_sessions', 'correct_answers', true);
    await createStringAttribute('study_sessions', 'session_type', 100, true);
    await createStringAttribute('study_sessions', 'language_id', 36, false);
    await createStringAttribute('study_sessions', 'category_id', 36, false);
    
    await waitFor(2000);
    
    await createIndex('study_sessions', 'user_id_index', 'key', ['user_id']);
    await createIndex('study_sessions', 'start_time_index', 'key', ['start_time']);
    
    // 9. Collection Settings
    console.log('\n📊 Membuat collection Settings...');
    const settingsCollection = await createCollection('settings', 'Settings');
    
    await createStringAttribute('settings', 'user_id', 36, true);
    await createStringAttribute('settings', 'app_language', 10, false, 'id');
    await createStringAttribute('settings', 'theme', 20, false, 'light');
    await createBooleanAttribute('settings', 'is_dark_mode', false, false);
    await createBooleanAttribute('settings', 'enable_tts', false, true);
    await createBooleanAttribute('settings', 'enable_notifications', false, true);
    await createStringAttribute('settings', 'notification_time', 10, false, '20:00');
    await createIntegerAttribute('settings', 'daily_goal', false, 0, null, 10);
    await createIntegerAttribute('settings', 'daily_session_count', false, 0, null, 0);
    await createDatetimeAttribute('settings', 'last_session_date', false);
    await createDatetimeAttribute('settings', 'updated_at', false, new Date().toISOString());
    
    await waitFor(2000);
    
    await createIndex('settings', 'user_id_index', 'unique', ['user_id']);
    
    // 10. Collection Subscriptions
    console.log('\n📊 Membuat collection Subscriptions...');
    const subscriptionsCollection = await createCollection('subscriptions', 'Subscriptions');
    
    await createStringAttribute('subscriptions', 'user_id', 36, true);
    await createStringAttribute('subscriptions', 'plan_type', 50, true);
    await createDatetimeAttribute('subscriptions', 'start_date', true);
    await createDatetimeAttribute('subscriptions', 'end_date', true);
    await createBooleanAttribute('subscriptions', 'is_active', false, true);
    await createStringAttribute('subscriptions', 'payment_method', 50, false);
    await createDatetimeAttribute('subscriptions', 'created_at', false, new Date().toISOString());
    await createDatetimeAttribute('subscriptions', 'updated_at', false, new Date().toISOString());
    
    await waitFor(2000);
    
    await createIndex('subscriptions', 'user_id_index', 'unique', ['user_id']);
    await createIndex('subscriptions', 'end_date_index', 'key', ['end_date']);
    
    console.log('\n🎉 Setup database selesai!');
  } catch (error) {
    console.error('❌ Terjadi kesalahan:', error);
  }
}

// Jalankan fungsi setup
setupDatabase(); 