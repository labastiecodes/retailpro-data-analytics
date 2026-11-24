-- Motor utilizado: PostgreSQL 16 (ejecutado y verificado con psql 16.15; ver evidencia/)
/* =====================================================================
   Pre-entrega 4 - Consultas SQL de negocio: extrayendo métricas clave
   Base de datos : Ventas_Tech_DB (creada en M3 con modulo-03/ventas_tech_db.sql)
   Estudiante    : Lucas Sosa  -  Comisión #91080
   Curso         : Data Analytics - Coderhouse

   Todas las consultas trabajan solo sobre la tabla ventas
   (id_venta, id_cliente, id_producto, cantidad, precio_unitario, fecha_venta).
   Importe de cada venta = cantidad * precio_unitario.
   Cada fila de ventas (id_venta) se cuenta como un pedido.

   Cómo ejecutarlo (detalle en modulo-04/README.md): primero correr el script
   del Módulo 3 y después, conectado a la misma base:
       psql -d ventas_tech_db -f m4_consultas_negocio.sql

   Equivalencias con SQL Server (según la consigna):
   - MONTH(fecha_venta) -> EXTRACT(MONTH FROM fecha_venta)
   - YEAR(fecha_venta)  -> EXTRACT(YEAR FROM fecha_venta)
   - SELECT TOP 5 ...   -> ... LIMIT 5
   ===================================================================== */


-- =====================================================================
-- CONSULTA 1 - Resumen ejecutivo mensual
-- Total facturado, cantidad de pedidos y ticket promedio por mes.
-- Se agrupa también por año para que, cuando haya datos de más de un año,
-- marzo 2024 y marzo 2025 no se sumen juntos.
-- Resultado esperado con los datos de M3: 1 fila (marzo 2024).
-- =====================================================================
SELECT
    EXTRACT(YEAR FROM fecha_venta)                           AS anio,
    EXTRACT(MONTH FROM fecha_venta)                          AS mes,
    SUM(cantidad * precio_unitario)                          AS total_facturado,
    COUNT(*)                                                 AS cantidad_pedidos,
    CAST(AVG(cantidad * precio_unitario) AS DECIMAL(10,2))   AS ticket_promedio
FROM ventas
GROUP BY EXTRACT(YEAR FROM fecha_venta), EXTRACT(MONTH FROM fecha_venta)
ORDER BY anio, mes;
-- Resultado: 2024 | 3 | 6444.00 | 10 | 644.40


-- =====================================================================
-- CONSULTA 2 - Ranking de productos
-- Top 5 de id_producto por total facturado, con unidades vendidas.
-- =====================================================================
SELECT
    id_producto,
    SUM(cantidad)                      AS unidades_vendidas,
    SUM(cantidad * precio_unitario)    AS total_facturado
FROM ventas
GROUP BY id_producto
ORDER BY total_facturado DESC
LIMIT 5;                                   -- equivale a TOP 5 de SQL Server
-- Resultado:
--   1 |  3 | 3600.00
--   3 |  3 | 1350.00
--   5 |  3 |  390.00
--   6 |  4 |  380.00
--   2 | 13 |  364.00   (queda afuera el producto 4: 3 unidades, 360.00)


-- =====================================================================
-- CONSULTA 3 - Clientes recurrentes
-- id_cliente con más de un pedido, cantidad de pedidos y total gastado.
-- HAVING filtra después de agrupar (WHERE no puede usar COUNT).
-- =====================================================================
SELECT
    id_cliente,
    COUNT(*)                           AS cantidad_pedidos,
    SUM(cantidad * precio_unitario)    AS total_gastado
FROM ventas
GROUP BY id_cliente
HAVING COUNT(*) > 1
ORDER BY total_gastado DESC;
-- Resultado:
--   1 | 2 | 2640.00
--   5 | 2 | 2100.00
--   3 | 2 |  674.00
--   2 | 2 |  520.00
--   4 | 2 |  510.00


-- =====================================================================
-- CONSULTA 4 - Productos por encima / por debajo del promedio
-- Paso 1 (WITH): total facturado por producto.
-- Paso 2 (subconsulta): promedio de esos totales por producto
--         -> 6444.00 / 6 productos = 1074.00
--         (no es el promedio de las filas de ventas, que sería 644.40).
-- Paso 3 (CASE WHEN): etiqueta cada producto contra ese promedio.
-- =====================================================================
WITH totales_por_producto AS (
    SELECT
        id_producto,
        SUM(cantidad * precio_unitario) AS total_facturado
    FROM ventas
    GROUP BY id_producto
)
SELECT
    id_producto,
    total_facturado,
    (SELECT CAST(AVG(total_facturado) AS DECIMAL(10,2))
       FROM totales_por_producto)                            AS promedio_por_producto,
    CASE
        WHEN total_facturado > (SELECT AVG(total_facturado) FROM totales_por_producto)
            THEN 'Por encima'
        ELSE 'Por debajo'
    END                                                      AS comparacion_promedio
FROM totales_por_producto
ORDER BY total_facturado DESC;
-- Resultado:
--   1 | 3600.00 | 1074.00 | Por encima
--   3 | 1350.00 | 1074.00 | Por encima
--   5 |  390.00 | 1074.00 | Por debajo
--   6 |  380.00 | 1074.00 | Por debajo
--   2 |  364.00 | 1074.00 | Por debajo
--   4 |  360.00 | 1074.00 | Por debajo


-- =====================================================================
-- HALLAZGOS
-- =====================================================================
-- 1. La facturación está muy concentrada: el producto 1 (Laptop Pro 15)
--    factura 3600 de 6444 (55,9%) y, junto con el producto 3 (Monitor 4K 27),
--    suma 4950 (76,8%). Son los únicos 2 de 6 productos por encima del
--    promedio de 1074. Acción: priorizar stock y disponibilidad de estos
--    dos productos, porque un quiebre de stock pega en tres cuartos de la
--    facturación.
--
-- 2. Vender muchas unidades no significa facturar mucho: el producto 2
--    (Mouse Inalámbrico) es el que más unidades vende (13 de 29, el 44,8%)
--    pero factura solo 364 (5,6%). Acción: usarlo como
--    producto gancho en combos con laptops y monitores para subir el
--    ticket promedio, hoy en 644,40.
--
-- 3. Los 5 clientes compraron 2 veces en marzo (100% de recurrencia),
--    pero el gasto es muy desigual: los clientes 1 y 5 suman 4740 (73,6%)
--    y los otros tres gastan entre 510 y 674. Acción: armar un programa de
--    fidelización para los clientes 1 y 5 y ofertas de productos de mayor
--    valor a los clientes 2, 3 y 4. Hay que tomarlo con cautela: son solo
--    10 ventas de un mes, así que conviene repetir el análisis con más
--    meses antes de decidir.
-- =====================================================================
