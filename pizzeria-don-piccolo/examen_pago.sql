-- creacion de tabla --

CREATE TABLE pagos_simple (
id_pago INT AUTO_INCREMENT PRIMARY KEY,
id_pedido INT NOT NULL UNIQUE,
monto DECIMAL(12, 1) NOT NULL ,
metodo_pago ENUM ('efectivo', 'tarjeta de credito', 'Nequi', 'Daviplata' ) NOT NULL,
fecha_pago DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;


-- consultas solicitadas --
-- esta consulta es ingresos totales --

SELECT 
    metodo_pago,
    COUNT(id_pago) AS transacciones,
    SUM(monto) AS total_recaudado
FROM pagos_simple
GROUP BY metodo_pago
ORDER BY total_recaudado DESC;

-- los pedidos que superan el monto --
SELECT id_pedido, monto
FROM pagos_simple
WHERE monto > (SELECT AVG(monto) FROM pagos_simple);

-- pedidos entregados que aún no registran pago ---

SELECT 
    pe.id AS id_pedido,
    pe.total AS total_pedido
FROM pedidos pe
LEFT JOIN pagos_simple pa ON pe.id = pa.id_pedido
WHERE pe.estado = 'entregado'
  AND pa.id_pago IS NULL;


-- vista del flujo --

CREATE OR REPLACE VIEW vista_flujo_caja_diario AS
SELECT 
    DATE(fecha_pago) AS fecha,
    metodo_pago,
    SUM(monto) AS total_recaudado
FROM pagos_simple
GROUP BY DATE(fecha_pago), metodo_pago;
*/
