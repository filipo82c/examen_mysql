-- ============================================================================
-- VISTAS DE REPORTES - PIZZERÍA DON PICCOLO
-- ============================================================================

USE pizzeria_don_piccolo;

-- Eliminar vistas existentes para evitar errores de duplicación
DROP VIEW IF EXISTS vista_resumen_pedidos_cliente;
DROP VIEW IF EXISTS vista_desempeno_repartidores;
DROP VIEW IF EXISTS vista_stock_critico_ingredientes;

-- ============================================================================
-- 1. VISTA: vista_resumen_pedidos_cliente
-- ============================================================================
-- Resumen de la actividad comercial por cliente: nombre, número de pedidos
-- realizados y el monto total gastado en pedidos (excluyendo cancelados).
-- ============================================================================
CREATE VIEW vista_resumen_pedidos_cliente AS
SELECT 
    c.nombre AS nombre_cliente,
    c.telefono,
    COUNT(p.id) AS cantidad_pedidos,
    COALESCE(SUM(CASE WHEN p.estado <> 'cancelado' THEN p.total ELSE 0.00 END), 0.00) AS total_gastado
FROM clientes c
LEFT JOIN pedidos p ON c.id = p.cliente_id
GROUP BY c.id, c.nombre, c.telefono;

-- ============================================================================
-- 2. VISTA: vista_desempeno_repartidores
-- ============================================================================
-- Reporte de eficiencia de los repartidores: número de entregas completadas,
-- tiempo promedio de entrega en minutos (desde salida hasta entrega) y zona.
-- ============================================================================
CREATE VIEW vista_desempeno_repartidores AS
SELECT 
    r.nombre AS nombre_repartidor,
    z.nombre_zona AS zona,
    COUNT(d.id) AS numero_entregas,
    ROUND(COALESCE(AVG(TIMESTAMPDIFF(MINUTE, d.hora_salida, d.hora_entrega)), 0), 1) AS tiempo_promedio_minutos
FROM repartidores r
JOIN zonas z ON r.zona_id = z.id
LEFT JOIN domicilios d ON r.id = d.repartidor_id AND d.hora_entrega IS NOT NULL
GROUP BY r.id, r.nombre, z.nombre_zona;

-- ============================================================================
-- 3. VISTA: vista_stock_critico_ingredientes
-- ============================================================================
-- Muestra la lista de ingredientes cuyo stock actual se encuentra por debajo
-- del stock mínimo permitido, indicando la cantidad faltante para abastecerse.
-- ============================================================================
CREATE VIEW vista_stock_critico_ingredientes AS
SELECT 
    id,
    nombre AS ingrediente,
    stock AS stock_actual,
    stock_minimo,
    (stock_minimo - stock) AS cantidad_faltante
FROM ingredientes
WHERE stock < stock_minimo;
