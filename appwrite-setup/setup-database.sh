#!/bin/bash

# Warna untuk output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Memastikan variabel lingkungan tersedia
if [ -z "$1" ]; then
  echo -e "${RED}ERROR: Project ID diperlukan sebagai argumen pertama${NC}"
  echo -e "Contoh: ./setup-database.sh your-project-id your-api-key"
  exit 1
fi

if [ -z "$2" ]; then
  echo -e "${RED}ERROR: API Key diperlukan sebagai argumen kedua${NC}"
  echo -e "Contoh: ./setup-database.sh your-project-id your-api-key"
  exit 1
fi

PROJECT_ID=$1
API_KEY=$2

echo -e "${YELLOW}=========================================${NC}"
echo -e "${YELLOW}   SETUP DATABASE NETZLINGO OTOMATIS     ${NC}"
echo -e "${YELLOW}=========================================${NC}"
echo ""

# Langkah 1: Buat database
echo -e "${YELLOW}Langkah 1: Membuat database...${NC}"
appwrite databases create --projectId=$PROJECT_ID --databaseId=netzlingo_db --name="NetzLingo"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Database berhasil dibuat${NC}"
else
    echo -e "${RED}✗ Gagal membuat database. Periksa apakah database dengan ID tersebut sudah ada${NC}"
    # Tetap lanjutkan proses karena mungkin database sudah ada
fi

# Variabel untuk melacak collection yang berhasil dibuat
SUCCESS_COUNT=0

# Langkah 2: Membuat collections dan atribut dari file JSON
echo -e "\n${YELLOW}Langkah 2: Membuat collections dari JSON...${NC}"

# Baca JSON dan parse collection
COLLECTIONS=$(cat netzlingo-db.json | jq -r '.collections[] | @base64')

for collection in $COLLECTIONS; do
    _jq() {
        echo ${collection} | base64 --decode | jq -r ${1}
    }
    
    COLLECTION_ID=$(_jq '.id')
    COLLECTION_NAME=$(_jq '.name')
    
    echo -e "${YELLOW}Membuat collection: ${COLLECTION_NAME}...${NC}"
    
    # Buat collection
    appwrite databases createCollection --projectId=$PROJECT_ID --databaseId=netzlingo_db --collectionId=$COLLECTION_ID --name="$COLLECTION_NAME" --documentSecurity=true
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Collection ${COLLECTION_NAME} berhasil dibuat${NC}"
        ((SUCCESS_COUNT++))
        
        # Tambahkan atribut
        ATTRIBUTES=$(_jq '.attributes[] | @base64')
        
        for attr in $ATTRIBUTES; do
            _attr() {
                echo ${attr} | base64 --decode | jq -r ${1}
            }
            
            ATTR_KEY=$(_attr '.key')
            ATTR_TYPE=$(_attr '.type')
            ATTR_REQUIRED=$(_attr '.required // false')
            ATTR_DEFAULT=$(_attr '.default // ""')
            
            echo -e "  Menambahkan atribut: ${ATTR_KEY} (${ATTR_TYPE})..."
            
            # Buat perintah berbeda berdasarkan tipe atribut
            if [ "$ATTR_TYPE" == "string" ]; then
                appwrite databases createStringAttribute --projectId=$PROJECT_ID --databaseId=netzlingo_db --collectionId=$COLLECTION_ID --key="$ATTR_KEY" --required=$ATTR_REQUIRED --default="$ATTR_DEFAULT" --array=false
            elif [ "$ATTR_TYPE" == "integer" ]; then
                appwrite databases createIntegerAttribute --projectId=$PROJECT_ID --databaseId=netzlingo_db --collectionId=$COLLECTION_ID --key="$ATTR_KEY" --required=$ATTR_REQUIRED --min=0 --max=1000000 --default=$ATTR_DEFAULT --array=false
            elif [ "$ATTR_TYPE" == "double" ]; then
                appwrite databases createFloatAttribute --projectId=$PROJECT_ID --databaseId=netzlingo_db --collectionId=$COLLECTION_ID --key="$ATTR_KEY" --required=$ATTR_REQUIRED --min=0 --max=1000000 --default=$ATTR_DEFAULT --array=false
            elif [ "$ATTR_TYPE" == "boolean" ]; then
                appwrite databases createBooleanAttribute --projectId=$PROJECT_ID --databaseId=netzlingo_db --collectionId=$COLLECTION_ID --key="$ATTR_KEY" --required=$ATTR_REQUIRED --default=$ATTR_DEFAULT --array=false
            elif [ "$ATTR_TYPE" == "datetime" ]; then
                appwrite databases createDatetimeAttribute --projectId=$PROJECT_ID --databaseId=netzlingo_db --collectionId=$COLLECTION_ID --key="$ATTR_KEY" --required=$ATTR_REQUIRED --array=false
            fi
        done
        
        # Tambahkan indexes
        INDEXES=$(_jq '.indexes[] | @base64')
        
        for idx in $INDEXES; do
            _idx() {
                echo ${idx} | base64 --decode | jq -r ${1}
            }
            
            IDX_KEY=$(_idx '.key')
            IDX_TYPE=$(_idx '.type')
            IDX_ATTRS=$(_idx '.attributes | join(",")')
            
            echo -e "  Menambahkan index: ${IDX_KEY}..."
            
            appwrite databases createIndex --projectId=$PROJECT_ID --databaseId=netzlingo_db --collectionId=$COLLECTION_ID --key="$IDX_KEY" --type="$IDX_TYPE" --attributes="$IDX_ATTRS"
        done
    else
        echo -e "${RED}✗ Gagal membuat collection ${COLLECTION_NAME}. Mungkin sudah ada?${NC}"
    fi
done

# Langkah 3: Menambahkan bahasa default menggunakan script Node.js
echo -e "\n${YELLOW}Langkah 3: Menambahkan data bahasa default...${NC}"

# Perbarui file JavaScript dengan PROJECT_ID dan API_KEY yang benar
sed -i "s/YOUR_PROJECT_ID/$PROJECT_ID/g" add-default-languages.js
sed -i "s/YOUR_API_KEY/$API_KEY/g" add-default-languages.js

# Pastikan node-appwrite sudah diinstal
npm install node-appwrite

# Jalankan script
node add-default-languages.js

# Rangkuman
echo -e "\n${YELLOW}=========================================${NC}"
echo -e "${YELLOW}             RANGKUMAN SETUP             ${NC}"
echo -e "${YELLOW}=========================================${NC}"
echo -e "Database: netzlingo_db"
echo -e "Collections berhasil dibuat: $SUCCESS_COUNT dari 10"
echo -e "\n${GREEN}Setup selesai. Silakan periksa dashboard AppWrite untuk memastikan semua telah terbuat dengan benar.${NC}"
echo -e "URL Dashboard: https://cloud.appwrite.io/console/project-$PROJECT_ID/databases" 