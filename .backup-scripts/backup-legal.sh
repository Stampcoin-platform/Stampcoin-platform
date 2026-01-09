#!/bin/bash

###############################################################################
# نسخ احتياطي سريع للملفات القانونية
# Quick Legal Files Backup
# Copyright © 2024-2026 Stampcoin Platform. All Rights Reserved.
###############################################################################

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_ROOT="/workspaces/Stampcoin-platform"
BACKUP_DIR="$PROJECT_ROOT/backups/legal"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

mkdir -p "$BACKUP_DIR"

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}   📋 نسخ احتياطي سريع للملفات القانونية${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# نسخ الملفات القانونية
LEGAL_FILES=(
    "LICENSE"
    "COPYRIGHT"
    "INTELLECTUAL_PROPERTY.md"
    "TRADEMARK_NOTICE.md"
    "LEGAL_PROTECTION_GUIDE.md"
    "COPYRIGHT_HEADER.txt"
    "IP_PROTECTION_COMPLETE.md"
    "IP_PROTECTION_SUMMARY.md"
    "IP_PROTECTED.txt"
    "IP_DOCUMENTS_INDEX.md"
    "IP_QUICK_START.md"
)

BACKUP_SUBDIR="$BACKUP_DIR/legal_${TIMESTAMP}"
mkdir -p "$BACKUP_SUBDIR"

for file in "${LEGAL_FILES[@]}"; do
    if [ -f "$PROJECT_ROOT/$file" ]; then
        cp "$PROJECT_ROOT/$file" "$BACKUP_SUBDIR/"
        echo -e "${GREEN}✅${NC} $file"
    fi
done

# إنشاء أرشيف
cd "$BACKUP_DIR"
tar -czf "legal_${TIMESTAMP}.tar.gz" "legal_${TIMESTAMP}" 2>/dev/null

ARCHIVE_SIZE=$(du -sh "legal_${TIMESTAMP}.tar.gz" | cut -f1)

echo ""
echo -e "${GREEN}✅ تم إنشاء: legal_${TIMESTAMP}.tar.gz ($ARCHIVE_SIZE)${NC}"
echo -e "${BLUE}📁 الموقع: $BACKUP_DIR${NC}"
echo ""

exit 0
