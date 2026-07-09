#!/usr/bin/env python3
"""Envía informe del Bar por Telegram leyendo window.BAR_DATA de bar.html.
Usa las variables de entorno TELEGRAM_BOT_TOKEN y TELEGRAM_CHAT_ID."""
import json, re, os, sys
import urllib.request

TOKEN = os.environ.get("TELEGRAM_BOT_TOKEN")
CHAT = os.environ.get("TELEGRAM_CHAT_ID")
CAMBIOS = os.environ.get("HUBO_CAMBIOS", "1") == "1"

if not TOKEN or not CHAT:
    print("Sin credenciales de Telegram; no se envía aviso.")
    sys.exit(0)

with open(os.path.join(os.path.dirname(__file__), "bar.html"), encoding="utf-8") as f:
    c = f.read()
m = re.search(r"window\.BAR_DATA = (\{.*?\});", c, re.DOTALL)
d = json.loads(m.group(1).rstrip(";"))
ultima = d["hojas"][-1]
hoy = ultima["datos"][-1] if ultima["datos"] else None
t = d["totales"]

msg = "📊 <b>Bar Madre Monte · Dashboard</b>\n\n"
if CAMBIOS:
    msg += f"✅ <b>Actualizado:</b> {ultima['nombre']}\n"
else:
    msg += f"📅 <b>{ultima['nombre']}</b> · sin cambios (ya estaba al día)\n"
msg += f"📅 {len(ultima['datos'])} días en el mes actual\n"
if hoy:
    msg += f"🕐 Último día: {hoy['fecha'][:10]}\n"
    msg += f"   Alegra: ${hoy['cierreAlegra']:,} | Formato: ${hoy['cierreFormato']:,}\n"
msg += f"\n📈 <b>{len(d['hojas'])} meses</b> · {d['totalDias']} días con datos\n"
msg += f"💰 Total Alegra: <b>${t['cierreAlegra']:,}</b>\n"
msg += f"📄 Total Formato: <b>${t['cierreFormato']:,}</b>\n"
msg += f"💵 Efectivo: ${t['efectivo']:,}\n"
msg += f"🏦 Transferencias: ${t['transferencias']:,}\n"
msg += f"💳 Datáfono: ${t['datafono']:,}\n"
msg += f"❤️ Propinas: ${t['propinas']:,}\n\n"
msg += '🔗 <a href="https://johnnyartesano26.github.io/madremonte-dashboard/bar.html">Ver Dashboard</a>'

body = json.dumps({"chat_id": CHAT, "text": msg, "parse_mode": "HTML"}).encode()
req = urllib.request.Request(f"https://api.telegram.org/bot{TOKEN}/sendMessage",
                            data=body, headers={"Content-Type": "application/json"})
resp = json.load(urllib.request.urlopen(req, timeout=15))
print("Telegram enviado:", resp.get("ok"), resp.get("description", ""))
