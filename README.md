# Scrum Dashboard — Madre Monte

Dashboard de metodología Scrum para la cervecería Madre Monte, con **histórico SQL** vía Supabase.

- Archivo: `scrum.html`
- URL pública: `https://johnnyartesano26.github.io/madremonte-dashboard/scrum.html`

---

## Dashboard de Planta (`index.html`) — Alertas

### Semáforo de botellas

La pestaña **Producción** marca cada estilo de botella según su stock (`renderProduccion()`):

| Botellas | Color | Texto |
|---|---|---|
| ≤ 48 | 🔴 rojo | Crítico (≤48) |
| 49–120 | 🟡 ámbar | Stock bajo |
| > 120 | 🟢 verde | Stock OK |

> Umbral crítico = **48 unidades**. Se evalúa por estilo con `if (b.cantidad <= 48)`.

### Alerta semanal de actualización de inventario

- Un **banner rojo** ("El inventario no se ha actualizado esta semana") aparece cuando la
  última lectura de inventario (`fecha_lectura` de `inventario_neto.json`, o `generado`)
  es **anterior al lunes** de la semana actual.
- **Persiste** toda la semana hasta que se actualice el inventario.
- Incluye enlace directo al formulario de inventario.

Lógica en `actualizarAlertaInventario()`: calcula el lunes de la semana (`(getDay() + 6) % 7`)
y lo compara contra la última fecha de lectura (`parseFecha()`). Si no hay lectura o es
anterior al lunes → muestra el banner.

---

## Dashboard de Planta — Tanques SVG (respaldo / versión anterior)

> Guardado como respaldo antes de migrar al enfoque fotorrealista (imagen `tanque-3d.jpg`
> + medidor de nivel). Si se quiere volver al SVG, copiar este código.

### `tanqueSVG(f, idx)` — función generadora del tanque (SVG)

```js
function tanqueSVG(f, idx) {
  const fill = FILL_FERM[f.estilo] || "#F0C419";
  const pct = Math.max(0, Math.min(100, f.porcentaje || 0));
  const innerTop = 24, innerBot = 130, H = innerBot - innerTop;
  const fillY = innerBot - H * pct / 100;
  const clipId = "ci" + idx;
  const capId = "cap-t" + idx;
  const interior = "M30," + innerTop + " L90," + innerTop + " L90,96 L60," + innerBot + " L30,96 Z";
  const bgLabel = (pct >= 44) ? fill : EMPTY_FERM;
  const txt = textoContraste(bgLabel);
  return '<div class="tanque-wrap"><svg class="tanque" width="120" height="168" viewBox="0 0 120 168">'
    + '<defs>'
    + '<radialGradient id="' + capId + '" cx="0.38" cy="0.3" r="0.9"><stop offset="0%" stop-color="#fdfdfa"/><stop offset="42%" stop-color="#e3e8ec"/><stop offset="100%" stop-color="#9aa4ad"/></radialGradient>'
    + '<clipPath id="' + clipId + '"><path d="' + interior + '"/></clipPath>'
    + '</defs>'
    + '<g clip-path="url(#' + clipId + ')">'
    + '<rect x="28" y="20" width="64" height="118" fill="' + EMPTY_FERM + '"/>'
    + '<rect x="31" y="22" width="5" height="112" fill="#ffffff" opacity="0.45"/>'   // brillo izquierdo
    + '<rect class="liquido" x="28" y="' + fillY + '" width="64" height="' + (innerBot - fillY) + '" fill="' + fill + '"/>'
    + '<ellipse class="liquido-superficie" cx="60" cy="' + fillY + '" rx="30" ry="3.5" fill="' + fill + '"/>'
    + '</g>'
    + '<path d="' + interior + '" fill="none" stroke="#8a9299" stroke-width="2"/>'
    + '<ellipse cx="60" cy="' + innerTop + '" rx="30" ry="7" fill="url(#' + capId + ')" stroke="#8a9299" stroke-width="2"/>'
    + '<circle cx="60" cy="' + (innerTop - 6) + '" r="3" fill="#8a9299"/>'
    + '<rect x="57" y="130" width="6" height="9" rx="1" fill="#8a9299"/>'
    + '<line x1="42" y1="96" x2="34" y2="152" stroke="#8a9299" stroke-width="3"/>'
    + '<line x1="78" y1="96" x2="86" y2="152" stroke="#8a9299" stroke-width="3"/>'
    + '</svg><span class="pct-label" style="color:' + txt + ';text-shadow:none;">' + pct + '%</span></div>';
}
```

### CSS asociado al SVG (onda, tilt, sombra, crítico)

```css
/* Onda del líquido (respiración) */
@keyframes onda-liquido {
  0%   { transform: scaleX(1)     translateX(0);     opacity: .82; }
  50%  { transform: scaleX(1.06)  translateX(1.6px); opacity: 1; }
  100% { transform: scaleX(1)     translateX(0);     opacity: .82; }
}
.tanque .liquido-superficie { transform-origin: center; animation: onda-liquido 3.2s ease-in-out infinite; }

/* Tilt 3D al hover */
.tanque-wrap { position: relative; display: inline-block; transition: transform .5s cubic-bezier(.25,.8,.25,1); transform-style: preserve-3d; }
.ferm:hover .tanque-wrap { transform: perspective(650px) rotateX(4deg) rotateY(-5deg); }

/* Sombra proyectada en el suelo (se mueve opuesta al tilt) */
.tanque-wrap::after { content:''; position:absolute; bottom:2px; left:50%; width:64px; height:10px; transform:translateX(-50%); background:radial-gradient(ellipse, rgba(60,40,20,.22) 0%, rgba(60,40,20,0) 70%); transition: transform .5s cubic-bezier(.25,.8,.25,1), opacity .5s ease; pointer-events:none; }
.ferm:hover .tanque-wrap::after { transform: translateX(-40%) scaleX(.78); opacity:.6; }

/* Tanque crítico en grises */
.ferm.critico .tanque { filter: grayscale(.92) contrast(.92); opacity: .5; }
.ferm.critico .pct-label { color: #8c7b6b !important; }
```

---

## Dashboard de Planta — Barriles SVG (respaldo / versión anterior)

> Respaldo del SVG de barriles antes de migrar a la imagen fotorrealista (`barril-1.webp`).

### `barrilSVG(estilo)` — función generadora del barril (SVG)

```js
function barrilSVG(estilo) {
  const color = colorEstilo(estilo);
  const uid = estilo.replace(/\s/g, "");
  return '<div class="barril-svg-wrap"><svg class="barril-svg" width="100" height="130" viewBox="0 0 100 130">'
    + '<defs>'
    + '<linearGradient id="steel' + uid + '" x1="0" y1="0" x2="1" y2="0"><stop offset="0%" stop-color="#8a97a3"/><stop offset="18%" stop-color="#e5ebf0"/><stop offset="45%" stop-color="#c2ccd4"/><stop offset="70%" stop-color="#eef2f5"/><stop offset="100%" stop-color="#7f8b96"/></linearGradient>'
    + '<radialGradient id="cap' + uid + '" cx="0.38" cy="0.3" r="0.95"><stop offset="0%" stop-color="#ffffff" stop-opacity="0.55"/><stop offset="38%" stop-color="' + color + '"/><stop offset="100%" stop-color="' + color + '" stop-opacity="0.72"/></radialGradient>'
    + '</defs>'
    + '<ellipse cx="50" cy="14" rx="26" ry="6" fill="url(#cap' + uid + ')" stroke="#5b6670" stroke-width="1.5"/>'
    + '<rect x="24" y="14" width="52" height="8" fill="url(#cap' + uid + ')"/>'
    + '<rect x="46" y="4" width="8" height="8" rx="2" fill="#5b6670"/>'
    + '<path d="M24,22 L24,26 Q16,30 16,40 L16,92 Q16,102 24,106 L24,110 L76,110 L76,106 Q84,102 84,92 L84,40 Q84,30 76,26 L76,22 Z" fill="url(#steel' + uid + ')" stroke="#5b6670" stroke-width="1.5"/>'
    + '<rect x="14" y="40" width="72" height="6" rx="3" fill="#aab4bd" opacity="0.7"/>'
    + '<rect x="14" y="86" width="72" height="6" rx="3" fill="#aab4bd" opacity="0.7"/>'
    + '<rect x="30" y="30" width="5" height="76" rx="2" fill="#ffffff" opacity="0.35"/>'
    + '<ellipse cx="50" cy="110" rx="26" ry="6" fill="#8a97a3" stroke="#5b6670" stroke-width="1.5"/>'
    + '</svg></div>';
}
```

---

## Funcionalidades

- **Encabezado dinámico**: cuartil actual (Q1–Q4), semana del cuartil, semana del año, fecha y días restantes del trimestre.
- **Navegación entre cuartiles**: clic en Q1–Q4 para ver cada trimestre, botón "↺ Hoy" para volver al actual.
- **Objetivos del trimestre** y **tablero de sprint** (con histórico, últimos cambios por ítem).
- **Formulario "✍️ Registrar datos"**: guarda objetivos, tareas, checklist Invima y métricas en SQL.
- **Gráficos "📈 Avances"**: progreso de objetivos, sprint por estado y evolución de métricas (Chart.js).
- **KPIs**: ventas del bar, litros en fermentación, botellas, urgentes Invima y cartera pendiente.
- **Deduplicación**: agrupa objetivos/tareas con texto similar (acentos, mayúsculas, artículos).

---

## Fuentes de datos

| Sección | Fuente | Actualización |
|---------|--------|---------------|
| Ventas Bar (KPI) | `dashboard-maestro/catalogo.json` | Automática (workflow diario) |
| Cartera pendiente | Google Sheet "Respuestas de formulario 1" (en vivo) | En vivo |
| Litros / botellas | `data/ledger_inventario.json` (núcleo de inventario) | Automática (sync) |
| Invima | `data/invima_checklist.json` + localStorage | Manual / edición en navegador |
| Objetivos / sprint / métricas | Supabase (SQL) | Formulario del dashboard |
| Objetivos (respaldo) | `data/objetivos.json` | Solo si Supabase está vacío |

> `DATA_BASE` apunta a `https://johnnyartesano26.github.io/dashboard-maestro/data`; `catalogo.json` vive en la **raíz** de ese repo (por eso se usa `ROOT_BASE`).

---

## Cuartiles y semanas

La lógica está en `scrum.html` y es **automática según la fecha**:

- Un año = 52 semanas → **4 trimestres de 13 semanas**.
- `trimestreActual()` calcula el cuartil (Q1–Q4), su fecha de inicio/fin y `totalSemanas = 13`.
- `semanaActual(trimestre)` calcula la semana dentro del cuartil.
- Semana del año = `(cuartil − 1) × 13 + semana` (ej. Q4 semana 1 = semana 40 del año).
- `renderVistaCuartil(q)` dibuja encabezado, timeline, meta (días restantes / % transcurrido) y la fila de cuartiles clicables.

No hay que cambiar fechas al pasar de trimestre: se recalcula al abrir la página.

---

## Histórico SQL (Supabase)

El dashboard es un sitio estático (GitHub Pages), así que para guardar datos en una base de datos SQL se usa **[Supabase](https://supabase.com)** (Postgres con API REST). El formulario hace POST directo a Supabase y cada registro queda con su fecha (`creado_el`) → **historial completo**.

### Flujo de datos

```
scrum.html (formulario)      ──POST──▶  Supabase REST (/rest/v1/<tabla>)
scrum.html (tablero/objetivos) ──GET──▶  Supabase REST
```

- **Escritura**: sección "✍️ Registrar datos" (4 pestañas: 🎯 Objetivo, 🏃 Tarea sprint, 🏥 Invima, 📊 Métrica).
- **Lectura**: tablero de sprint y objetivos leen del histórico SQL (última fila por ítem, agrupando por texto normalizado). Si la tabla está vacía o no hay conexión, usan un respaldo local.

### Esquema (4 tablas, append-only)

| Tabla | Columnas |
|-------|----------|
| `objetivos` | `trimestre`, `texto`, `estado` (en_curso/completado), `progreso` (0-100), `notas`, `creado_el` |
| `sprint_tareas` | `tarea`, `responsable`, `estado` (pendiente/en_progreso/hecho/bloqueado), `sprint`, `creado_el` |
| `invima_items` | `item`, `categoria`, `clasificacion` (Urgente/Importante), `responsable`, `avance`, `estado`, `creado_el` |
| `metricas` | `clave`, `valor`, `unidad`, `creado_el` |

Cada cambio es una **fila nueva** (append-only). El "estado actual" se obtiene tomando la última fila por nombre (normalizado).

### Conexión

Los valores están en `scrum.html` (constantes `SUPABASE_URL` y `SUPABASE_KEY`):

```js
const SUPABASE_URL = 'https://xrhuonbgjlocjusmniel.supabase.co';
const SUPABASE_KEY = 'sb_publishable_...';   // publishable key (pública, segura en navegador)
```

> ⚠️ La **`service_role` / `secret` key NUNCA debe ir en el repositorio** ni en el navegador.

### Seguridad (clave de escritura + RLS)

La **lectura** está abierta al rol `anon` (necesaria para el sitio estático). La **escritura** está protegida con una **clave de escritura**: el formulario pide la clave (la misma de los dashboards), la hashea (SHA-256) y la envía como header `x-write-key`. Las políticas RLS de `insert` verifican ese hash antes de permitir el guardado.

> El hash se guarda en `scrum.html` (`CLAVE_HASH`) y en las políticas RLS. La clave en texto plano solo la escribe el usuario.

---

## Reproducir la configuración

Para recrear las tablas en otro proyecto de Supabase, ejecuta en **SQL Editor**:

```sql
create table if not exists public.objetivos (
  id bigint generated always as identity primary key,
  trimestre text not null,
  texto text not null,
  estado text not null default 'en_curso',
  progreso integer default 0,
  notas text,
  creado_el timestamptz not null default now()
);

create table if not exists public.sprint_tareas (
  id bigint generated always as identity primary key,
  tarea text not null,
  responsable text,
  estado text not null default 'pendiente',
  sprint text,
  creado_el timestamptz not null default now()
);

create table if not exists public.invima_items (
  id bigint generated always as identity primary key,
  item text not null,
  categoria text,
  clasificacion text default 'Importante',
  responsable text,
  avance text,
  estado text default 'Pendiente',
  creado_el timestamptz not null default now()
);

create table if not exists public.metricas (
  id bigint generated always as identity primary key,
  clave text not null,
  valor numeric,
  unidad text,
  creado_el timestamptz not null default now()
);

alter table public.objetivos enable row level security;
alter table public.sprint_tareas enable row level security;
alter table public.invima_items enable row level security;
alter table public.metricas enable row level security;

create policy "lectura anon objetivos" on public.objetivos for select to anon using (true);
create policy "escritura anon objetivos" on public.objetivos for insert to anon
with check (current_setting('request.headers', true)::json->>'x-write-key' = '700686426580d0bb78aebaabf76399a10f806705c93c4e826f8c982f0028ab74');

create policy "lectura anon sprint" on public.sprint_tareas for select to anon using (true);
create policy "escritura anon sprint" on public.sprint_tareas for insert to anon
with check (current_setting('request.headers', true)::json->>'x-write-key' = '700686426580d0bb78aebaabf76399a10f806705c93c4e826f8c982f0028ab74');

create policy "lectura anon invima" on public.invima_items for select to anon using (true);
create policy "escritura anon invima" on public.invima_items for insert to anon
with check (current_setting('request.headers', true)::json->>'x-write-key' = '700686426580d0bb78aebaabf76399a10f806705c93c4e826f8c982f0028ab74');

create policy "lectura anon metricas" on public.metricas for select to anon using (true);
create policy "escritura anon metricas" on public.metricas for insert to anon
with check (current_setting('request.headers', true)::json->>'x-write-key' = '700686426580d0bb78aebaabf76399a10f806705c93c4e826f8c982f0028ab74');
```

---

## Cómo agregar un campo o tabla nueva

1. **Tabla**: crear la tabla en Supabase (SQL Editor) y habilitar RLS con políticas `select`/`insert` para `anon`.
2. **Formulario**: añadir un bloque en `REGISTRO_TIPOS` en `scrum.html`.
3. **Lectura**: si hace falta, añadir su render (como `renderSprintBoard`/`renderObjetivos`).
4. Hacer commit/push del `scrum.html`.

---

## Nota de mantenimiento

- El cuartil, las semanas y la navegación Q1–Q4 son **automáticos** (ver "Cuartiles y semanas"). Al pasar de trimestre solo revisar `SPRINT_FALLBACK` (tareas de respaldo).
- `data/objetivos.json` es el **respaldo local** de objetivos; la fuente principal es Supabase.
- Los KPIs dependen de fuentes externas: si "Ventas Bar" aparece "sin datos", verifica que `dashboard-maestro/catalogo.json` exista en la **raíz** del repo.

---

## Solución de problemas

- **"❌ Error al guardar"** en el formulario: al insertar con `Prefer: return=minimal`, Supabase responde `201` con **cuerpo vacío**. `sbFetch` ya lo maneja (lee el texto y solo hace `JSON.parse` si hay contenido). Si vuelve a ocurrir, abre la **Consola del navegador** (F12) para ver el error real devuelto por Supabase.
- **Cambios que no se ven**: el navegador cachea la página. Recarga con `Ctrl+Shift+R` o añade `?v=2` a la URL para forzar la versión nueva.
- **Borrar filas**: el rol `anon` solo tiene `select` e `insert` (sin `delete`). Para eliminar filas usa el **SQL Editor** de Supabase, por ejemplo:
  ```sql
  delete from public.metricas where clave in ('test_conexion', 'test_minimal');
  ```
- **Vaciar una tabla** y empezar de cero:
  ```sql
  truncate table public.metricas;
  ```
