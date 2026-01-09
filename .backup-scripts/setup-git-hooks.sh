#!/bin/bash

###############################################################################
# إعداد Git Hooks للنسخ الاحتياطي التلقائي
# Setup Git Hooks for Automatic Backup
# Copyright © 2024-2026 Stampcoin Platform. All Rights Reserved.
###############################################################################

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_ROOT="/workspaces/Stampcoin-platform"
GIT_HOOKS_DIR="$PROJECT_ROOT/.git/hooks"
POST_COMMIT_HOOK="$GIT_HOOKS_DIR/post-commit"
BACKUP_POST_COMMIT="$PROJECT_ROOT/.backup-scripts/post-commit"

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}   🔧 إعداد Git Hooks للنسخ الاحتياطي التلقائي${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# إنشاء مجلد hooks إذا لم يكن موجوداً
mkdir -p "$GIT_HOOKS_DIR"

# نسخ post-commit hook
if [ -f "$BACKUP_POST_COMMIT" ]; then
    cp "$BACKUP_POST_COMMIT" "$POST_COMMIT_HOOK"
    chmod +x "$POST_COMMIT_HOOK"
    echo -e "${GREEN}✅${NC} تم تثبيت post-commit hook"
else
    echo -e "${RED}❌${NC} ملف post-commit غير موجود!"
    exit 1
fi

echo ""
echo -e "${GREEN}✅ اكتمل الإعداد!${NC}"
echo ""
echo -e "${BLUE}📝 الآن سيتم النسخ الاحتياطي تلقائياً بعد كل git commit${NC}"
echo ""

exit 0
