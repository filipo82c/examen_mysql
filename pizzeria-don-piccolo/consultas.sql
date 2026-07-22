-- ============================================================================
-- CONSULTAS SQL REQUERIDAS DE NEGOCIO - PIZZERÍA DON PICCOLO
-- ============================================================================

USE pizzeria_don_piccolo;

-- 1. Clientes con pedidos entre dos fechas (Uso de BETWEEN)
-- Retorna los clientes únicos que realizaron compras en un rango de fechas.
SELECT DISTINCT 
    c.id AS cliente_id,
    c.nombre AS nombre_cliente,
    c.telefono,
    c.correo_electronico
FROM clientes c
JOIN pedidos p ON c.id = p.cliente_id
WHERE p.fecha_hora BETWEEN '2026-07-01 00:00:00' AND '2026-07-15 23:59:59'
ORDER BY c.nombre;

-- 2. Pizzas más vendidas (Uso de GROUP BY, COUNT y SUM)
-- Muestra las pizzas ordenadas de mayor a menor según las unidades totales vendidas y cantidad de pedidos.
SELECT 
    pi.id AS pizza_id,
    pi.nombre AS nombre_pizza,
    pi.tamano,
    COUNT(pp.pedido_id) AS cantidad_pedidos,
    SUM(pp.cantidad) AS total_unidades_vendidas
FROM pizzas pi
JOIN pedido_pizzas pp ON pi.id = pp.pizza_id
GROUP BY pi.id, pi.nombre, pi.tamano
ORDER BY total_unidades_vendidas DESC;

-- 3. Pedidos por repartidor (Uso de JOIN)
-- Lista cada repartidor junto con el detalle de los pedidos y domicilios que tiene asignados.
SELECT 
    r.id AS repartidor_id,
    r.nombre AS nombre_repartidor,
    p.id AS pedido_id,
    p.fecha_hora AS fecha_pedido,
    p.estado AS estado_pedido,
    d.distancia_km,
    d.costo_envio,
    d.hora_salida,
    d.hora_entrega
FROM repartidores r
JOIN domicilios d ON r.id = d.repartidor_id
JOIN pedidos p ON d.pedido_id = p.id
ORDER BY r.nombre, p.fecha_hora DESC;

-- 4. Promedio de entrega por zona (Uso de AVG y JOIN)
-- Calcula el tiempo promedio en minutos que tardan las entregas en completarse por zona geográfica.
SELECT 
    z.id AS zona_id,
    z.nombre_zona,
    ROUND(AVG(TIMESTAMPDIFF(MINUTE, d.hora_salida, d.hora_entrega)), 1) AS tiempo_promedio_entrega_minutos,
    COUNT(d.id) AS total_entregas_evaluadas
FROM zonas z
JOIN repartidores r ON z.id = r.zona_id
JOIN domicilios d ON r.id = d.repartidor_id
WHERE d.hora_entrega IS NOT NULL
GROUP BY z.id, z.nombre_zona
ORDER BY tiempo_promedio_entrega_minutos ASC;

-- 5. Clientes que gastaron más de un monto (Uso de HAVING)
-- Filtra clientes cuyo gasto total acumulado en la pizzería supere un umbral (ejemplo: $150,000). Excluye pedidos cancelados.
SELECT 
    c.id AS cliente_id,
    c.nombre AS nombre_cliente,
    c.telefono,
    SUM(p.total) AS total_gastado
FROM clientes c
JOIN pedidos p ON c.id = p.cliente_id
WHERE p.estado <> 'cancelado'
GROUP BY c.id, c.nombre, c.telefono
HAVING total_gastado > 150000.00
ORDER BY total_gastado DESC;

-- 6. Búsqueda por coincidencia parcial de nombre de pizza (Uso de LIKE)
-- Busca pizzas que contengan un fragmento de texto en su nombre (ejemplo: 'Piccolo' o 'Margarita').
SELECT 
    id AS pizza_id,
    nombre AS nombre_pizza,
    tamano,
    precio_base,
    tipo
FROM pizzas
WHERE nombre LIKE '%Piccolo%'
ORDER BY nombre;

-- 7. Subconsulta para obtener los clientes frecuentes (más de 5 pedidos mensuales)
-- Retorna la información completa de clientes que han hecho más de 5 pedidos en el mes de Julio de 2026.
SELECT 
    id AS cliente_id,
    nombre AS nombre_cliente,
    telefono,
    direccion,
    correo_electronico
FROM clientes
WHERE id IN (
    SELECT cliente_id
    FROM pedidos
    WHERE fecha_hora BETWEEN '2026-07-01 00:00:00' AND '2026-07-31 23:59:59'
      AND estado <> 'cancelado'
    GROUP BY cliente_id
    HAVING COUNT(id) > 5
);
