#!/bin/bash
# update_and_push.sh
# Ejecuta update_bar_dashboard.py, si hay cambios commitea/pushea y envía informe por Telegram.
set -e

# Cargar credenciales desde .env (fuera del repo, nunca en GitHub)
ENV_FILE="$HOME/.config/madremonte/.env"
if [ -f "$ENV_FILE" ]; then
    set -a; source "$ENV_FILE"; set +a
else
    echo "[$(date)] ⚠️  $ENV_FILE no encontrado. Algunas funciones fallarán." >&2
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] === Iniciando actualización diaria ==="

# ── 1. Actualizar datos desde Google Sheets ──
python3 update_bar_dashboard.py
RET=$?
if [ $RET -ne 0 ]; then
    echo "[$(date)] ERROR: update_bar_dashboard.py falló con código $RET"
    exit $RET
fi

# ── 2. Cargar token de Telegram ──
python3 -c "
import sys; sys.path.insert(0,'/mnt/c/DeepAgente')
import os
from env_loader import load_credentials; load_credentials()
print(os.getenv('TELEGRAM_BOT_TOKEN',''))
print(os.getenv('TELEGRAM_CHAT_ID',''))
" > /tmp/mm_telegram_creds.txt

TOKEN=$(head -1 /tmp/mm_telegram_creds.txt)
CHAT_ID=$(tail -1 /tmp/mm_telegram_creds.txt)
rm -f /tmp/mm_telegram_creds.txt

# ── 3. Verificar si hay cambios ──
if git diff --quiet bar.html; then
    echo "[$(date)] Sin cambios en bar.html."
    # Enviar informe resumido igual
    python3 -c "
import json, re
with open('bar.html') as f:
    c = f.read()
m = re.search(r'window\.BAR_DATA = (\{.*?\});', c, re.DOTALL)
d = json.loads(m.group(1).rstrip(';'))
ultima = d['hojas'][-1]
hoy_datos = ultima['datos'][-1] if ultima['datos'] else None
ultimo_mes = ultima['nombre']
total_meses = len(d['hojas'])
total_dias = d['totalDias']
t = d['totales']

msg = f'📊 <b>Bar Madre Monte · Dashboard</b>\n\n'
msg += f'📅 <b>{ultimo_mes}</b> · {len(ultima[\"datos\"])} días\n'
if hoy_datos:
    msg += f'🕐 Último día: {hoy_datos[\"fecha\"][:10]} · Alegra: \${hoy_datos[\"cierreAlegra\"]:,} · Formato: \${hoy_datos[\"cierreFormato\"]:,}\n'
msg += f'\n📈 <b>{total_meses} meses</b> · {total_dias} días con datos\n'
msg += f'💰 Total Alegra: \${t[\"cierreAlegra\"]:,}\n'
msg += f'📄 Total Formato: \${t[\"cierreFormato\"]:,}\n'
msg += f'💵 Efectivo: \${t[\"efectivo\"]:,}\n'
msg += f'🏦 Transferencias: \${t[\"transferencias\"]:,}\n'
msg += f'💳 Datafono: \${t[\"datafono\"]:,}\n'
msg += f'❤️ Propinas: \${t[\"propinas\"]:,}\n\n'
msg += f'⚠️ Sin cambios hoy — ya estaba actualizado.\n'
msg += f'🔗 https://johnnyartesano26.github.io/madremonte-dashboard/bar.html'

import requests
resp = requests.post(f'https://api.telegram.org/bot$TOKEN/sendMessage',
    json={'chat_id': '$CHAT_ID', 'text': msg, 'parse_mode': 'HTML'}, timeout=10)
print('TG send:', resp.json())
"
    exit 0
fi

# ── 4. Commit y push ──
echo "[$(date)] Cambios detectados. Commiteando..."
git add bar.html update_bar_dashboard.py update_and_push.sh
git commit -m "Auto-actualización diaria: $(date '+%Y-%m-%d %H:%M')"
git push origin main

echo "[$(date)] ✅ Push completado."

# ── 5. Enviar informe por Telegram ──
python3 -c "
import json, re
with open('bar.html') as f:
    c = f.read()
m = re.search(r'window\.BAR_DATA = (\{.*?\});', c, re.DOTALL)
d = json.loads(m.group(1).rstrip(';'))
ultima = d['hojas'][-1]
hoy_datos = ultima['datos'][-1] if ultima['datos'] else None
ultimo_mes = ultima['nombre']
total_meses = len(d['hojas'])
total_dias = d['totalDias']
t = d['totales']

msg = f'📊 <b>Bar Madre Monte · Dashboard</b>\n\n'
msg += f'✅ <b>Actualizado:</b> {ultimo_mes}\n'
msg += f'📅 {len(ultima[\"datos\"])} días en el mes actual\n'
if hoy_datos:
    msg += f'🕐 Último día registrado: {hoy_datos[\"fecha\"][:10]}\n'
    msg += f'   Alegra: \${hoy_datos[\"cierreAlegra\"]:,} | Formato: \${hoy_datos[\"cierreFormato\"]:,}\n'
    msg += f'   Efectivo: \${hoy_datos[\"efectivo\"]:,} | Transf: \${hoy_datos[\"transferencias\"]:,} | Dataf: \${hoy_datos[\"datafono\"]:,}\n'
    msg += f'   Propinas: \${hoy_datos[\"propinas\"]:,}\n'
msg += f'\n📈 <b>{total_meses} meses</b> · {total_dias} días con datos\n'
msg += f'💰 Total Alegra acumulado: <b>\${t[\"cierreAlegra\"]:,}</b>\n'
msg += f'📄 Total Formato acumulado: <b>\${t[\"cierreFormato\"]:,}</b>\n'
msg += f'💵 Efectivo: \${t[\"efectivo\"]:,}\n'
msg += f'🏦 Transferencias: \${t[\"transferencias\"]:,}\n'
msg += f'💳 Datafono: \${t[\"datafono\"]:,}\n'
msg += f'❤️ Propinas: \${t[\"propinas\"]:,}\n\n'
msg += f'🔗 <a href=\"https://johnnyartesano26.github.io/madremonte-dashboard/bar.html\">Ver Dashboard</a>'

import requests
resp = requests.post(f'https://api.telegram.org/bot$TOKEN/sendMessage',
    json={'chat_id': '$CHAT_ID', 'text': msg, 'parse_mode': 'HTML'}, timeout=10)
print('TG send:', resp.json())
"

echo "[$(date)] ✅ Informe enviado por Telegram."
