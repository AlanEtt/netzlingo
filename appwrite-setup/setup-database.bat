@echo off
echo ========================================
echo    SETUP DATABASE NETZLINGO OTOMATIS    
echo ========================================
echo.

REM Periksa apakah argumen diberikan
if "%~1"=="" (
    echo ERROR: Project ID diperlukan sebagai argumen pertama
    echo Contoh: setup-database.bat your-project-id your-api-key
    exit /b 1
)

if "%~2"=="" (
    echo ERROR: API Key diperlukan sebagai argumen kedua
    echo Contoh: setup-database.bat your-project-id your-api-key
    exit /b 1
)

set PROJECT_ID=%~1
set API_KEY=%~2

REM Langkah 1: Buat database
echo Langkah 1: Membuat database...
appwrite databases create --projectId=%PROJECT_ID% databaseId=netzlingo_db name="NetzLingo"

REM Langkah 2: Install node-appwrite
echo.
echo Langkah 2: Menginstal node-appwrite...
npm install

REM Langkah 3: Update file JavaScript dengan PROJECT_ID dan API_KEY
echo.
echo Langkah 3: Mempersiapkan script untuk data default...
powershell -Command "(Get-Content add-default-languages.js) | ForEach-Object { $_ -replace 'YOUR_PROJECT_ID', '%PROJECT_ID%' } | Set-Content add-default-languages.js"
powershell -Command "(Get-Content add-default-languages.js) | ForEach-Object { $_ -replace 'YOUR_API_KEY', '%API_KEY%' } | Set-Content add-default-languages.js"

REM Langkah 4: Jalankan script untuk menambahkan bahasa default
echo.
echo Langkah 4: Menambahkan data bahasa default...
node add-default-languages.js

REM Langkah 5: Petunjuk manual untuk membuat collections
echo.
echo ========================================
echo         PETUNJUK MEMBUAT COLLECTIONS   
echo ========================================
echo.
echo Untuk membuat collections, silakan ikuti langkah-langkah berikut:
echo 1. Buka dashboard AppWrite: https://cloud.appwrite.io/console/project-%PROJECT_ID%/databases
echo 2. Pilih database "NetzLingo"
echo 3. Klik "Create Collection" dan buat 10 collections sesuai dokumentasi
echo.
echo Anda juga bisa menggunakan AppWrite CLI untuk membuat collections satu per satu.
echo.
echo Setup selesai. Silakan periksa dashboard AppWrite untuk memastikan semua telah terbuat dengan benar.
echo URL Dashboard: https://cloud.appwrite.io/console/project-%PROJECT_ID%/databases

pause 