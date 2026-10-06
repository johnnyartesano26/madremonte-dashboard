# Scrum Dashboard — Madre Monte

Dashboard de metodología Scrum para la cervecería Madre Monte, con **histórico SQL** vía Supabase.

- Archivo: `scrum.html`
- URL pública: `https://johnnyartesano26.github.io/madremonte-dashboard/scrum.html`

---

## Histórico SQL (Supabase)

El dashboard es un sitio estático (GitHub Pages), así que para guardar datos en una base de datos SQL se usa **[Supabase](https://supabase.com)** (Postgres con API REST). El formulario del dashboard hace POST directo a Supabase y cada registro queda con su fecha (`creado_el`) → **historial completo**.

### Flujo de datos

```
scrum.html (formulario)  ──POST──▶  Supabase REST (/rest/v1/<tabla>)
scrum.html (tablero/objetivos) ──GET──▶  Supabase REST
```

- **Escritura**: sección "✍️ Registrar datos" (4 pestañas: 🎯 Objetivo, 🏃 Tarea sprint, 🏥 Invima, 📊 Métrica).
- **Lectura**: tablero de sprint y objetivos leen del histórico SQL (última fila por ítem). Si la tabla está vacía o no hay conexión, usan un respaldo local.

### Esquema (4 tablas, append-only)

| Tabla | Columnas |
|-------|----------|
| `objetivos` | `trimestre`, `texto`, `estado` (en_curso/completado), `progreso` (0-100), `notas`, `creado_el` |
| `sprint_tareas` | `tarea`, `responsable`, `estado` (pendiente/en_progreso/hecho/bloqueado), `sprint`, `creado_el` |
| `invima_items` | `item`, `categoria`, `clasificacion` (Urgente/Importante), `responsable`, `avance`, `estado`, `creado_el` |
| `metricas` | `clave`, `valor`, `unidad`, `creado_el` |

Cada cambio es una **fila nueva** (append-only). El "estado actual" de una tarea/objetivo se obtiene tomando la última fila por nombre.

### Conexión

Los valores están en `scrum.html` (constantes `SUPABASE_URL` y `SUPABASE_KEY`):

```js
const SUPABASE_URL = 'https://xrhuonbgjlocjusmniel.supabase.co';
const SUPABASE_KEY = 'sb_publishable_...';   // publishable key (pública, segura en navegador)
```

> ⚠️ La **`service_role` / `secret` key NUNCA debe ir en el repositorio** ni en el navegador.

### Seguridad (Row Level Security)

Las tablas tienen RLS habilitado con políticas abiertas al rol `anon` (lectura y escritura), necesario para un sitio estático sin login. Son datos no sensibles, pero **cualquiera con la URL podría escribir**. Para limitarlo, añadir una "clave de escritura" (header + política RLS) como siguiente paso.

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
create policy "escritura anon objetivos" on public.objetivos for insert to anon with check (true);
create policy "lectura anon sprint" on public.sprint_tareas for select to anon using (true);
create policy "escritura anon sprint" on public.sprint_tareas for insert to anon with check (true);
create policy "lectura anon invima" on public.invima_items for select to anon using (true);
create policy "escritura anon invima" on public.invima_items for insert to anon with check (true);
create policy "lectura anon metricas" on public.metricas for select to anon using (true);
create policy "escritura anon metricas" on public.metricas for insert to anon with check (true);
```

---

## Cómo agregar un campo o tabla nueva

1. **Tabla**: crear la tabla en Supabase (SQL Editor) y habilitar RLS con políticas `select`/`insert` para `anon`.
2. **Formulario**: añadir un bloque en `REGISTRO_TIPOS` en `scrum.html`.
3. **Lectura**: si hace falta, añadir su render (como `renderSprintBoard`/`renderObjetivos`).
4. Hacer commit/push del `scrum.html`.

---

## Nota de mantenimiento

- El dashboard Q4 usa la fecha de inicio `Q4_INICIO = 2026-10-01` en `scrum.html`. Al cambiar de trimestre, actualizar esa fecha y los `SPRINT_FALLBACK`.
- `data/objetivos.json` es el **respaldo local** de objetivos; la fuente principal es Supabase.

---

## Solución de problemas

- **"❌ Error al guardar"** en el formulario: al insertar con `Prefer: return=minimal`, Supabase responde `201` con **cuerpo vacío**. `sbFetch` ya lo maneja (lee el texto y solo hace `JSON.parse` si hay contenido). Si vuelve a ocurrir, abre la **Consola del navegador** (F12) para ver el error real devuelto por Supabase.
- **Borrar filas**: el rol `anon` solo tiene `select` e `insert` (sin `delete`). Para eliminar filas usa el **SQL Editor** de Supabase, por ejemplo:
  ```sql
  delete from public.metricas where clave in ('test_conexion', 'test_minimal');
  ```
- **Vaciar una tabla** y empezar de cero:
  ```sql
  truncate table public.metricas;
  ```
