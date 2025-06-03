const sdk = require('node-appwrite');

// Inisialisasi client AppWrite
const client = new sdk.Client();
const databases = new sdk.Databases(client);

// PENTING: Ganti dengan nilai Project ID Anda dari dashboard AppWrite
const projectId = '683efa6900051e415ec7';
// PENTING: Buat API key di AppWrite dashboard dengan permission databases.write
const apiKey = 'standard_369ed0490b9625fa11a888319757d81c6b3fda9ca3997decd8aa38908496d84d27b197cd6acac0130f09795e803c49ddc5c839fb54786a81e6129b1dac968021e20b92e977aa4dc227c2b6c81fb0b6be774f552e0d89f16dd8da481985dc4b51ea7fc8cbed941d80043a5ee19a331fb1bcf97d0307c6de529b581846d3e507d9';

client
  .setEndpoint('https://cloud.appwrite.io/v1')
  .setProject(projectId)
  .setKey(apiKey);

// Data bahasa default yang akan ditambahkan
const languages = [
  { name: 'English', code: 'en', flag_icon: '🇬🇧', created_at: new Date().toISOString(), updated_at: new Date().toISOString() },
  { name: 'Bahasa Indonesia', code: 'id', flag_icon: '🇮🇩', created_at: new Date().toISOString(), updated_at: new Date().toISOString() },
  { name: 'French', code: 'fr', flag_icon: '🇫🇷', created_at: new Date().toISOString(), updated_at: new Date().toISOString() },
  { name: 'Spanish', code: 'es', flag_icon: '🇪🇸', created_at: new Date().toISOString(), updated_at: new Date().toISOString() },
  { name: 'Japanese', code: 'ja', flag_icon: '🇯🇵', created_at: new Date().toISOString(), updated_at: new Date().toISOString() }
];

// Fungsi untuk menambahkan bahasa default
async function addDefaultLanguages() {
  console.log('Mulai menambahkan bahasa default...');
  
  for (const language of languages) {
    try {
      const result = await databases.createDocument(
        '683efc300031f618f3c2',
        'languages',
        sdk.ID.unique(),
        language
      );
      console.log(`✅ Berhasil menambahkan bahasa: ${language.name} (${language.code})`);
    } catch (error) {
      console.error(`❌ Gagal menambahkan bahasa ${language.name}:`, error.message);
    }
  }
  
  console.log('Proses penambahan bahasa selesai.');
}

// Jalankan fungsi
addDefaultLanguages(); 