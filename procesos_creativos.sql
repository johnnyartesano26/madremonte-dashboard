-- ═══════════════════════════════════════════════════════════════
-- Procesos Creativos — Madre Monte
-- Ejecutar en: Supabase → SQL Editor (proyecto xrhuonbgjlocjusmniel)
--
-- Usa la MISMA clave de escritura que scrum.html (SHA-256).
-- Hash: 700686426580d0bb78aebaabf76399a10f806705c93c4e826f8c982f0028ab74
-- ═══════════════════════════════════════════════════════════════

-- ── 1. Proyectos (Fase 1 · creación, solo admin) ──
create table if not exists public.proyectos_creativos (
  id uuid primary key default gen_random_uuid(),
  nombre_aliado text not null,
  tipo text not null default 'Cultural',
  responsable_mm text,
  responsable_aliado text,
  estado text not null default 'en_creacion',
  creado_por text,
  creado_el timestamptz not null default now()
);

-- ── 2. Participantes / marcas (Fase 2 · logos opcionales) ──
create table if not exists public.participantes (
  id bigint generated always as identity primary key,
  proyecto_id uuid not null references public.proyectos_creativos(id) on delete cascade,
  nombre text not null,
  rol text,
  logo_url text,
  creado_el timestamptz not null default now()
);

-- ── 3. Fases (Gantt · línea de tiempo) ──
create table if not exists public.fases (
  id bigint generated always as identity primary key,
  proyecto_id uuid not null references public.proyectos_creativos(id) on delete cascade,
  nombre text not null,
  fecha_inicio date,
  duracion_semanas int not null default 1,
  dependencia_id bigint references public.fases(id),
  avance_pct int not null default 0,
  es_hito boolean not null default false,
  estado text not null default 'pendiente',
  responsable text,
  creado_el timestamptz not null default now()
);

-- ── 4. Dimensiones (etapas/tópicos · 5 por defecto) ──
create table if not exists public.dimensiones (
  id bigint generated always as identity primary key,
  proyecto_id uuid not null references public.proyectos_creativos(id) on delete cascade,
  nombre text not null,
  orden int not null default 0,
  estado text not null default 'no_iniciada',
  creado_el timestamptz not null default now()
);

-- ── 5. Preguntas (por dimensión) ──
create table if not exists public.preguntas (
  id bigint generated always as identity primary key,
  dimension_id bigint not null references public.dimensiones(id) on delete cascade,
  texto text not null,
  tipo_indicador text not null default 'numero',   -- numero | porcentaje | escala | cualitativo
  unidad text,
  meta_valor numeric,                              -- meta numérica (= 100%)
  meta_descripcion text,                           -- meta cualitativa
  responsable text,
  origen text not null default 'catalogo',         -- catalogo | propia
  creado_el timestamptz not null default now()
);

-- ── 6. Mediciones (avance · append-only · auditoría quién/cuándo) ──
create table if not exists public.mediciones (
  id bigint generated always as identity primary key,
  pregunta_id bigint not null references public.preguntas(id) on delete cascade,
  valor numeric,
  valor_pct numeric,                               -- % de avance vs meta
  creado_por text,
  creado_el timestamptz not null default now()
);

-- ── 7. Catálogo de preguntas base (plantilla global) ──
create table if not exists public.catalogo_preguntas (
  id bigint generated always as identity primary key,
  dimension text not null,
  texto text not null,
  tipo_indicador text not null default 'numero',
  unidad text,
  sugerencia_meta text
);

-- ═══ ROW LEVEL SECURITY ═══
alter table public.proyectos_creativos enable row level security;
alter table public.participantes enable row level security;
alter table public.fases enable row level security;
alter table public.dimensiones enable row level security;
alter table public.preguntas enable row level security;
alter table public.mediciones enable row level security;
alter table public.catalogo_preguntas enable row level security;

-- ═══ POLÍTICAS ═══
-- Lectura abierta al rol anon (sitio estático).
-- Escritura/actualización gated por la clave (header x-write-key).
-- mediciones es append-only (sin update/delete) para preservar auditoría.

do $$
declare h text := '700686426580d0bb78aebaabf76399a10f806705c93c4e826f8c982f0028ab74';
begin
  -- proyectos_creativos
  execute format('create policy sel_proyectos on public.proyectos_creativos for select to anon using (true)');
  execute format('create policy ins_proyectos on public.proyectos_creativos for insert to anon with check (current_setting(''request.headers'', true)::json->>''x-write-key'' = ''%s'')', h);
  execute format('create policy upd_proyectos on public.proyectos_creativos for update to anon using (current_setting(''request.headers'', true)::json->>''x-write-key'' = ''%s'') with check (current_setting(''request.headers'', true)::json->>''x-write-key'' = ''%s'')', h, h);
  execute format('create policy del_proyectos on public.proyectos_creativos for delete to anon using (current_setting(''request.headers'', true)::json->>''x-write-key'' = ''%s'')', h);

  -- participantes
  execute format('create policy sel_participantes on public.participantes for select to anon using (true)');
  execute format('create policy ins_participantes on public.participantes for insert to anon with check (current_setting(''request.headers'', true)::json->>''x-write-key'' = ''%s'')', h);
  execute format('create policy upd_participantes on public.participantes for update to anon using (current_setting(''request.headers'', true)::json->>''x-write-key'' = ''%s'') with check (current_setting(''request.headers'', true)::json->>''x-write-key'' = ''%s'')', h, h);
  execute format('create policy del_participantes on public.participantes for delete to anon using (current_setting(''request.headers'', true)::json->>''x-write-key'' = ''%s'')', h);

  -- fases
  execute format('create policy sel_fases on public.fases for select to anon using (true)');
  execute format('create policy ins_fases on public.fases for insert to anon with check (current_setting(''request.headers'', true)::json->>''x-write-key'' = ''%s'')', h);
  execute format('create policy upd_fases on public.fases for update to anon using (current_setting(''request.headers'', true)::json->>''x-write-key'' = ''%s'') with check (current_setting(''request.headers'', true)::json->>''x-write-key'' = ''%s'')', h, h);
  execute format('create policy del_fases on public.fases for delete to anon using (current_setting(''request.headers'', true)::json->>''x-write-key'' = ''%s'')', h);

  -- dimensiones
  execute format('create policy sel_dimensiones on public.dimensiones for select to anon using (true)');
  execute format('create policy ins_dimensiones on public.dimensiones for insert to anon with check (current_setting(''request.headers'', true)::json->>''x-write-key'' = ''%s'')', h);
  execute format('create policy upd_dimensiones on public.dimensiones for update to anon using (current_setting(''request.headers'', true)::json->>''x-write-key'' = ''%s'') with check (current_setting(''request.headers'', true)::json->>''x-write-key'' = ''%s'')', h, h);
  execute format('create policy del_dimensiones on public.dimensiones for delete to anon using (current_setting(''request.headers'', true)::json->>''x-write-key'' = ''%s'')', h);

  -- preguntas
  execute format('create policy sel_preguntas on public.preguntas for select to anon using (true)');
  execute format('create policy ins_preguntas on public.preguntas for insert to anon with check (current_setting(''request.headers'', true)::json->>''x-write-key'' = ''%s'')', h);
  execute format('create policy upd_preguntas on public.preguntas for update to anon using (current_setting(''request.headers'', true)::json->>''x-write-key'' = ''%s'') with check (current_setting(''request.headers'', true)::json->>''x-write-key'' = ''%s'')', h, h);
  execute format('create policy del_preguntas on public.preguntas for delete to anon using (current_setting(''request.headers'', true)::json->>''x-write-key'' = ''%s'')', h);

  -- mediciones (append-only)
  execute format('create policy sel_mediciones on public.mediciones for select to anon using (true)');
  execute format('create policy ins_mediciones on public.mediciones for insert to anon with check (current_setting(''request.headers'', true)::json->>''x-write-key'' = ''%s'')', h);

  -- catalogo_preguntas
  execute format('create policy sel_catalogo on public.catalogo_preguntas for select to anon using (true)');
  execute format('create policy ins_catalogo on public.catalogo_preguntas for insert to anon with check (current_setting(''request.headers'', true)::json->>''x-write-key'' = ''%s'')', h);
  execute format('create policy upd_catalogo on public.catalogo_preguntas for update to anon using (current_setting(''request.headers'', true)::json->>''x-write-key'' = ''%s'') with check (current_setting(''request.headers'', true)::json->>''x-write-key'' = ''%s'')', h, h);
  execute format('create policy del_catalogo on public.catalogo_preguntas for delete to anon using (current_setting(''request.headers'', true)::json->>''x-write-key'' = ''%s'')', h);
end $$;

-- ═══ ÍNDICES (claves foráneas) ═══
create index if not exists idx_participantes_proy on public.participantes(proyecto_id);
create index if not exists idx_fases_proy on public.fases(proyecto_id);
create index if not exists idx_dimensiones_proy on public.dimensiones(proyecto_id);
create index if not exists idx_preguntas_dim on public.preguntas(dimension_id);
create index if not exists idx_mediciones_preg on public.mediciones(pregunta_id);

-- ═══ SEMILLA: catálogo de 40 preguntas base (5 dimensiones × 8) ═══
insert into public.catalogo_preguntas (dimension, texto, tipo_indicador, unidad, sugerencia_meta) values
('Impacto Cultural', '¿Cuántas personas experimentarán el proyecto?', 'numero', 'asistentes', '80+ por evento'),
('Impacto Cultural', '¿La experiencia generará conversación o reflexión?', 'numero', 'menciones', '10+ por evento'),
('Impacto Cultural', '¿El proyecto visibilizará un tema o historia que no esté en la agenda?', 'numero', 'temas', '1+ por proyecto'),
('Impacto Cultural', '¿Generará emoción o cambio de percepción?', 'escala', '1-5', '4/5'),
('Impacto Cultural', '¿Dejará una obra, pieza o experiencia que perdurará?', 'numero', 'activos', '1+ por proyecto'),
('Impacto Cultural', '¿Inspirará a otros a hacer algo similar?', 'numero', 'réplicas', '1+'),
('Impacto Cultural', '¿Fortalecerá la identidad cultural local?', 'cualitativo', 'percepción', 'Cualitativo positivo'),
('Impacto Cultural', '¿Conectará con temas relevantes del contexto?', 'numero', 'temas', '1+'),

('Alcance y Comunidad', '¿Cuántas personas alcanzaremos en total?', 'numero', 'personas', '500+ por semestre'),
('Alcance y Comunidad', '¿Llegaremos a públicos nuevos?', 'porcentaje', '%', '30%+'),
('Alcance y Comunidad', '¿La comunidad participará activamente o solo recibirá?', 'numero', 'co-creadores', '5+ por proyecto'),
('Alcance y Comunidad', '¿Se involucrarán aliados externos?', 'numero', 'aliados', '2+ por proyecto'),
('Alcance y Comunidad', '¿Habrá diversidad en la audiencia?', 'cualitativo', 'perfil', 'Diverso'),
('Alcance y Comunidad', '¿Se generará contenido espontáneo por parte del público?', 'numero', 'publicaciones', '10+ por evento'),
('Alcance y Comunidad', '¿El proyecto llegará a territorios o comunidades específicas?', 'numero', 'municipios', '1+'),
('Alcance y Comunidad', '¿Se activará una red de colaboración?', 'numero', 'conexiones', '3+'),

('Proceso y Equipo', '¿Cumpliremos los plazos definidos?', 'porcentaje', '%', '80%+'),
('Proceso y Equipo', '¿Respetaremos el presupuesto?', 'porcentaje', '%', '±10%'),
('Proceso y Equipo', '¿El equipo se sentirá motivado y valorado?', 'escala', '1-5', '4+'),
('Proceso y Equipo', '¿Habrá claridad en roles y responsabilidades?', 'porcentaje', '%', '80%+'),
('Proceso y Equipo', '¿Documentaremos el proceso?', 'numero', 'documentos', '5+ por proyecto'),
('Proceso y Equipo', '¿Aprenderemos algo nuevo como equipo?', 'numero', 'aprendizajes', '3+'),
('Proceso y Equipo', '¿Habrá conflictos y se resolverán?', 'porcentaje', '%', '100% resueltos'),
('Proceso y Equipo', '¿El ritmo de trabajo será sostenible?', 'cualitativo', 'percepción', 'Equilibrada'),

('Sostenibilidad', '¿El proyecto se podrá repetir sin empezar de cero?', 'numero', 'procesos', '3+'),
('Sostenibilidad', '¿Generará ingresos o ahorros?', 'porcentaje', '%', '30%+'),
('Sostenibilidad', '¿Dependerá de personas específicas o de sistemas?', 'numero', 'personas', '≤2'),
('Sostenibilidad', '¿Habrá demanda para repetirlo o ampliarlo?', 'numero', 'solicitudes', '5+'),
('Sostenibilidad', '¿Se documentará para que otros lo repliquen?', 'numero', 'manuales', '1+'),
('Sostenibilidad', '¿El proyecto dejará capacidad instalada?', 'numero', 'habilidades', '3+'),
('Sostenibilidad', '¿Será viable en el próximo semestre?', 'cualitativo', 'sí/no', 'Sí'),
('Sostenibilidad', '¿Tendrá aliados o patrocinadores potenciales?', 'numero', 'contactos', '2+'),

('Relación y Alianza', '¿La alianza se fortalecerá?', 'escala', '1-5', '4+'),
('Relación y Alianza', '¿Aprenderemos a trabajar juntos?', 'numero', 'acuerdos', '3+'),
('Relación y Alianza', '¿Generaremos confianza mutua?', 'cualitativo', 'percepción', 'Alta'),
('Relación y Alianza', '¿El proyecto beneficiará a ambas partes por igual?', 'cualitativo', 'balance', 'Equilibrado'),
('Relación y Alianza', '¿Querremos seguir trabajando juntos?', 'cualitativo', 'sí/no', 'Sí'),
('Relación y Alianza', '¿La alianza se visibilizará externamente?', 'numero', 'menciones', '5+'),
('Relación y Alianza', '¿Atraeremos nuevos aliados gracias a esta colaboración?', 'numero', 'aliados', '2+'),
('Relación y Alianza', '¿La alianza tendrá nombre o identidad propia?', 'cualitativo', 'sí/no', 'Sí/No');
