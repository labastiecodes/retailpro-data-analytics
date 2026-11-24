# Pre-entrega 5 — Consultas con JOINs para el proyecto

**Estudiante:** Lucas Sosa · **Comisión:** #91080 · **Motor:** PostgreSQL 16 (aclarado en la primera línea del script)

## Archivos de esta carpeta

| Archivo | Qué es |
|---|---|
| [`m5_consultas_joins.sql`](m5_consultas_joins.sql) | El entregable: 4 consultas, cada una con un comentario de propósito y un `-- Hallazgo:` |
| [`evidencia/ejecucion.txt`](evidencia/ejecucion.txt) | Salida real de psql al ejecutar el archivo completo |

## Cómo ejecutarlo

Primero hay que crear y cargar la base con el script del Módulo 3 ([`../modulo-03`](../modulo-03)):

```bash
createdb ventas_tech_db
psql -v ON_ERROR_STOP=1 -d ventas_tech_db -f ../modulo-03/ventas_tech_db.sql
psql -v ON_ERROR_STOP=1 -d ventas_tech_db -f m5_consultas_joins.sql
```

El archivo no modifica la base: la prueba de las consultas 2 y 3 se hace dentro de `BEGIN ... ROLLBACK`.

## Resultados obtenidos (copiados de `evidencia/ejecucion.txt`)

**Consulta 1 — Vista base del proyecto (INNER JOIN de ventas + clientes + productos + categorias):** 10 filas, una por venta, con `id_venta, fecha_venta, id_cliente, cliente, ciudad_cliente, id_producto, producto, categoria, cantidad, precio_unitario, total_venta`. Columna para agrupar: `categoria`; columna para filtrar: `ciudad_cliente`.

> Hallazgo: Computación concentra 4950 de 6444 (76,8 %) con solo 4 de las 10 ventas. Buenos Aires lidera con 2640 (41,0 %) y Mendoza queda última con 510.

**Consulta 2 — Clientes sin ventas (LEFT JOIN + `WHERE v.id_venta IS NULL`):** 0 filas.

> Hallazgo: los 5 clientes registrados compraron, así que CRM no tiene clientes inactivos para reactivar; su foco pasa a subir el ticket de los clientes de menor gasto (Mendoza y Córdoba).

**Consulta 3 — Productos sin ventas (LEFT JOIN + `WHERE v.id_venta IS NULL`):** 0 filas.

> Hallazgo: los 6 productos se vendieron, así que el área de producto no tiene stock inmovilizado; sí hay baja rotación en SSD Externo 1TB y Teclado Mecánico (una venta cada uno).

**Prueba de las consultas 2 y 3:** con los datos de M3 dan 0 filas, así que el script carga 2 clientes y 2 productos sin ventas dentro de una transacción, repite las consultas y hace `ROLLBACK`. Las consultas los detectan:

| nombre | email | fecha_registro |
|---|---|---|
| Sofía Méndez | sofia@mail.com | 2024-03-18 |
| Diego Paz | diego@mail.com | 2024-03-20 |

| nombre_producto | categoria | precio |
|---|---|---|
| Webcam Full HD | Accesorios | 60.00 |
| Parlante BT Mini | Audio | 45.00 |

**Consulta 4 — Consolidado por canal (UNION ALL):** la columna `canal` se crea como texto fijo en cada `SELECT` (casa central = clientes de Buenos Aires; sucursales del interior = el resto). Las dos partes devuelven las mismas 3 columnas (`fecha_venta`, `total`, `canal`) en el mismo orden y con tipos compatibles.

| canal | cantidad_ventas | total_canal | ticket_promedio |
|---|---|---|---|
| Sucursales del interior | 8 | 3804.00 | 475.50 |
| Casa central (Buenos Aires) | 2 | 2640.00 | 1320.00 |

Control: 3804 + 2640 = 6444, el total del Módulo 4, así que ninguna venta se perdió ni se duplicó.

> Hallazgo: el interior factura más en total (59,0 %) porque tiene 4 clientes contra 1, pero la casa central vende casi el triple por venta (1320 contra 475,50).

## Checklist de la rúbrica

| Criterio (peso) | Cómo se cumple |
|---|---|
| Consulta 1 — INNER JOIN (35 %) | Une ventas con clientes, productos y categorias por sus FK y devuelve fecha, cliente, producto, cantidad, precio unitario y total, más categoría y ciudad |
| Consultas 2 y 3 — LEFT JOIN + IS NULL (30 %) | Ambas usan `LEFT JOIN` y `WHERE v.id_venta IS NULL`; cada hallazgo dice cuántos registros aparecieron y qué implica para CRM y para producto |
| Consulta 4 — UNION ALL (20 %) | Las dos partes tienen el mismo número y tipo de columnas; el `GROUP BY canal` calcula el total de cada canal |
| Organización y comentarios (15 %) | Cada consulta tiene un comentario que la identifica y explica su propósito, y un `-- Hallazgo:` debajo |
