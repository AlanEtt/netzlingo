#!/bin/bash

echo "===== SETUP DATABASE APPWRITE UNTUK NETZLINGO ====="
echo

echo "[1/3] Menginstall dependensi..."
npm install
if [ $? -ne 0 ]; then
    echo "Gagal menginstall dependensi!"
    exit 1
fi
echo "Dependensi berhasil diinstall."
echo

echo "[2/3] Menjalankan script setup database..."
node setup-database.js
if [ $? -ne 0 ]; then
    echo "Gagal setup database!"
    exit 1
fi
echo "Database berhasil disetup."
echo

echo "[3/3] Menambahkan data bahasa default..."
node add-default-languages.js
if [ $? -ne 0 ]; then
    echo "Gagal menambahkan data bahasa default!"
    exit 1
fi
echo "Data bahasa default berhasil ditambahkan."
echo

echo "===== SETUP SELESAI ====="
echo
echo "Sekarang database AppWrite untuk NetzLingo sudah siap digunakan!"
echo "Anda dapat membuka dashboard AppWrite untuk memeriksa hasilnya."
echo
read -p "Tekan ENTER untuk melanjutkan..." 