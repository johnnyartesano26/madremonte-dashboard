#!/bin/bash
# update_and_push.sh
# Ejecuta update_bar_dashboard.py y si hay cambios, commitea y pushea a GitHub.
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] === Iniciando actualización diaria ==="

# Step 1: Update data from Google Sheets
python3 update_bar_dashboard.py
RET=$?
if [ $RET -ne 0 ]; then
    echo "[$(date)] ERROR: update_bar_dashboard.py falló con código $RET"
    exit $RET
fi

# Step 2: Check if bar.html changed
if git diff --quiet bar.html; then
    echo "[$(date)] Sin cambios en bar.html. No se requiere push."
    exit 0
fi

# Step 3: Commit and push
echo "[$(date)] Cambios detectados. Commiteando..."
git add bar.html update_bar_dashboard.py update_and_push.sh
git commit -m "Auto-actualización diaria: $(date '+%Y-%m-%d')"
git push origin main

echo "[$(date)] ✅ Push completado."
