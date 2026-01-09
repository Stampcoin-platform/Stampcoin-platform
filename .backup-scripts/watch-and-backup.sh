#!/bin/bash

###############################################################################
# نظام المراقبة والنسخ الاحتياطي التلقائي
# Automatic File Watcher and Backup System
# Copyright © 2024-2026 Stampcoin Platform. All Rights Reserved.
###############################################################################

# الألوان
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

PROJECT_ROOT="/workspaces/Stampcoin-platform"
BACKUP_SCRIPT="$PROJECT_ROOT/.backup-scripts/backup.sh"
WATCH_INTERVAL=300  # 5 دقائق

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}   🔍 بدء مراقبة الملفات للنسخ الاحتياطي التلقائي${NC}"
echo -e "${GREEN}   Starting File Watcher for Automatic Backup${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}⏱️  الفحص كل $WATCH_INTERVAL ثانية ($(($WATCH_INTERVAL / 60)) دقائق)${NC}"
echo -e "${YELLOW}📁 المشروع: $PROJECT_ROOT${NC}"
echo -e "${YELLOW}🔄 للإيقاف: Ctrl+C${NC}"
echo ""

# الاحتفاظ بآخر وقت تعديل
LAST_MODIFICATION=""

while true; do
    # الحصول على آخر وقت تعديل للملفات المهمة
    CURRENT_MODIFICATION=$(find "$PROJECT_ROOT" -type f \
        \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" \
        -o -name "*.json" -o -name "*.md" -o -name "*.yml" -o -name "*.yaml" \
        -o -name "LICENSE" -o -name "COPYRIGHT" \) \
        -not -path "*/node_modules/*" \
        -not -path "*/dist/*" \
        -not -path "*/backups/*" \
        -not -path "*/.git/*" \
        -printf '%T@\n' 2>/dev/null | sort -n | tail -1)
    
    # إذا تغيرت الملفات، قم بالنسخ الاحتياطي
    if [ -n "$CURRENT_MODIFICATION" ] && [ "$CURRENT_MODIFICATION" != "$LAST_MODIFICATION" ]; then
        echo -e "${GREEN}🔔 تم اكتشاف تغييرات في الملفات!${NC}"
        echo -e "${BLUE}⏰ $(date '+%Y-%m-%d %H:%M:%S')${NC}"
        echo ""
        
        # تشغيل سكريبت النسخ الاحتياطي
        bash "$BACKUP_SCRIPT"
        
        LAST_MODIFICATION="$CURRENT_MODIFICATION"
        echo ""
        echo -e "${GREEN}✅ النسخ الاحتياطي التلقائي مكتمل${NC}"
        echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
        echo ""
    fi
    
    # الانتظار قبل الفحص التالي
    sleep $WATCH_INTERVAL
done
