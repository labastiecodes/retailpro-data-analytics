# Pre-entrega 3 — Script SQL para esquema normalizado y datos iniciales

**Estudiante:** Lucas Sosa · **Comisión:** #91080 · **Motor:** PostgreSQL 16 (la consigna lo permite si se aclara en la primera línea del script, y así está)

## Archivos de esta carpeta

| Archivo | Qué es |
|---|---|
| [`ventas_tech_db.sql`](ventas_tech_db.sql) | El entregable: script con las 4 secciones DROP, CREATE, INSERT y VALIDACIÓN |
| [`evidencia/ejecucion_1.txt`](evidencia/ejecucion_1.txt) | Salida real de psql al ejecutar el script sobre una base vacía |
| [`evidencia/ejecucion_2.txt`](evidencia/ejecucion_2.txt) | Salida real de psql al ejecutarlo **por segunda vez seguida** (prueba de que es repetible) |

## Cómo ejecutarlo

Requisito: PostgreSQL 14 o superior instalado (con `psql` o pgAdmin).

```bash
createdb ventas_tech_db
psql -v ON_ERROR_STOP=1 -d ventas_tech_db -f ventas_tech_db.sql
# se puede volver a correr la misma línea: no da errores
psql -v ON_ERROR_STOP=1 -d ventas_tech_db -f ventas_tech_db.sql
```

Con pgAdmin: crear la base `ventas_tech_db`, abrir el Query Tool sobre ella, abrir el archivo y ejecutarlo completo (F5).

## Modelo

```
categorias (1) ──── (N) productos (1) ──── (N) ventas (N) ──── (1) clientes
```

| Tabla | Tipo | Columnas y tipos | Claves y restricciones |
|---|---|---|---|
| `categorias` | Dimensión | id_categoria INT, nombre_categoria VARCHAR(50), descripcion VARCHAR(200) | PK id_categoria · nombre NOT NULL |
| `clientes` | Dimensión | id_cliente INT, nombre VARCHAR(100), email VARCHAR(100), ciudad VARCHAR(50), fecha_registro DATE | PK id_cliente · email UNIQUE · nombre y fecha NOT NULL |
| `productos` | Dimensión | id_producto INT, nombre_producto VARCHAR(100), id_categoria INT, precio DECIMAL(10,2), stock INT, activo BOOLEAN | PK id_producto · FK id_categoria → categorias · stock DEFAULT 0 · activo DEFAULT TRUE |
| `ventas` | Hechos | id_venta INT, id_cliente INT, id_producto INT, cantidad INT, precio_unitario DECIMAL(10,2), fecha_venta DATE | PK id_venta · FK id_cliente → clientes · FK id_producto → productos · cantidad, precio y fecha NOT NULL |

`activo` es `BOOLEAN` porque en PostgreSQL es el equivalente de `BIT` (tabla de equivalencias de la consigna).

## Resultado de la validación (de `evidencia/ejecucion_2.txt`)

| tabla | filas | esperado |
|---|---|---|
| categorias | 4 | 4 |
| clientes | 5 | 5 |
| productos | 6 | 6 |
| ventas | 10 | 10 |

Prueba de integridad referencial incluida en el script (al final de la sección 4):

```
NOTICE:  OK: la FK rechazo la venta con cliente inexistente -> insert or update on table "ventas" violates foreign key constraint "fk_ventas_clientes"
NOTICE:  OK: la FK rechazo la venta con producto inexistente -> insert or update on table "ventas" violates foreign key constraint "fk_ventas_productos"
 ventas_despues_de_pruebas
---------------------------
                        10
```

Las dos ejecuciones terminan con `Código de salida de psql: 0` (sin errores). En la primera, los `DROP TABLE IF EXISTS` informan que las tablas no existían; en la segunda las eliminan y las vuelven a crear.

## Checklist de la rúbrica

| Criterio (peso) | Cómo se cumple | Dónde verlo |
|---|---|---|
| Estructura y tipos de datos (30 %) | 4 tablas con las columnas y tipos de la consigna, PK en las 4, precios en `DECIMAL(10,2)` (no hay ningún `FLOAT`), fechas en `DATE` | Sección 2 del script |
| Foreign Keys e integridad referencial (30 %) | `productos → categorias`, `ventas → clientes`, `ventas → productos`, todas `NOT NULL`; la prueba muestra que se rechazan ventas con cliente o producto inexistente | Sección 2 y final de la sección 4; `NOTICE` en las evidencias |
| INSERT y orden de carga (25 %) | Los 25 registros exactos, en orden categorias → clientes → productos → ventas, con columnas explicitadas; ningún error de integridad durante la carga | Sección 3; `INSERT 0 4/5/6/10` en las evidencias |
| Organización y validación (15 %) | Secciones separadas con comentarios `-- SECCIÓN 1..4`; los 4 `SELECT` devuelven 4, 5, 6 y 10 filas | Sección 4; tabla de arriba |
| Repetible | `DROP TABLE IF EXISTS` en orden inverso a las dependencias | `evidencia/ejecucion_2.txt` (segunda corrida, sin errores) |
