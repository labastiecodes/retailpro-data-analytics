# Data Analytics · Coderhouse — Proyecto RetailPro

**Estudiante:** Lucas Sosa · **Comisión:** #91080

Entregas de código del curso. **Cada pre-entrega tiene su propia carpeta** con el script, un README con instrucciones de ejecución, los resultados obtenidos, un checklist de la rúbrica y la evidencia de ejecución (salida real de `psql`).

| Pre-entrega | Carpeta | Archivo entregable | Evidencia |
|---|---|---|---|
| 3 — Script SQL: esquema normalizado y datos iniciales | [`modulo-03/`](modulo-03) | [`ventas_tech_db.sql`](modulo-03/ventas_tech_db.sql) | [`evidencia/`](modulo-03/evidencia) (2 ejecuciones seguidas) |
| 4 — Consultas SQL de negocio | [`modulo-04/`](modulo-04) | [`m4_consultas_negocio.sql`](modulo-04/m4_consultas_negocio.sql) | [`evidencia/`](modulo-04/evidencia) |
| 5 — Consultas con JOINs | [`modulo-05/`](modulo-05) | [`m5_consultas_joins.sql`](modulo-05/m5_consultas_joins.sql) | [`evidencia/`](modulo-05/evidencia) |

## Motor y ejecución

Motor: **PostgreSQL 16**, aclarado en la primera línea de cada script, como permite la consigna. Equivalencias con SQL Server: `BIT` → `BOOLEAN`, `TOP 5` → `LIMIT 5`, `MONTH()` → `EXTRACT(MONTH FROM ...)`.

Orden de ejecución (los módulos 4 y 5 usan la base que crea el módulo 3):

```bash
createdb ventas_tech_db
psql -v ON_ERROR_STOP=1 -d ventas_tech_db -f modulo-03/ventas_tech_db.sql
psql -v ON_ERROR_STOP=1 -d ventas_tech_db -f modulo-04/m4_consultas_negocio.sql
psql -v ON_ERROR_STOP=1 -d ventas_tech_db -f modulo-05/m5_consultas_joins.sql
```

Modelo de `ventas_tech_db` (3NF):

```
categorias (1) ──── (N) productos (1) ──── (N) ventas (N) ──── (1) clientes
```
