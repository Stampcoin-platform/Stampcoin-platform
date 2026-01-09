#!/bin/bash

###############################################################################
# نظام النسخ الاحتياطي التلقائي - Stampcoin Platform
# Automatic Backup System
# Copyright © 2024-2026 Stampcoin Platform. All Rights Reserved.
###############################################################################

# الألوان للإخراج
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# المتغيرات الأساسية
PROJECT_ROOT="/workspaces/Stampcoin-platform"
BACKUP_DIR="$PROJECT_ROOT/backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_NAME="backup_${TIMESTAMP}"
BACKUP_PATH="$BACKUP_DIR/$BACKUP_NAME"

# إنشاء مجلد النسخ الاحتياطي
mkdir -p "$BACKUP_PATH"

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}   🔄 بدء عملية النسخ الاحتياطي التلقائي${NC}"
echo -e "${GREEN}   Starting Automatic Backup Process${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# دالة للنسخ مع السجل
backup_item() {
    local source=$1
    local dest=$2
    local name=$3
    
    if [ -e "$source" ]; then
        cp -r "$source" "$dest/" 2>/dev/null && \
        echo -e "${GREEN}✅${NC} تم نسخ: $name" || \
        echo -e "${RED}❌${NC} فشل نسخ: $name"
    else
        echo -e "${YELLOW}⚠️${NC}  غير موجود: $name"
    fi
}

# نسخ الملفات القانونية والحماية
echo -e "${BLUE}📋 نسخ الملفات القانونية...${NC}"
backup_item "$PROJECT_ROOT/LICENSE" "$BACKUP_PATH" "LICENSE"
backup_item "$PROJECT_ROOT/COPYRIGHT" "$BACKUP_PATH" "COPYRIGHT"
backup_item "$PROJECT_ROOT/INTELLECTUAL_PROPERTY.md" "$BACKUP_PATH" "INTELLECTUAL_PROPERTY.md"
backup_item "$PROJECT_ROOT/TRADEMARK_NOTICE.md" "$BACKUP_PATH" "TRADEMARK_NOTICE.md"
backup_item "$PROJECT_ROOT/LEGAL_PROTECTION_GUIDE.md" "$BACKUP_PATH" "LEGAL_PROTECTION_GUIDE.md"
backup_item "$PROJECT_ROOT/COPYRIGHT_HEADER.txt" "$BACKUP_PATH" "COPYRIGHT_HEADER.txt"
backup_item "$PROJECT_ROOT/IP_PROTECTION_COMPLETE.md" "$BACKUP_PATH" "IP_PROTECTION_COMPLETE.md"
backup_item "$PROJECT_ROOT/IP_PROTECTION_SUMMARY.md" "$BACKUP_PATH" "IP_PROTECTION_SUMMARY.md"
backup_item "$PROJECT_ROOT/IP_PROTECTED.txt" "$BACKUP_PATH" "IP_PROTECTED.txt"
backup_item "$PROJECT_ROOT/IP_DOCUMENTS_INDEX.md" "$BACKUP_PATH" "IP_DOCUMENTS_INDEX.md"
backup_item "$PROJECT_ROOT/IP_QUICK_START.md" "$BACKUP_PATH" "IP_QUICK_START.md"
echo ""

# نسخ الملفات الأساسية
echo -e "${BLUE}⚙️  نسخ الملفات الأساسية...${NC}"
backup_item "$PROJECT_ROOT/package.json" "$BACKUP_PATH" "package.json"
backup_item "$PROJECT_ROOT/package-lock.json" "$BACKUP_PATH" "package-lock.json"
backup_item "$PROJECT_ROOT/pnpm-lock.yaml" "$BACKUP_PATH" "pnpm-lock.yaml"
backup_item "$PROJECT_ROOT/tsconfig.json" "$BACKUP_PATH" "tsconfig.json"
backup_item "$PROJECT_ROOT/vite.config.ts" "$BACKUP_PATH" "vite.config.ts"
backup_item "$PROJECT_ROOT/drizzle.config.ts" "$BACKUP_PATH" "drizzle.config.ts"
backup_item "$PROJECT_ROOT/README.md" "$BACKUP_PATH" "README.md"
backup_item "$PROJECT_ROOT/.gitignore" "$BACKUP_PATH" ".gitignore"
backup_item "$PROJECT_ROOT/.gitattributes" "$BACKUP_PATH" ".gitattributes"
backup_item "$PROJECT_ROOT/docker-compose.yml" "$BACKUP_PATH" "docker-compose.yml"
backup_item "$PROJECT_ROOT/Dockerfile" "$BACKUP_PATH" "Dockerfile"
echo ""

# نسخ مجلدات المصدر
echo -e "${BLUE}📁 نسخ مجلدات المصدر...${NC}"
if [ -d "$PROJECT_ROOT/server" ]; then
    mkdir -p "$BACKUP_PATH/server"
    cp -r "$PROJECT_ROOT/server/"* "$BACKUP_PATH/server/" 2>/dev/null
    echo -e "${GREEN}✅${NC} تم نسخ: server/"
fi

if [ -d "$PROJECT_ROOT/client" ]; then
    mkdir -p "$BACKUP_PATH/client"
    cp -r "$PROJECT_ROOT/client/"* "$BACKUP_PATH/client/" 2>/dev/null
    echo -e "${GREEN}✅${NC} تم نسخ: client/"
fi

if [ -d "$PROJECT_ROOT/drizzle" ]; then
    mkdir -p "$BACKUP_PATH/drizzle"
    cp -r "$PROJECT_ROOT/drizzle/"* "$BACKUP_PATH/drizzle/" 2>/dev/null
    echo -e "${GREEN}✅${NC} تم نسخ: drizzle/"
fi

if [ -d "$PROJECT_ROOT/public" ]; then
    mkdir -p "$BACKUP_PATH/public"
    cp -r "$PROJECT_ROOT/public/"* "$BACKUP_PATH/public/" 2>/dev/null
    echo -e "${GREEN}✅${NC} تم نسخ: public/"
fi
echo ""

# نسخ ملفات الإعداد والسكريبتات
echo -e "${BLUE}🔧 نسخ السكريبتات...${NC}"
for script in deploy-*.sh configure-*.sh *.sh; do
    [ -f "$PROJECT_ROOT/$script" ] && backup_item "$PROJECT_ROOT/$script" "$BACKUP_PATH" "$script"
done
echo ""

# نسخ الوثائق
echo -e "${BLUE}📚 نسخ الوثائق...${NC}"
for doc in *.md *.txt; do
    [ -f "$PROJECT_ROOT/$doc" ] && backup_item "$PROJECT_ROOT/$doc" "$BACKUP_PATH" "$doc"
done
echo ""

# إنشاء أرشيف مضغوط
echo -e "${BLUE}📦 إنشاء أرشيف مضغوط...${NC}"
cd "$BACKUP_DIR"
tar -czf "${BACKUP_NAME}.tar.gz" "$BACKUP_NAME" 2>/dev/null && \
echo -e "${GREEN}✅${NC} تم إنشاء الأرشيف: ${BACKUP_NAME}.tar.gz" || \
echo -e "${RED}❌${NC} فشل إنشاء الأرشيف"
echo ""

# حساب الحجم
BACKUP_SIZE=$(du -sh "$BACKUP_PATH" | cut -f1)
ARCHIVE_SIZE=$(du -sh "${BACKUP_NAME}.tar.gz" | cut -f1)

# إنشاء ملف معلومات النسخة الاحتياطية
cat > "$BACKUP_PATH/BACKUP_INFO.txt" << EOF
═══════════════════════════════════════════════════════════
        معلومات النسخة الاحتياطية
        Backup Information
═══════════════════════════════════════════════════════════

التاريخ والوقت: $(date '+%Y-%m-%d %H:%M:%S')
Date/Time: $(date '+%Y-%m-%d %H:%M:%S')

اسم النسخة: $BACKUP_NAME
Backup Name: $BACKUP_NAME

حجم المجلد: $BACKUP_SIZE
Folder Size: $BACKUP_SIZE

حجم الأرشيف: $ARCHIVE_SIZE
Archive Size: $ARCHIVE_SIZE

المسار: $BACKUP_PATH
Path: $BACKUP_PATH

الأرشيف: ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz
Archive: ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz

═══════════════════════════════════════════════════════════
© 2024-2026 Stampcoin Platform. All Rights Reserved.
═══════════════════════════════════════════════════════════
EOF

# تنظيف النسخ القديمة (الاحتفاظ بآخر 10 نسخ)
echo -e "${BLUE}🧹 تنظيف النسخ القديمة...${NC}"
cd "$BACKUP_DIR"
ls -t backup_*.tar.gz 2>/dev/null | tail -n +11 | xargs -r rm -f
ls -td backup_*/ 2>/dev/null | tail -n +11 | xargs -r rm -rf
echo -e "${GREEN}✅${NC} تم الاحتفاظ بآخر 10 نسخ احتياطية"
echo ""

# الخلاصة
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}   ✅ اكتملت عملية النسخ الاحتياطي بنجاح!${NC}"
echo -e "${GREEN}   Backup Process Completed Successfully!${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}📊 الإحصائيات:${NC}"
echo -e "   المجلد: $BACKUP_SIZE"
echo -e "   الأرشيف: $ARCHIVE_SIZE"
echo -e "   الموقع: $BACKUP_PATH"
echo ""
echo -e "${GREEN}📁 للاستعادة:${NC}"
echo -e "   tar -xzf $BACKUP_DIR/${BACKUP_NAME}.tar.gz -C /desired/location/"
echo ""

# إرجاع رمز النجاح
exit 0
