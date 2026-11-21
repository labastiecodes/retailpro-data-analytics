-- Motor utilizado: SQL Server (T-SQL) - ejecutar en SQL Server Management Studio (SSMS)
/* =====================================================================
   Pre-entrega 3 - Script SQL para esquema normalizado y datos iniciales
   Base de datos : Ventas_Tech_DB
   Estudiante    : Lucas Sosa  -  Comisión #91080
   Curso         : Data Analytics - Coderhouse

   Modelo (3NF):
       categorias (1) ──── (N) productos (1) ──── (N) ventas (N) ──── (1) clientes
   - Dimensiones: categorias, clientes, productos
   - Hechos     : ventas

   El script es repetible: se puede ejecutar completo varias veces seguidas
   sin errores, porque primero elimina las tablas en orden inverso a sus
   dependencias y después las vuelve a crear y cargar.
   ===================================================================== */


-- =====================================================================
-- SECCIÓN 0: BASE DE DATOS
-- Crea la base solo si todavía no existe y la selecciona.
-- =====================================================================
IF DB_ID('Ventas_Tech_DB') IS NULL
    CREATE DATABASE Ventas_Tech_DB;
GO

USE Ventas_Tech_DB;
GO


-- =====================================================================
-- SECCIÓN 1: DROP
-- Orden inverso a las dependencias: primero las tablas que tienen FK
-- (ventas, luego productos) y al final las que son referenciadas.
-- =====================================================================
DROP TABLE IF EXISTS ventas;      -- depende de clientes y productos
DROP TABLE IF EXISTS productos;   -- depende de categorias
DROP TABLE IF EXISTS clientes;
DROP TABLE IF EXISTS categorias;
GO


-- =====================================================================
-- SECCIÓN 2: CREATE
-- Primero las tablas que no dependen de nadie (categorias, clientes),
-- después productos y al final la tabla de hechos (ventas).
-- Precios en DECIMAL(10,2), nunca FLOAT. Fechas en DATE.
-- =====================================================================

-- Dimensión: categorias
CREATE TABLE categorias (
    id_categoria      INT           NOT NULL,
    nombre_categoria  VARCHAR(50)   NOT NULL,
    descripcion       VARCHAR(200)  NULL,
    CONSTRAINT PK_categorias PRIMARY KEY (id_categoria)
);

-- Dimensión: clientes
CREATE TABLE clientes (
    id_cliente        INT           NOT NULL,
    nombre            VARCHAR(100)  NOT NULL,
    email             VARCHAR(100)  NULL,
    ciudad            VARCHAR(50)   NULL,
    fecha_registro    DATE          NOT NULL,
    CONSTRAINT PK_clientes PRIMARY KEY (id_cliente),
    CONSTRAINT UQ_clientes_email UNIQUE (email)
);

-- Dimensión: productos (cada producto pertenece a una categoría)
CREATE TABLE productos (
    id_producto       INT           NOT NULL,
    nombre_producto   VARCHAR(100)  NOT NULL,
    id_categoria      INT           NOT NULL,
    precio            DECIMAL(10,2) NOT NULL,
    stock             INT           NOT NULL CONSTRAINT DF_productos_stock  DEFAULT 0,
    activo            BIT           NOT NULL CONSTRAINT DF_productos_activo DEFAULT 1,
    CONSTRAINT PK_productos PRIMARY KEY (id_producto),
    CONSTRAINT FK_productos_categorias FOREIGN KEY (id_categoria)
        REFERENCES categorias (id_categoria),
    CONSTRAINT CK_productos_precio CHECK (precio >= 0),
    CONSTRAINT CK_productos_stock  CHECK (stock >= 0)
);

-- Hechos: ventas (cada venta apunta a un cliente y a un producto)
CREATE TABLE ventas (
    id_venta          INT           NOT NULL,
    id_cliente        INT           NOT NULL,
    id_producto       INT           NOT NULL,
    cantidad          INT           NOT NULL,
    precio_unitario   DECIMAL(10,2) NOT NULL,
    fecha_venta       DATE          NOT NULL,
    CONSTRAINT PK_ventas PRIMARY KEY (id_venta),
    CONSTRAINT FK_ventas_clientes FOREIGN KEY (id_cliente)
        REFERENCES clientes (id_cliente),
    CONSTRAINT FK_ventas_productos FOREIGN KEY (id_producto)
        REFERENCES productos (id_producto),
    CONSTRAINT CK_ventas_cantidad CHECK (cantidad > 0),
    CONSTRAINT CK_ventas_precio   CHECK (precio_unitario >= 0)
);
GO


-- =====================================================================
-- SECCIÓN 3: INSERT
-- 25 registros, en orden de dependencias: categorias (4) y clientes (5)
-- antes que productos (6), y ventas (10) al final.
-- Las columnas van explicitadas en cada INSERT.
-- =====================================================================

-- categorias: 4 registros
INSERT INTO categorias (id_categoria, nombre_categoria, descripcion) VALUES
  (1, 'Computación',    'Laptops, PCs y monitores'),
  (2, 'Accesorios',     'Periféricos y complementos'),
  (3, 'Audio',          'Auriculares y parlantes'),
  (4, 'Almacenamiento', 'Discos y memorias');

-- clientes: 5 registros
INSERT INTO clientes (id_cliente, nombre, email, ciudad, fecha_registro) VALUES
  (1, 'María López',  'maria@mail.com',  'Buenos Aires', '2024-01-05'),
  (2, 'Carlos Ruiz',  'carlos@mail.com', 'Córdoba',      '2024-01-10'),
  (3, 'Ana Gómez',    'ana@mail.com',    'Rosario',      '2024-02-01'),
  (4, 'Pedro Sanz',   'pedro@mail.com',  'Mendoza',      '2024-02-15'),
  (5, 'Laura Torres', 'laura@mail.com',  'Tucumán',      '2024-03-01');

-- productos: 6 registros
INSERT INTO productos (id_producto, nombre_producto, id_categoria, precio, stock, activo) VALUES
  (1, 'Laptop Pro 15',      1, 1200.00, 15, 1),
  (2, 'Mouse Inalámbrico',  2,   28.00, 80, 1),
  (3, 'Monitor 4K 27',      1,  450.00, 12, 1),
  (4, 'Auriculares BT Pro', 3,  120.00, 35, 1),
  (5, 'SSD Externo 1TB',    4,  130.00, 18, 1),
  (6, 'Teclado Mecánico',   2,   95.00, 40, 1);

-- ventas: 10 registros
INSERT INTO ventas (id_venta, id_cliente, id_producto, cantidad, precio_unitario, fecha_venta) VALUES
  ( 1, 1, 1, 2, 1200.00, '2024-03-05'),
  ( 2, 2, 2, 5,   28.00, '2024-03-06'),
  ( 3, 3, 3, 1,  450.00, '2024-03-07'),
  ( 4, 1, 4, 2,  120.00, '2024-03-08'),
  ( 5, 4, 5, 3,  130.00, '2024-03-10'),
  ( 6, 2, 6, 4,   95.00, '2024-03-11'),
  ( 7, 5, 1, 1, 1200.00, '2024-03-12'),
  ( 8, 3, 2, 8,   28.00, '2024-03-13'),
  ( 9, 4, 4, 1,  120.00, '2024-03-14'),
  (10, 5, 3, 2,  450.00, '2024-03-15');
GO


-- =====================================================================
-- SECCIÓN 4: VALIDACIÓN
-- Las cuatro consultas deben devolver 4, 5, 6 y 10 filas.
-- =====================================================================
SELECT * FROM categorias;   -- esperado: 4 filas
SELECT * FROM clientes;     -- esperado: 5 filas
SELECT * FROM productos;    -- esperado: 6 filas
SELECT * FROM ventas;       -- esperado: 10 filas

-- Resumen de control: cantidad de filas por tabla (total esperado: 25)
SELECT 'categorias' AS tabla, COUNT(*) AS filas FROM categorias
UNION ALL SELECT 'clientes',  COUNT(*) FROM clientes
UNION ALL SELECT 'productos', COUNT(*) FROM productos
UNION ALL SELECT 'ventas',    COUNT(*) FROM ventas;

-- Prueba de integridad referencial: se intenta cargar una venta con un
-- cliente que no existe (id 99). La FK debe rechazarla; el error se
-- captura con TRY/CATCH para que el script siga ejecutándose sin fallar.
BEGIN TRY
    INSERT INTO ventas (id_venta, id_cliente, id_producto, cantidad, precio_unitario, fecha_venta)
    VALUES (99, 99, 1, 1, 1200.00, '2024-03-20');
    PRINT 'ATENCIÓN: la venta con cliente inexistente se insertó (la FK no está funcionando).';
END TRY
BEGIN CATCH
    PRINT 'OK: la FK rechazó la venta con un cliente inexistente -> ' + ERROR_MESSAGE();
END CATCH;

-- Lo mismo con un producto inexistente (id 99).
BEGIN TRY
    INSERT INTO ventas (id_venta, id_cliente, id_producto, cantidad, precio_unitario, fecha_venta)
    VALUES (98, 1, 99, 1, 100.00, '2024-03-20');
    PRINT 'ATENCIÓN: la venta con producto inexistente se insertó (la FK no está funcionando).';
END TRY
BEGIN CATCH
    PRINT 'OK: la FK rechazó la venta con un producto inexistente -> ' + ERROR_MESSAGE();
END CATCH;

-- Después de las pruebas, ventas sigue teniendo exactamente 10 filas.
SELECT COUNT(*) AS ventas_despues_de_pruebas FROM ventas;   -- esperado: 10
GO
