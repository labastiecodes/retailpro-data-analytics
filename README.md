# Data Analytics · Coderhouse — Proyecto RetailPro

**Estudiante:** Lucas Sosa · **Comisión:** #91080

Repositorio con las entregas de código del curso, organizadas por módulo.

## Módulo 3 — Pre-entrega 3: Script SQL para esquema normalizado y datos iniciales

Archivo: [`modulo-03/ventas_tech_db.sql`](modulo-03/ventas_tech_db.sql)

Crea la base `Ventas_Tech_DB` en **SQL Server** con un modelo relacional en 3NF:

```
categorias (1) ──── (N) productos (1) ──── (N) ventas (N) ──── (1) clientes
```

| Tabla | Tipo | Registros | Claves |
|---|---|---|---|
| `categorias` | Dimensión | 4 | PK `id_categoria` |
| `clientes` | Dimensión | 5 | PK `id_cliente`, UNIQUE `email` |
| `productos` | Dimensión | 6 | PK `id_producto`, FK `id_categoria` → `categorias` |
| `ventas` | Hechos | 10 | PK `id_venta`, FK `id_cliente` → `clientes`, FK `id_producto` → `productos` |

### Secciones del script

1. **DROP**: elimina las tablas si existen, en orden inverso a las dependencias (`ventas` → `productos` → `clientes` → `categorias`). Gracias a esto el script es repetible.
2. **CREATE**: crea las tablas empezando por las que no dependen de nadie. Las PK y FK están definidas dentro de cada `CREATE TABLE`. Los precios usan `DECIMAL(10,2)` (nunca `FLOAT`) y las fechas usan `DATE`.
3. **INSERT**: carga los 25 registros en orden de dependencias, con las columnas explicitadas.
4. **VALIDACIÓN**: cuatro `SELECT` que devuelven 4, 5, 6 y 10 filas, un resumen de conteo por tabla y una prueba de integridad referencial con `TRY/CATCH` que confirma que las FK rechazan ventas con clientes o productos inexistentes.

### Cómo ejecutarlo

1. Abrir `ventas_tech_db.sql` en SQL Server Management Studio (SSMS), en SQL Server 2016 o superior (por `DROP TABLE IF EXISTS`).
2. Ejecutar el script completo (F5). Si la base `Ventas_Tech_DB` no existe, el propio script la crea y la selecciona.
3. Se puede volver a ejecutar las veces que haga falta sin errores.

## Módulo 4 — Pre-entrega 4: Consultas SQL de negocio

Archivo: [`modulo-04/m4_consultas_negocio.sql`](modulo-04/m4_consultas_negocio.sql)

Cuatro consultas sobre la tabla `ventas` de `Ventas_Tech_DB` (requiere haber ejecutado antes el script del Módulo 3):

| # | Consulta | Técnica | Resultado con los datos de M3 |
|---|---|---|---|
| 1 | Resumen ejecutivo mensual: total facturado, pedidos y ticket promedio | `GROUP BY YEAR/MONTH`, `SUM`, `COUNT`, `AVG` | Marzo 2024: 6444.00 · 10 pedidos · 644.40 |
| 2 | Top 5 de productos por facturación, con unidades vendidas | `GROUP BY`, `ORDER BY`, `TOP 5` | Producto 1 lidera con 3600.00 |
| 3 | Clientes recurrentes (más de un pedido) | `GROUP BY`, `HAVING COUNT(*) > 1` | Los 5 clientes, con 2 pedidos cada uno |
| 4 | Productos por encima o por debajo del promedio de facturación por producto | `WITH`, subconsulta, `CASE WHEN` | Promedio 1074.00: productos 1 y 3 por encima |

Al final del archivo hay un bloque de comentarios con 3 hallazgos de negocio.

## Módulo 5 — Pre-entrega 5: Consultas con JOINs para el proyecto

Archivo: [`modulo-05/m5_consultas_joins.sql`](modulo-05/m5_consultas_joins.sql)

Cuatro consultas que cruzan las tablas de `Ventas_Tech_DB` (requiere haber ejecutado antes el script del Módulo 3):

| # | Consulta | Técnica | Resultado con los datos de M3 |
|---|---|---|---|
| 1 | Vista base para Power BI: venta + cliente + ciudad + producto + categoría + total | `INNER JOIN` de 4 tablas | 10 filas, una por venta |
| 2 | Clientes sin ventas, para CRM | `LEFT JOIN` + `WHERE ... IS NULL` | 0 filas: los 5 clientes compraron |
| 3 | Productos sin ventas, para el área de producto | `LEFT JOIN` + `WHERE ... IS NULL` | 0 filas: los 6 productos se vendieron |
| 4 | Consolidado por canal: casa central (Buenos Aires) contra sucursales del interior | `UNION ALL` con columna literal + `GROUP BY` | Interior 3804.00 · Casa central 2640.00 |

Como las consultas 2 y 3 dan 0 filas con los datos actuales, el archivo incluye una prueba dentro de una transacción: carga 2 clientes y 2 productos sin ventas, repite las consultas (que los detectan) y hace `ROLLBACK`, así la base queda igual que antes. Cada consulta tiene un comentario con su propósito y otro con el hallazgo de negocio.
