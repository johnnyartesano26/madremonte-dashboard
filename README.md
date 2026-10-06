# Scrum Dashboard — Madre Monte

Dashboard de metodología Scrum para la cervecería Madre Monte, con **histórico SQL** vía Supabase.

- Archivo: `scrum.html`
- URL pública: `https://johnnyartesano26.github.io/madremonte-dashboard/scrum.html`

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
