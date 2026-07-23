-- ============================================================================
-- SCRIPT DE PREPARACIÓN - POSIBLES EXÁMENES GRUPO 2 - PIZZERÍA DON PICCOLO 🍕
-- ============================================================================
-- Este archivo contiene las 3 posibles variaciones simplificadas para el Grupo 2.
-- Si tu examen trata sobre Ingredientes, Ventas o Pagos, copia el bloque correspondiente.
-- ============================================================================

-- ============================================================================
-- SIMULACRO VARIACIÓN A: MÓDULO DE INGREDIENTES Y RECETAS (Muy probable)
-- ============================================================================
-- Escenario: La pizzería necesita monitorear el inventario de ingredientes y 
-- el costo de producción de cada tipo de pizza.

-- 1. Creación de tablas
CREATE TABLE IF NOT EXISTS ingredientes_simple (
    id_ingrediente INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    stock_actual INT NOT NULL DEFAULT 0,
    stock_minimo INT NOT NULL DEFAULT 5,
    costo_unidad DECIMAL(10, 2) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS recetas_simple (
    id_receta INT AUTO_INCREMENT PRIMARY KEY,
    id_pizza INT NOT NULL, -- FK a tabla pizzas
    id_ingrediente INT NOT NULL, -- FK a ingredientes_simple
    cantidad_requerida INT NOT NULL,
    CONSTRAINT fk_recetas_ingredientes FOREIGN KEY (id_ingrediente) 
        REFERENCES ingredientes_simple(id_ingrediente) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- 2. Consultas solicitadas
-- Consulta 1: Ingredientes con stock crítico (bajo el mínimo)
SELECT 
    nombre, 
    stock_actual, 
    stock_minimo, 
    (stock_minimo - stock_actual) AS faltante
FROM ingredientes_simple
WHERE stock_actual < stock_minimo;

-- Consulta 2: Costo de producción de cada pizza (Sumatoria de costo de sus ingredientes)
-- Suma: cantidad_requerida * costo_unidad
SELECT 
    p.nombre AS nombre_pizza,
    p.tamano,
    SUM(r.cantidad_requerida * i.costo_unidad) AS costo_produccion_total
FROM pizzas p
JOIN recetas_simple r ON p.id = r.id_pizza
JOIN ingredientes_simple i ON r.id_ingrediente = i.id_ingrediente
GROUP BY p.id, p.nombre, p.tamano;

-- Consulta 3: Ingredientes que no se usan en ninguna pizza (LEFT JOIN ... IS NULL)
SELECT 
    i.id_ingrediente,
    i.nombre
FROM ingredientes_simple i
LEFT JOIN recetas_simple r ON i.id_ingrediente = r.id_ingrediente
WHERE r.id_receta IS NULL;

-- 3. Vista resumen de inventario
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


-- ============================================================================
-- SIMULACRO VARIACIÓN B: MÓDULO DE CLIENTES Y VENTAS (Fidelización)
-- ============================================================================
-- Escenario: Analizar las ventas acumuladas por cliente y el comportamiento de compra.

-- 1. Creación de tablas
CREATE TABLE IF NOT EXISTS clientes_simple (
    id_cliente INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    telefono VARCHAR(20) NOT NULL,
    fecha_registro DATE DEFAULT (CURRENT_DATE)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS pedidos_simple (
    id_pedido INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente INT NOT NULL,
    fecha_pedido DATETIME DEFAULT CURRENT_TIMESTAMP,
    total DECIMAL(10, 2) NOT NULL,
    estado ENUM('pendiente', 'entregado', 'cancelado') NOT NULL DEFAULT 'pendiente',
    CONSTRAINT fk_pedidos_clientes_simple FOREIGN KEY (id_cliente) 
        REFERENCES clientes_simple(id_cliente) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- 2. Consultas solicitadas
-- Consulta 1: Clientes con mayor gasto acumulado en pedidos entregados
SELECT 
    c.nombre AS cliente,
    COUNT(p.id_pedido) AS compras_realizadas,
    SUM(p.total) AS total_gastado
FROM clientes_simple c
JOIN pedidos_simple p ON c.id_cliente = p.id_cliente
WHERE p.estado = 'entregado'
GROUP BY c.id_cliente, c.nombre
HAVING total_gastado > 100000.00 -- Umbral de compras VIP
ORDER BY total_gastado DESC;

-- Consulta 2: Pedidos demorados en pagarse o entregarse en un rango de fechas
SELECT 
    id_pedido, 
    fecha_pedido, 
    total 
FROM pedidos_simple
WHERE fecha_pedido BETWEEN '2026-07-01 00:00:00' AND '2026-07-22 23:59:59'
  AND estado = 'pendiente';

-- Consulta 3: Clientes nuevos que no han realizado ningún pedido (LEFT JOIN ... IS NULL)
SELECT 
    c.id_cliente,
    c.nombre,
    c.telefono
FROM clientes_simple c
LEFT JOIN pedidos_simple p ON c.id_cliente = p.id_cliente
WHERE p.id_pedido IS NULL;

-- 3. Vista resumen de ventas diarias
CREATE OR REPLACE VIEW vista_resumen_ventas_diarias AS
SELECT 
    DATE(fecha_pedido) AS fecha,
    COUNT(id_pedido) AS cantidad_pedidos,
    SUM(total) AS ingresos_totales,
    AVG(total) AS ticket_promedio
FROM pedidos_simple
WHERE estado = 'entregado'
GROUP BY DATE(fecha_pedido);


-- ============================================================================
-- SIMULACRO VARIACIÓN C: MÓDULO DE PAGOS Y FACTURACIÓN
-- ============================================================================
-- Escenario: Controlar la forma de pago y facturación de la pizzería.

-- 1. Creación de tablas
CREATE TABLE IF NOT EXISTS pagos_simple (
    id_pago INT AUTO_INCREMENT PRIMARY KEY,
    id_pedido INT NOT NULL UNIQUE,
    monto DECIMAL(10, 2) NOT NULL,
    metodo_pago ENUM('efectivo', 'tarjeta', 'nequi', 'daviplata') NOT NULL,
    fecha_pago DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- 2. Consultas solicitadas
-- Consulta 1: Ingresos totales y cantidad de transacciones por cada método de pago
SELECT 
    metodo_pago,
    COUNT(id_pago) AS transacciones,
    SUM(monto) AS total_recaudado
FROM pagos_simple
GROUP BY metodo_pago
ORDER BY total_recaudado DESC;

-- Consulta 2: Pedidos que superan el monto promedio de pagos
SELECT 
    id_pedido,
    monto
FROM pagos_simple
WHERE monto > (SELECT AVG(monto) FROM pagos_simple);

-- Consulta 3: Pedidos entregados que aún no registran pago (Auditoría / LEFT JOIN ... IS NULL)
-- Asume que hay una tabla pedidos en la base de datos
SELECT 
    pe.id AS id_pedido,
    pe.total AS total_pedido,
    pe.estado AS estado_pedido
FROM pedidos pe
LEFT JOIN pagos_simple pa ON pe.id = pa.id_pedido
WHERE pe.estado = 'entregado'
  AND pa.id_pago IS NULL;

-- 3. Vista flujo de caja diario
CREATE OR REPLACE VIEW vista_flujo_caja_diario AS
SELECT 
    DATE(fecha_pago) AS fecha,
    metodo_pago,
    SUM(monto) AS total_recaudado
FROM pagos_simple
GROUP BY DATE(fecha_pago), metodo_pago;
