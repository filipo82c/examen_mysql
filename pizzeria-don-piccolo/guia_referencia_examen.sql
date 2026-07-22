/* 
============================================================================
       GUÍA DE REFERENCIA RÁPIDA - REPASO Y PLANTILLAS DE EXAMEN SQL 🍕
============================================================================
Este archivo contiene las explicaciones y estructuras clave que necesitas
para el examen práctico. Al estar escrito en formato SQL, puedes tenerlo
abierto directamente en DBeaver como una pestaña de código más.

----------------------------------------------------------------------------
TEMARIO:
1. SINTAXIS DDL COMPLETA (Tablas, Constraints, FKs, CASCADE vs RESTRICT)
2. DIFERENCIAS CLAVE Y SINTAXIS (Funciones vs Procedimientos vs Triggers)
3. SINTAXIS DE DELIMITERS
4. TRUCOS DE MANEJO DE FECHAS (TIMESTAMPDIFF, DATEDIFF, DATE, NOW)
5. TRUCOS DE AGREGACIONES (LEFT JOIN... IS NULL, GROUP BY, HAVING, COALESCE)
6. TRICK: RESOLVER ERROR 1093 (Modificar y consultar misma tabla)
7. TRICK: RESOLVER ERROR 1419 (Privilegios bin log en Linux)
8. RETO 1 COMPLETO: Sistema de Puntos de Fidelidad (AFTER UPDATE)
9. RETO 2 COMPLETO: Historial / Alertas de Stock Crítico (AFTER UPDATE)
10. RETO 3 COMPLETO: Validación / Bloqueo de Compras sin Insumos (BEFORE INSERT)
11. RETO 4 COMPLETO: Descuento dinámico antes de insertar (BEFORE INSERT)
12. EXAMEN GRUPO 1 COMPLETO: Módulo de Repartidores y Domicilios (Entregas)
13. EXAMEN GRUPO 2 VARIACIÓN A: Módulo de Ingredientes y Recetas (Recetario)
14. EXAMEN GRUPO 2 VARIACIÓN B: Módulo de Clientes y Ventas (Fidelización)
15. EXAMEN GRUPO 2 VARIACIÓN C: Módulo de Pagos y Facturación (Caja)
----------------------------------------------------------------------------
*/

-- ============================================================================
-- 1. SINTAXIS DDL COMPLETA (CREACIÓN DE TABLAS Y LLAVES FORÁNEAS)
-- ============================================================================
/*
CREATE TABLE nombre_tabla (
    id_campo INT AUTO_INCREMENT,
    nombre_var VARCHAR(100) NOT NULL,
    precio DECIMAL(10, 2) NOT NULL CHECK (precio >= 0), -- Evita valores negativos
    estado ENUM('activo', 'inactivo') NOT NULL DEFAULT 'activo',
    correo VARCHAR(100) UNIQUE, -- Impide duplicados
    id_padre INT NOT NULL,
    CONSTRAINT pk_tabla PRIMARY KEY (id_campo),
    -- Llave Foránea y políticas de integridad referencial:
    CONSTRAINT fk_tabla_padre FOREIGN KEY (id_padre) 
        REFERENCES tabla_padre(id_padre)
        -- ON DELETE CASCADE: Si se borra el padre, se borra este hijo automáticamente.
        -- ON DELETE RESTRICT: Impide borrar al padre si este hijo existe (Protección).
        -- ON DELETE SET NULL: Si se borra el padre, el campo id_padre en el hijo pasa a ser NULL.
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB; -- Motor indispensable para transacciones y llaves foráneas.
*/


-- ============================================================================
-- 2. DIFERENCIAS CLAVE Y SINTAXIS DE ESTRUCTURAS
-- ============================================================================
/*
A. VISTAS (VIEWS)
- Qué es: Una tabla virtual basada en una consulta SELECT. No almacena datos físicamente.
- Limitación: Si contiene SUM, AVG, COUNT, GROUP BY o JOIN, es NO ACTUALIZABLE (no admite INSERT/UPDATE).
- Sintaxis:
    CREATE OR REPLACE VIEW nombre_vista AS
    SELECT columnas FROM tabla;

B. FUNCIONES (FUNCTIONS)
- Qué es: Bloque de código para hacer un cálculo. RETORNA OBLIGATORIAMENTE UN ÚNICO VALOR.
- Uso: Se puede invocar dentro de un SELECT normal (ej: SELECT fn_calcular_total(5);).
- Sintaxis:
    CREATE FUNCTION fn_nombre(parametro INT)
    RETURNS DECIMAL(10,2)
    DETERMINISTIC -- Indica que para el mismo parámetro siempre devuelve lo mismo.
    BEGIN
        DECLARE v_resultado DECIMAL(10,2);
        SELECT SUM(subtotal) INTO v_resultado FROM detalles WHERE pedido_id = parametro;
        RETURN COALESCE(v_resultado, 0.00);
    END;

C. PROCEDIMIENTOS ALMACENADOS (STORED PROCEDURES)
- Qué es: Bloques de transacciones que modifican el estado. NO retornan valor directo.
- Uso: Se ejecutan usando la palabra clave CALL (ej: CALL sp_cancelar_pedido(5);).
- Sintaxis:
    CREATE PROCEDURE sp_nombre(IN parametro_id INT, OUT parametro_salida VARCHAR(100))
    BEGIN
        UPDATE pedidos SET estado = 'cancelado' WHERE id = parametro_id;
        SET parametro_salida = 'Proceso completado';
    END;

D. TRIGGERS (DISPARADORES)
- Qué es: Código automático ante INSERT, UPDATE o DELETE. Trabaja por fila.
- Variables especiales:
    * NEW.columna: Acceso a datos nuevos que ingresan (Disponible en INSERT y UPDATE).
    * OLD.columna: Acceso a datos viejos que ya existían (Disponible en UPDATE y DELETE).
*/


-- ============================================================================
-- 3. SINTAXIS DE DELIMITERS (POR QUÉ SE USA)
-- ============================================================================
-- Se usa DELIMITER // para cambiar temporalmente el caracter de fin de línea.
-- Esto evita que MySQL crea que la función termina en el primer ";" interno.
-- Ejemplo:
-- DELIMITER //
-- CREATE ... BEGIN ... END //
-- DELIMITER ; -- Siempre restablecer a punto y coma al final


-- ============================================================================
-- 4. TRUCOS DE MANEJO DE FECHAS EN MYSQL
-- ============================================================================
/*
- TIMESTAMPDIFF(unit, datetime1, datetime2): Calcula la diferencia de tiempo en la unidad indicada.
  Unidades posibles: SECOND, MINUTE, HOUR, DAY, MONTH, YEAR.
  Ejemplo: TIMESTAMPDIFF(MINUTE, hora_salida, hora_entrega) -> Minutos transcurridos.
  
- DATEDIFF(date1, date2): Diferencia en días enteros (date1 - date2).
- DATE(datetime): Extrae solo la parte de fecha (AAAA-MM-DD) de un DATETIME.
- NOW() o CURRENT_TIMESTAMP(): Fecha y hora actual completa.
- CURRENT_DATE() o CURDATE(): Fecha actual sin hora.
*/


-- ============================================================================
-- 5. TRUCOS DE AGREGACIONES Y JOINS AVANZADOS
-- ============================================================================
/*
- LEFT JOIN + IS NULL (Buscar registros sin relación):
  Permite auditar. Ej: Clientes que nunca han comprado nada:
  SELECT c.nombre FROM clientes c LEFT JOIN pedidos p ON c.id = p.cliente_id WHERE p.id IS NULL;

- COALESCE(valor, reemplazo): Si el primer valor es NULL, lo reemplaza por el segundo.
  Ej: COALESCE(SUM(total), 0.00) -> Evita que el total acumulado se muestre como NULL.

- CASE WHEN: Estructura condicional dentro de un SELECT.
  Ej: SELECT nombre, CASE WHEN stock < stock_minimo THEN 'Crítico' ELSE 'OK' END AS estado FROM ingredientes;

- HAVING vs WHERE:
  * WHERE filtra filas individuales ANTES de agrupar. No acepta funciones agregadas (SUM, AVG).
  * HAVING filtra grupos DESPUÉS de agrupar. Acepta variables calculadas en el SELECT.
*/


-- ============================================================================
-- 6. RESOLVER ERROR 1093 (SELECT Y UPDATE A LA MISMA TABLA)
-- ============================================================================
-- ERROR: "You can't specify target table 'pedidos' for update in FROM clause"
-- SOLUCIÓN: Envolver el SELECT en otra tabla temporal interna usando alias (AS).
-- Forma que da error:
--    UPDATE pedidos SET estado = 'entregado' WHERE id = (SELECT MAX(id) FROM pedidos);
-- Forma correcta que funciona:
--    UPDATE pedidos SET estado = 'entregado' 
--    WHERE id = (SELECT id_max FROM (SELECT MAX(id) AS id_max FROM pedidos) AS temp);


-- ============================================================================
-- 7. RESOLVER ERROR 1419 (PRIVILEGIOS DE CREACIÓN EN LINUX)
-- ============================================================================
-- ERROR: "You do not have the SUPER privilege and binary logging is enabled..."
-- SOLUCIÓN: Ejecutar este comando en la terminal de Linux de tu laptop:
--    sudo mysql -e "SET GLOBAL log_bin_trust_function_creators = 1;"


-- ============================================================================
-- 8. RETO 1: SISTEMA DE PUNTOS DE FIDELIDAD (AFTER UPDATE)
-- ============================================================================
-- Objetivo: Sumar 1 punto por cada $10,000 comprados al pasar pedido a 'entregado'.

-- Paso A: Agregar columna puntos
-- ALTER TABLE clientes ADD COLUMN puntos INT DEFAULT 0;

-- Paso B: Crear Trigger
/*
DELIMITER //
CREATE TRIGGER trg_acumular_puntos
AFTER UPDATE ON pedidos
FOR EACH ROW
BEGIN
    -- Validar cambio de estado de pendiente/preparación a entregado
    IF NEW.estado = 'entregado' AND OLD.estado <> 'entregado' THEN
        UPDATE clientes
        SET puntos = puntos + FLOOR(NEW.total / 10000)
        WHERE id = NEW.cliente_id;
    END IF;
END //
DELIMITER ;
*/


-- ============================================================================
-- 9. RETO 2: HISTORIAL / ALERTAS DE STOCK BAJO (AFTER UPDATE)
-- ============================================================================
-- Objetivo: Registrar alertas cuando el stock de un ingrediente cae del mínimo.

-- Paso A: Crear tabla alertas
/*
CREATE TABLE IF NOT EXISTS alertas_stock (
    id INT AUTO_INCREMENT PRIMARY KEY,
    ingrediente_id INT NOT NULL,
    stock_registrado INT NOT NULL,
    fecha_alerta DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_alertas_ingredientes FOREIGN KEY (ingrediente_id) 
        REFERENCES ingredientes(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Paso B: Crear Trigger
DELIMITER //
CREATE TRIGGER trg_alerta_stock_critico
AFTER UPDATE ON ingredientes
FOR EACH ROW
BEGIN
    -- Si el stock baja de su mínimo, y antes estaba bien (evita spam de alertas)
    IF NEW.stock < NEW.stock_minimo AND OLD.stock >= OLD.stock_minimo THEN
        INSERT INTO alertas_stock (ingrediente_id, stock_registrado)
        VALUES (NEW.id, NEW.stock);
    END IF;
END //
DELIMITER ;
*/


-- ============================================================================
-- 10. RETO 3: VALIDACIÓN / BLOQUEO DE COMPRAS (BEFORE INSERT)
-- ============================================================================
-- Objetivo: Bloquear el pedido usando SIGNAL si no hay ingredientes suficientes.

/*
DELIMITER //
CREATE TRIGGER trg_validar_stock_antes_pedido
BEFORE INSERT ON pedido_pizzas
FOR EACH ROW
BEGIN
    DECLARE v_nombre_ingrediente VARCHAR(50) DEFAULT NULL;
    DECLARE v_stock_disponible INT DEFAULT 0;
    DECLARE v_stock_requerido INT DEFAULT 0;
    DECLARE v_mensaje_error VARCHAR(255);

    -- Buscar si hay algún ingrediente para esta pizza que no alcance en stock
    SELECT i.nombre, i.stock, (pi.cantidad_requerida * NEW.cantidad)
    INTO v_nombre_ingrediente, v_stock_disponible, v_stock_requerido
    FROM pizza_ingredientes pi
    JOIN ingredientes i ON pi.ingrediente_id = i.id
    WHERE pi.pizza_id = NEW.pizza_id 
      AND i.stock < (pi.cantidad_requerida * NEW.cantidad)
    LIMIT 1;

    -- Si encontramos un ingrediente insuficiente, bloqueamos la compra
    IF v_nombre_ingrediente IS NOT NULL THEN
        SET v_mensaje_error = CONCAT('ERROR: STOCK INSUFICIENTE PARA ', v_nombre_ingrediente, 
                                     ' REQUERIDO: ', v_stock_requerido, 
                                     ' DISPONIBLE: ', v_stock_disponible);
        
        -- Lanzar el error para abortar el INSERT
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = v_mensaje_error;
    END IF;
END //
DELIMITER ;
*/


-- ============================================================================
-- 11. RETO 4: ENVÍO GRATIS A CLIENTES VIP (BEFORE INSERT)
-- ============================================================================
-- Objetivo: Poner en $0 el costo de envío de un domicilio si el cliente es VIP (> $100k consumidos).

/*
DELIMITER //
CREATE TRIGGER trg_envio_gratis_vip
BEFORE INSERT ON domicilios
FOR EACH ROW
BEGIN
    DECLARE v_total_gastado DECIMAL(10, 2) DEFAULT 0.00;
    DECLARE v_cliente_id INT;

    -- 1. Buscar el cliente asociado a este pedido
    SELECT cliente_id INTO v_cliente_id 
    FROM pedidos 
    WHERE id = NEW.pedido_id;

    -- 2. Sumar el total de compras no canceladas de ese cliente
    SELECT COALESCE(SUM(total), 0.00) INTO v_total_gastado
    FROM pedidos
    WHERE cliente_id = v_cliente_id AND estado <> 'cancelado';

    -- 3. Si sus compras totales superan $100,000, su costo de envío pasa a 0
    IF v_total_gastado > 100000.00 THEN
        SET NEW.costo_envio = 0.00;
    END IF;
END //
DELIMITER ;
*/


-- ============================================================================
-- 12. EXAMEN GRUPO 1 COMPLETO: MÓDULO DE REPARTIDORES Y DOMICILIOS (ENTREGAS)
-- ============================================================================
/*
-- A. Creación de Tablas Simplificadas
CREATE TABLE repartidores_simple (
    id_repartidor INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    telefono VARCHAR(20) NOT NULL,
    zona_asignada VARCHAR(100) NOT NULL,
    estado ENUM('activo', 'inactivo') NOT NULL DEFAULT 'activo'
) ENGINE=InnoDB;

CREATE TABLE domicilios_simple (
    id_domicilio INT AUTO_INCREMENT PRIMARY KEY,
    id_pedido INT NOT NULL UNIQUE,
    id_repartidor INT NOT NULL,
    hora_salida DATETIME NOT NULL,
    hora_entrega DATETIME NULL,
    estado ENUM('en_ruta', 'entregado', 'cancelado') NOT NULL DEFAULT 'en_ruta',
    CONSTRAINT fk_dom_rep FOREIGN KEY (id_repartidor) 
        REFERENCES repartidores_simple(id_repartidor) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- B. Consultas Solicitadas
-- Consulta 1: Entregas realizadas por cada repartidor y total acumulado
SELECT 
    r.nombre AS repartidor,
    COUNT(d.id_domicilio) AS entregas_realizadas,
    COALESCE(SUM(p.total), 0.00) AS total_acumulado_pedidos
FROM repartidores_simple r
LEFT JOIN domicilios_simple d ON r.id_repartidor = d.id_repartidor AND d.estado = 'entregado'
LEFT JOIN pedidos p ON d.id_pedido = p.id
GROUP BY r.id_repartidor, r.nombre;

-- Consulta 2: Pedidos demorados (Tardaron más de 40 minutos)
SELECT 
    id_pedido,
    hora_salida,
    hora_entrega,
    TIMESTAMPDIFF(MINUTE, hora_salida, hora_entrega) AS minutos_demora
FROM domicilios_simple
WHERE estado = 'entregado' 
  AND TIMESTAMPDIFF(MINUTE, hora_salida, hora_entrega) > 40;

-- Consulta 3: Repartidores activos sin entregas asignadas (LEFT JOIN IS NULL)
SELECT r.id_repartidor, r.nombre 
FROM repartidores_simple r
LEFT JOIN domicilios_simple d ON r.id_repartidor = d.id_repartidor
WHERE r.estado = 'activo' AND d.id_domicilio IS NULL;

-- C. Vista Resumen de Desempeño
CREATE OR REPLACE VIEW vista_desempeno_repartidor AS
SELECT 
    r.nombre AS nombre_repartidor,
    COUNT(d.id_domicilio) AS entregas_totales,
    AVG(TIMESTAMPDIFF(MINUTE, d.hora_salida, d.hora_entrega)) AS promedio_minutos_entrega
FROM repartidores_simple r
LEFT JOIN domicilios_simple d ON r.id_repartidor = d.id_repartidor AND d.estado = 'entregado'
GROUP BY r.id_repartidor, r.nombre;
*/


-- ============================================================================
-- 13. EXAMEN GRUPO 2 VARIACIÓN A: MÓDULO DE INGREDIENTES Y RECETAS (RECETARIO)
-- ============================================================================
/*
-- A. Creación de Tablas Simplificadas
CREATE TABLE ingredientes_simple (
    id_ingrediente INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    stock_actual INT NOT NULL DEFAULT 0,
    stock_minimo INT NOT NULL DEFAULT 5,
    costo_unidad DECIMAL(10, 2) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE recetas_simple (
    id_receta INT AUTO_INCREMENT PRIMARY KEY,
    id_pizza INT NOT NULL,
    id_ingrediente INT NOT NULL,
    cantidad_requerida INT NOT NULL,
    CONSTRAINT fk_rec_ing FOREIGN KEY (id_ingrediente) 
        REFERENCES ingredientes_simple(id_ingrediente) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- B. Consultas Solicitadas
-- Consulta 1: Ingredientes con stock por debajo del stock mínimo (Stock Crítico)
SELECT nombre, stock_actual, stock_minimo, (stock_minimo - stock_actual) AS faltante
FROM ingredientes_simple
WHERE stock_actual < stock_minimo;

-- Consulta 2: Costo de producción de cada pizza (Suma de costo de ingredientes)
SELECT 
    p.nombre AS nombre_pizza,
    p.tamano,
    SUM(r.cantidad_requerida * i.costo_unidad) AS costo_produccion
FROM pizzas p
JOIN recetas_simple r ON p.id = r.id_pizza
JOIN ingredientes_simple i ON r.id_ingrediente = i.id_ingrediente
GROUP BY p.id, p.nombre, p.tamano;

-- Consulta 3: Ingredientes activos sin usar en ninguna receta (LEFT JOIN IS NULL)
SELECT i.id_ingrediente, i.nombre
FROM ingredientes_simple i
LEFT JOIN recetas_simple r ON i.id_ingrediente = r.id_ingrediente
WHERE r.id_receta IS NULL;

-- C. Vista Resumen de Inventario
CREATE OR REPLACE VIEW vista_resumen_inventario AS
SELECT 
    nombre AS ingrediente,
    stock_actual,
    CASE 
        WHEN stock_actual = 0 THEN 'Agotado'
        WHEN stock_actual < stock_minimo THEN 'Crítico'
        ELSE 'Suficiente'
    END AS estado_stock
FROM ingredientes_simple;
*/


-- ============================================================================
-- 14. EXAMEN GRUPO 2 VARIACIÓN B: MÓDULO DE CLIENTES Y VENTAS (FIDELIZACIÓN)
-- ============================================================================
/*
-- A. Creación de Tablas Simplificadas
CREATE TABLE clientes_simple (
    id_cliente INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    telefono VARCHAR(20) NOT NULL,
    fecha_registro DATE DEFAULT (CURRENT_DATE)
) ENGINE=InnoDB;

CREATE TABLE pedidos_simple (
    id_pedido INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente INT NOT NULL,
    fecha_pedido DATETIME DEFAULT CURRENT_TIMESTAMP,
    total DECIMAL(10, 2) NOT NULL,
    estado ENUM('pendiente', 'entregado', 'cancelado') NOT NULL DEFAULT 'pendiente',
    CONSTRAINT fk_ped_clie FOREIGN KEY (id_cliente) 
        REFERENCES clientes_simple(id_cliente) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- B. Consultas Solicitadas
-- Consulta 1: Clientes VIP con mayor gasto acumulado en pedidos entregados
SELECT 
    c.nombre AS cliente,
    COUNT(p.id_pedido) AS compras_realizadas,
    SUM(p.total) AS total_gastado
FROM clientes_simple c
JOIN pedidos_simple p ON c.id_cliente = p.id_cliente
WHERE p.estado = 'entregado'
GROUP BY c.id_cliente, c.nombre
HAVING total_gastado > 100000.00
ORDER BY total_gastado DESC;

-- Consulta 2: Pedidos pendientes creados en un rango de fechas
SELECT id_pedido, fecha_pedido, total 
FROM pedidos_simple
WHERE estado = 'pendiente'
  AND fecha_pedido BETWEEN '2026-07-01 00:00:00' AND '2026-07-22 23:59:59';

-- Consulta 3: Clientes nuevos que no han realizado ningún pedido (LEFT JOIN IS NULL)
SELECT c.id_cliente, c.nombre, c.telefono
FROM clientes_simple c
LEFT JOIN pedidos_simple p ON c.id_cliente = p.id_cliente
WHERE p.id_pedido IS NULL;

-- C. Vista Resumen de Ventas Diarias
CREATE OR REPLACE VIEW vista_resumen_ventas_diarias AS
SELECT 
    DATE(fecha_pedido) AS fecha,
    COUNT(id_pedido) AS cantidad_pedidos,
    SUM(total) AS ingresos_totales,
    AVG(total) AS ticket_promedio
FROM pedidos_simple
WHERE estado = 'entregado'
GROUP BY DATE(fecha_pedido);
*/


-- ============================================================================
-- 15. EXAMEN GRUPO 2 VARIACIÓN C: MÓDULO DE PAGOS Y FACTURACIÓN (CAJA)
-- ============================================================================
/*
-- A. Creación de Tablas Simplificadas
CREATE TABLE pagos_simple (
    id_pago INT AUTO_INCREMENT PRIMARY KEY,
    id_pedido INT NOT NULL UNIQUE,
    monto DECIMAL(10, 2) NOT NULL,
    metodo_pago ENUM('efectivo', 'tarjeta', 'nequi', 'daviplata') NOT NULL,
    fecha_pago DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- B. Consultas Solicitadas
-- Consulta 1: Ingresos totales y cantidad de transacciones por cada método de pago
SELECT 
    metodo_pago,
    COUNT(id_pago) AS transacciones,
    SUM(monto) AS total_recaudado
FROM pagos_simple
GROUP BY metodo_pago
ORDER BY total_recaudado DESC;

-- Consulta 2: Pedidos que superan el monto promedio de pagos de la pizzería
SELECT id_pedido, monto
FROM pagos_simple
WHERE monto > (SELECT AVG(monto) FROM pagos_simple);

-- Consulta 3: Pedidos entregados que aún no registran pago (Auditoría / LEFT JOIN IS NULL)
SELECT 
    pe.id AS id_pedido,
    pe.total AS total_pedido
FROM pedidos pe
LEFT JOIN pagos_simple pa ON pe.id = pa.id_pedido
WHERE pe.estado = 'entregado'
  AND pa.id_pago IS NULL;

-- C. Vista Flujo de Caja Diario
CREATE OR REPLACE VIEW vista_flujo_caja_diario AS
SELECT 
    DATE(fecha_pago) AS fecha,
    metodo_pago,
    SUM(monto) AS total_recaudado
FROM pagos_simple
GROUP BY DATE(fecha_pago), metodo_pago;
*/
