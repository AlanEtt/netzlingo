@echo off
echo ===== SETUP DATABASE APPWRITE UNTUK NETZLINGO =====
echo.

echo [1/3] Menginstall dependensi...
call npm install
if %ERRORLEVEL% NEQ 0 (
    echo Gagal menginstall dependensi!
    exit /b %ERRORLEVEL%
)
echo Dependensi berhasil diinstall.
echo.

echo [2/3] Menjalankan script setup database...
node setup-database.js
if %ERRORLEVEL% NEQ 0 (
    echo Gagal setup database!
    exit /b %ERRORLEVEL%
)
echo Database berhasil disetup.
echo.

echo [3/3] Menambahkan data bahasa default...
node add-default-languages.js
if %ERRORLEVEL% NEQ 0 (
    echo Gagal menambahkan data bahasa default!
    exit /b %ERRORLEVEL%
)
echo Data bahasa default berhasil ditambahkan.
echo.

echo ===== SETUP SELESAI =====
echo.
echo Sekarang database AppWrite untuk NetzLingo sudah siap digunakan!
echo Anda dapat membuka dashboard AppWrite untuk memeriksa hasilnya.
echo.
pause 