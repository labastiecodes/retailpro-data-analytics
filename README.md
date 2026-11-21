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
