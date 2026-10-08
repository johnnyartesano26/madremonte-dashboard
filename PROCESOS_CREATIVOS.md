# Procesos Creativos — Madre Monte

Dashboard para gestionar proyectos creativos con aliados (empresas, corporaciones o personas naturales). Cada proyecto tiene su propio tablero, con **4 fases**, indicadores de impacto y medición de avance.

- Prototipo: `procesos-creativos.html`
- (Futuro) URL pública: `https://johnnyartesano26.github.io/madremonte-dashboard/procesos-creativos.html`

---

## Modelo conceptual

```
Proyecto
 ├─ Fase 1 · Creación        → quién, tipo, responsables (solo admin / Madre Monte)
 ├─ Fase 2 · Equipo & Timeline → logos de marcas + Gantt (duración en semanas)
 ├─ Fase 3 · Dimensiones & Preguntas → 5 dimensiones + preguntas (catálogo)
 └─ Fase 4 · Mediciones & Avance  → semáforo, radar, gauges, historial
```

- **Fases (Gantt)** = el *cuándo* (línea de tiempo, como cuartiles del Scrum).
- **Dimensiones** = el *qué* (etapas/tópicos). No todas se abarcan desde el inicio; cada una tiene su propio ciclo de vida.
- **Preguntas → indicador + meta (100%) + responsable** = el *cómo medir*.
- **Mediciones (% + quién + cuándo)** = el *avance real*.

Gantt y dimensiones son **independientes**.

---

## Fases

| Fase | Qué hace | Visual |
|---|---|---|
| 🏷 **1 · Creación** | `nombre_aliado`, `tipo` (Cultural/Económico/Medioambiental/Otro), `responsable_mm`, `responsable_aliado`. Solo admin. | formulario |
| 🗓 **2 · Equipo & Timeline** | Logos de cada marca participante (opcional) + duración (meses/semanas). | Gantt (barras/hitos/%) |
| 🧭 **3 · Dimensiones & Preguntas** | 5 dimensiones + preguntas base (catálogo) + preguntas propias. | radar + lista |
| 📈 **4 · Mediciones & Avance** | Registro de avance (quién/cuándo) contra la meta. Recurrente. | gauges + radar + semáforo + historial |

---

## Dimensiones e indicadores

5 dimensiones (ampliables), 8 preguntas base cada una (catálogo de 40):

1. **Impacto Cultural** — ¿Transformará algo?
2. **Alcance y Comunidad** — ¿A quién llegará?
3. **Proceso y Equipo** — ¿Cómo trabajaremos?
4. **Sostenibilidad** — ¿Se mantendrá?
5. **Relación y Alianza** — ¿Nos fortalecerá?

Cada pregunta base tiene: `texto`, `tipo_indicador`, `unidad`, `meta (ejemplo)`.

**Tipos de indicador:** `número` · `porcentaje` · `escala (1-5)` · `cualitativo` (Sí/No, Alta, Equilibrado, Diverso…).

**Reglas:**
- Toda pregunta debe tener **indicador** y **meta** (= 100%).
- Se puede añadir indicadores propios, **nunca quitar los base**.
- Medición **al menos una vez por sprint**.
- Revisión en cada sprint review / retrospectiva.

---

## Semáforo

| Estado | Significado | Acción |
|---|---|---|
| 🟢 Verde | Meta ≥100% | Mantener y documentar |
| 🟡 Amarillo | 70–99% | Ajustar y monitorear |
| 🔴 Rojo | <70% | Intervenir y reflexionar |
| ⚪ Gris | Aún no medido | Definir cómo medirlo |

---

## Modelo de datos (Supabase, por crear)

| Tabla | Campos |
|---|---|
| `proyectos_creativos` | id, nombre_aliado, tipo, responsable_mm, responsable_aliado, estado, creado_por, creado_el |
| `participantes` | id, proyecto_id, nombre, rol, logo_url, creado_el |
| `fases` | id, proyecto_id, nombre, fecha_inicio, duracion_semanas, dependencia_id, avance_pct, es_hito, estado, responsable |
| `dimensiones` | id, proyecto_id, nombre, orden, estado |
| `preguntas` | id, dimension_id, texto, tipo_indicador, unidad, meta_valor, meta_descripcion, responsable, origen (catalogo/propia) |
| `mediciones` | id, pregunta_id, valor, valor_pct, creado_por, creado_el |
| `catalogo_preguntas` | id, dimension, texto, tipo_indicador, unidad, sugerencia_meta |

- `fecha_fin` de una fase se **calcula** = `fecha_inicio + duracion_semanas`.
- Logo se sube a **Supabase Storage** y se guarda la `logo_url`.
- Escritura con clave (SHA-256) + RLS, igual que `scrum.html`.

---

## Acceso / roles

- **Admin (Madre Monte)** crea proyectos y configura fases/dimensiones/preguntas.
- **Aliado** ve su proyecto y puede ingresar mediciones, con **auditoría** (`creado_por` + `creado_el`).
- Vista de portafolio solo para admin; el aliado ve solo su proyecto.

---

## Backlog (ideas futuras, priorizadas)

1. **Tendencia + historial** por indicador (línea en el tiempo) y pronóstico ("¿llegará a la meta?").
2. **Vista de portafolio** (todos los proyectos): treemap/heatmap, semáforo global, filtros, permisos por aliado.
3. **Cierre de sprint / revisión**: semáforo del cuartil + 10 preguntas de reflexión + "registrar decisión".
4. **Alertas automáticas por Telegram**: indicador en rojo o N semanas sin medir.
5. **Evidencia por medición**: adjuntar foto/PDF (Supabase Storage).
6. **Presupuesto**: rastreador de presupuesto vs real (D3.2).
7. **Reporte exportable**: PDF/imprimible por proyecto para aliados.
8. **Notas por medición + bitácora** cronológica del proyecto.

---

## Estado

- [x] Prototipo `procesos-creativos.html` (4 fases, catálogo 40 preguntas, Gantt, radar/barras/semáforo con ECharts).
- [ ] Crear tablas en Supabase (SQL Editor).
- [ ] Conectar Fase 1–4 a Supabase (escritura + lectura).
- [ ] Subida de logos (Supabase Storage).
- [ ] Gauges + historial real de mediciones.
- [ ] Backlog (arriba).
