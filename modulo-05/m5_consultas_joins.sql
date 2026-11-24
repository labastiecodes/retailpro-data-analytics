-- Motor utilizado: PostgreSQL 16 (ejecutado y verificado con psql 16.15; ver evidencia/)
/* =====================================================================
   Pre-entrega 5 - Consultas con JOINs: cruzando tablas para enriquecer
                   el análisis
   Base de datos : Ventas_Tech_DB (creada en M3 con modulo-03/ventas_tech_db.sql)
   Estudiante    : Lucas Sosa  -  Comisión #91080
   Curso         : Data Analytics - Coderhouse

   Esquema usado (M3):
       categorias (1) ── (N) productos (1) ── (N) ventas (N) ── (1) clientes
   Columnas para agrupar y filtrar en Power BI:
       - categorias.nombre_categoria  (agrupar por tipo de producto)
       - clientes.ciudad              (dimensión geográfica, para filtrar)
       - ventas.fecha_venta           (análisis temporal)

   Cómo ejecutarlo (detalle en modulo-05/README.md): primero correr el script
   del Módulo 3 y después, conectado a la misma base:
       psql -d ventas_tech_db -f m5_consultas_joins.sql
   ===================================================================== */


-- =====================================================================
-- CONSULTA 1 - Vista base del proyecto (INNER JOIN)
-- Propósito: armar en una sola fila por venta todo lo que necesita
-- Power BI: fecha, cliente, ciudad, producto, categoría, cantidad,
-- precio unitario y total. Es la fuente de datos principal del dashboard.
-- Cruce por claves foráneas:
--   ventas.id_cliente    -> clientes.id_cliente
--   ventas.id_producto   -> productos.id_producto
--   productos.id_categoria -> categorias.id_categoria
-- =====================================================================
SELECT
    v.id_venta,
    v.fecha_venta,
    c.id_cliente,
    c.nombre                              AS cliente,
    c.ciudad                              AS ciudad_cliente,
    p.id_producto,
    p.nombre_producto                     AS producto,
    cat.nombre_categoria                  AS categoria,
    v.cantidad,
    v.precio_unitario,
    v.cantidad * v.precio_unitario        AS total_venta
FROM ventas AS v
INNER JOIN clientes   AS c   ON c.id_cliente     = v.id_cliente
INNER JOIN productos  AS p   ON p.id_producto    = v.id_producto
INNER JOIN categorias AS cat ON cat.id_categoria = p.id_categoria
ORDER BY v.fecha_venta, v.id_venta;
-- Resultado: 10 filas, una por venta (las 10 ventas tienen cliente y
-- producto válidos, así que el INNER JOIN no descarta ninguna).
-- Hallazgo: Computación (Laptop Pro 15 y Monitor 4K 27) concentra 4950 de
-- los 6444 facturados (76,8%) con solo 4 de las 10 ventas; las otras tres
-- categorías juntas no llegan a 1500. Por ciudad, Buenos Aires lidera con
-- 2640 (41,0%) y Mendoza queda última con 510.


-- =====================================================================
-- CONSULTA 2 - Clientes sin ventas (LEFT JOIN)
-- Propósito: detectar clientes registrados que nunca compraron, para que
-- el área de CRM los contacte. El LEFT JOIN conserva todos los clientes;
-- los que no tienen ventas quedan con v.id_venta en NULL.
-- =====================================================================
SELECT
    c.nombre,
    c.email,
    c.fecha_registro
FROM clientes AS c
LEFT JOIN ventas AS v ON v.id_cliente = c.id_cliente
WHERE v.id_venta IS NULL
ORDER BY c.fecha_registro;
-- Resultado: 0 filas.
-- Hallazgo: los 5 clientes registrados compraron al menos una vez (todos
-- tienen 2 compras en marzo), así que CRM no tiene hoy clientes inactivos
-- para reactivar. Su foco debería pasar a subir la frecuencia y el ticket
-- de los clientes de menor gasto (Mendoza y Córdoba, ~510-520 cada uno).


-- =====================================================================
-- CONSULTA 3 - Productos sin ventas (LEFT JOIN)
-- Propósito: identificar artículos del catálogo sin movimiento, para que
-- el área de producto decida si los promociona, liquida o da de baja.
-- Se suma categorias con INNER JOIN porque todo producto tiene categoría
-- (FK NOT NULL); el LEFT JOIN contra ventas es el que aísla los casos.
-- =====================================================================
SELECT
    p.nombre_producto,
    cat.nombre_categoria AS categoria,
    p.precio
FROM productos AS p
INNER JOIN categorias AS cat ON cat.id_categoria = p.id_categoria
LEFT JOIN  ventas     AS v   ON v.id_producto    = p.id_producto
WHERE v.id_venta IS NULL
ORDER BY cat.nombre_categoria, p.nombre_producto;
-- Resultado: 0 filas.
-- Hallazgo: los 6 productos del catálogo tuvieron ventas, así que el área
-- de producto no tiene stock inmovilizado que liquidar. Lo que sí aparece
-- es baja rotación: SSD Externo 1TB y Teclado Mecánico tienen una sola
-- venta cada uno; son los candidatos a revisar si siguen así.


-- =====================================================================
-- PRUEBA DE LAS CONSULTAS 2 Y 3 (opcional, no modifica la base)
-- Con los datos de M3 las consultas 2 y 3 devuelven 0 filas. Para mostrar
-- que sí detectan casos, se cargan 2 clientes y 2 productos nuevos SIN
-- ventas dentro de una transacción, se repiten las consultas y al final
-- se hace ROLLBACK: la base queda exactamente como estaba.
-- Resultado esperado: consulta 2 -> 2 filas; consulta 3 -> 2 filas.
-- =====================================================================
BEGIN;

INSERT INTO clientes (id_cliente, nombre, email, ciudad, fecha_registro) VALUES
  (6, 'Sofía Méndez', 'sofia@mail.com', 'Salta',   '2024-03-18'),
  (7, 'Diego Paz',    'diego@mail.com', 'Neuquén', '2024-03-20');

INSERT INTO productos (id_producto, nombre_producto, id_categoria, precio, stock, activo) VALUES
  (7, 'Webcam Full HD',   2, 60.00, 25, TRUE),
  (8, 'Parlante BT Mini', 3, 45.00, 30, TRUE);

-- Consulta 2 repetida: devuelve Sofía Méndez y Diego Paz
SELECT c.nombre, c.email, c.fecha_registro
FROM clientes AS c
LEFT JOIN ventas AS v ON v.id_cliente = c.id_cliente
WHERE v.id_venta IS NULL
ORDER BY c.fecha_registro;

-- Consulta 3 repetida: devuelve Webcam Full HD y Parlante BT Mini
SELECT p.nombre_producto, cat.nombre_categoria AS categoria, p.precio
FROM productos AS p
INNER JOIN categorias AS cat ON cat.id_categoria = p.id_categoria
LEFT JOIN  ventas     AS v   ON v.id_producto    = p.id_producto
WHERE v.id_venta IS NULL
ORDER BY cat.nombre_categoria, p.nombre_producto;

ROLLBACK;   -- deshace los 4 registros de prueba


-- =====================================================================
-- CONSULTA 4 - Consolidado por canal (UNION ALL)
-- Propósito: comparar cuánto vende la casa central contra las
-- sucursales del interior. La columna canal no existe en las tablas: se
-- crea como texto fijo en cada SELECT. Criterio: la ciudad del cliente
-- (Buenos Aires = casa central; el resto = sucursales del interior).
-- Las dos partes devuelven las mismas 3 columnas, en el mismo orden y con
-- los mismos tipos (DATE, DECIMAL, VARCHAR). Se usa UNION ALL y no UNION
-- para que ninguna venta se descarte por coincidir con otra en todos sus
-- valores. El "OR c.ciudad IS NULL" evita perder ventas de clientes sin
-- ciudad cargada.
-- =====================================================================
SELECT
    canal,
    COUNT(*)                          AS cantidad_ventas,
    SUM(total)                        AS total_canal,
    CAST(AVG(total) AS DECIMAL(10,2)) AS ticket_promedio
FROM (
    SELECT v.fecha_venta,
           v.cantidad * v.precio_unitario AS total,
           'Casa central (Buenos Aires)'  AS canal
    FROM ventas AS v
    INNER JOIN clientes AS c ON c.id_cliente = v.id_cliente
    WHERE c.ciudad = 'Buenos Aires'

    UNION ALL

    SELECT v.fecha_venta,
           v.cantidad * v.precio_unitario AS total,
           'Sucursales del interior'      AS canal
    FROM ventas AS v
    INNER JOIN clientes AS c ON c.id_cliente = v.id_cliente
    WHERE c.ciudad <> 'Buenos Aires' OR c.ciudad IS NULL
) AS consolidado
GROUP BY canal
ORDER BY total_canal DESC;
-- Resultado:
--   Sucursales del interior     | 8 | 3804.00 |  475.50
--   Casa central (Buenos Aires) | 2 | 2640.00 | 1320.00
--   (control: 3804 + 2640 = 6444, el total de M4; no se perdió ni se
--    duplicó ninguna venta)
-- Hallazgo: el interior factura más en total (3804, 59,0%), pero porque
-- tiene 4 clientes contra 1; por venta, la casa central vende casi el
-- triple (ticket de 1320 contra 475,50), impulsada por una compra de 2
-- laptops. Conviene llevar al interior la oferta de equipos de mayor valor.
