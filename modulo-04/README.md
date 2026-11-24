# Pre-entrega 4 — Consultas SQL de negocio

**Estudiante:** Lucas Sosa · **Comisión:** #91080 · **Motor:** PostgreSQL 16 (aclarado en la primera línea del script)

## Archivos de esta carpeta

| Archivo | Qué es |
|---|---|
| [`m4_consultas_negocio.sql`](m4_consultas_negocio.sql) | El entregable: las 4 consultas y el bloque de 3 hallazgos al final |
| [`evidencia/ejecucion.txt`](evidencia/ejecucion.txt) | Salida real de psql al ejecutar el archivo completo |

## Cómo ejecutarlo

Primero hay que crear y cargar la base con el script del Módulo 3 ([`../modulo-03`](../modulo-03)):

```bash
createdb ventas_tech_db
psql -v ON_ERROR_STOP=1 -d ventas_tech_db -f ../modulo-03/ventas_tech_db.sql
psql -v ON_ERROR_STOP=1 -d ventas_tech_db -f m4_consultas_negocio.sql
```

Todas las consultas trabajan solo sobre la tabla `ventas`, como pide la consigna. El importe de cada venta es `cantidad * precio_unitario`.

Equivalencias con SQL Server: `MONTH(fecha_venta)` → `EXTRACT(MONTH FROM fecha_venta)` y `TOP 5` → `LIMIT 5`.

## Resultados obtenidos (copiados de `evidencia/ejecucion.txt`)

**Consulta 1 — Resumen ejecutivo mensual** (`GROUP BY` año y mes; 1 fila, como anticipa la consigna)

| anio | mes | total_facturado | cantidad_pedidos | ticket_promedio |
|---|---|---|---|---|
| 2024 | 3 | 6444.00 | 10 | 644.40 |

**Consulta 2 — Ranking de productos** (`GROUP BY id_producto`, `ORDER BY total_facturado DESC`, `LIMIT 5`)

| id_producto | unidades_vendidas | total_facturado |
|---|---|---|
| 1 | 3 | 3600.00 |
| 3 | 3 | 1350.00 |
| 5 | 3 | 390.00 |
| 6 | 4 | 380.00 |
| 2 | 13 | 364.00 |

**Consulta 3 — Clientes recurrentes** (`GROUP BY id_cliente`, `HAVING COUNT(*) > 1`)

| id_cliente | cantidad_pedidos | total_gastado |
|---|---|---|
| 1 | 2 | 2640.00 |
| 5 | 2 | 2100.00 |
| 3 | 2 | 674.00 |
| 2 | 2 | 520.00 |
| 4 | 2 | 510.00 |

**Consulta 4 — Productos por encima / por debajo del promedio** (`WITH` + subconsulta + `CASE WHEN`). El promedio es el de los **totales por producto**: 6444 / 6 = 1074.00 (no el de las filas de ventas, que sería 644.40).

| id_producto | total_facturado | promedio_por_producto | comparacion_promedio |
|---|---|---|---|
| 1 | 3600.00 | 1074.00 | Por encima |
| 3 | 1350.00 | 1074.00 | Por encima |
| 5 | 390.00 | 1074.00 | Por debajo |
| 6 | 380.00 | 1074.00 | Por debajo |
| 2 | 364.00 | 1074.00 | Por debajo |
| 4 | 360.00 | 1074.00 | Por debajo |

## Hallazgos (resumen del bloque de cierre del script)

1. **Facturación concentrada:** el producto 1 (Laptop Pro 15) factura el 55,9 % del total y, junto con el producto 3, el 76,8 %. Conviene priorizar su stock.
2. **Muchas unidades no es mucha facturación:** el producto 2 (Mouse Inalámbrico) es el 44,8 % de las unidades pero solo el 5,6 % de lo facturado. Sirve como producto gancho en combos.
3. **Recurrencia total pero gasto desigual:** los 5 clientes compraron 2 veces; los clientes 1 y 5 explican el 73,6 % del gasto. Son 10 ventas de un solo mes, así que el análisis se debe repetir con más datos.

## Checklist de la rúbrica

| Criterio (peso) | Cómo se cumple |
|---|---|
| Consulta 1 (20 %) | Agrupa por mes, calcula total, pedidos y ticket promedio con alias en español; ejecuta sin errores |
| Consulta 2 (20 %) | Ordenada por total facturado descendente, muestra id_producto, unidades y total, limitada a 5 |
| Consulta 3 (25 %) | `GROUP BY id_cliente` + `HAVING COUNT(*) > 1`; los totales suman 6444, igual que la consulta 1 |
| Consulta 4 (25 %) | Total por producto en el `WITH`, promedio de esos totales en la subconsulta y etiqueta con `CASE WHEN` |
| Hallazgos (10 %) | 3 hallazgos con cifras concretas y una acción de negocio cada uno, en el bloque de comentarios final |
