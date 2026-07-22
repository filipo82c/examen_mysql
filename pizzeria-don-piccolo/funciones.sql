-- ============================================================================
-- FUNCIONES Y PROCEDIMIENTOS ALMACENADOS - PIZZERÍA DON PICCOLO
-- ============================================================================

USE pizzeria_don_piccolo;

-- Eliminar funciones y procedimientos existentes para evitar errores de duplicación
DROP FUNCTION IF EXISTS fn_calcular_total_pedido;
DROP FUNCTION IF EXISTS fn_calcular_ganancia_neta_diaria;
DROP PROCEDURE IF EXISTS sp_registrar_entrega_pedido;

DELIMITER //

-- ============================================================================
-- 1. FUNCIÓN: fn_calcular_total_pedido
-- ============================================================================
-- Calcula el total facturado para un pedido específico, sumando el precio de 
-- las pizzas solicitadas, el costo de envío (si aplica) y el IVA (19%).
-- ============================================================================
CREATE FUNCTION fn_calcular_total_pedido(p_pedido_id INT)
RETURNS DECIMAL(10, 2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_subtotal_pizzas DECIMAL(10, 2) DEFAULT 0.00;
    DECLARE v_costo_envio DECIMAL(10, 2) DEFAULT 0.00;
    DECLARE v_iva DECIMAL(10, 2) DEFAULT 0.00;
    DECLARE v_total DECIMAL(10, 2) DEFAULT 0.00;

    -- 1. Calcular el subtotal de pizzas vendidas (congelado en pedido_pizzas)
    SELECT COALESCE(SUM(subtotal), 0.00) INTO v_subtotal_pizzas
    FROM pedido_pizzas
    WHERE pedido_id = p_pedido_id;

    -- 2. Obtener el costo de envío de la tabla domicilios (si aplica)
    SELECT COALESCE(costo_envio, 0.00) INTO v_costo_envio
    FROM domicilios
    WHERE pedido_id = p_pedido_id;

    -- 3. Calcular IVA del 19% sobre el subtotal de pizzas
    SET v_iva = v_subtotal_pizzas * 0.19;

    -- 4. Calcular el total final
    SET v_total = v_subtotal_pizzas + v_costo_envio + v_iva;

    RETURN v_total;
END //

-- ============================================================================
-- 2. FUNCIÓN: fn_calcular_ganancia_neta_diaria
-- ============================================================================
-- Calcula la ganancia neta diaria restando el costo total de los ingredientes
-- consumidos de las ventas totales de pizzas realizadas en una fecha dada.
-- Excluye pedidos cancelados.
-- ============================================================================
CREATE FUNCTION fn_calcular_ganancia_neta_diaria(p_fecha DATE)
RETURNS DECIMAL(10, 2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_ventas_pizzas DECIMAL(10, 2) DEFAULT 0.00;
    DECLARE v_costos_ingredientes DECIMAL(10, 2) DEFAULT 0.00;
    DECLARE v_ganancia_neta DECIMAL(10, 2) DEFAULT 0.00;

    -- 1. Obtener la venta total de pizzas (sin incluir envío ni IVA)
    SELECT COALESCE(SUM(pp.subtotal), 0.00) INTO v_ventas_pizzas
    FROM pedido_pizzas pp
    JOIN pedidos p ON pp.pedido_id = p.id
    WHERE DATE(p.fecha_hora) = p_fecha
      AND p.estado != 'cancelado';

    -- 2. Obtener el costo total de ingredientes utilizados en esas pizzas
    SELECT COALESCE(SUM(pp.cantidad * pi.cantidad_requerida * i.costo), 0.00) INTO v_costos_ingredientes
    FROM pedido_pizzas pp
    JOIN pedidos p ON pp.pedido_id = p.id
    JOIN pizza_ingredientes pi ON pp.pizza_id = pi.pizza_id
    JOIN ingredientes i ON pi.ingrediente_id = i.id
    WHERE DATE(p.fecha_hora) = p_fecha
      AND p.estado != 'cancelado';

    -- 3. Calcular ganancia neta
    SET v_ganancia_neta = v_ventas_pizzas - v_costos_ingredientes;

    RETURN v_ganancia_neta;
END //

-- ============================================================================
-- 3. PROCEDIMIENTO ALMACENADO: sp_registrar_entrega_pedido
-- ============================================================================
-- Registra la hora de entrega de un domicilio y cambia automáticamente el estado
-- del pedido correspondiente a "entregado".
-- ============================================================================
CREATE PROCEDURE sp_registrar_entrega_pedido(
    IN p_pedido_id INT,
    IN p_hora_entrega DATETIME
)
BEGIN
    -- Declarar variables para manejar errores o verificar existencia
    DECLARE v_existe_domicilio INT DEFAULT 0;

    -- Verificar si existe el domicilio asociado al pedido
    SELECT COUNT(*) INTO v_existe_domicilio
    FROM domicilios
    WHERE pedido_id = p_pedido_id;

    IF v_existe_domicilio > 0 THEN
        -- 1. Actualizar la hora de entrega en la tabla de domicilios
        UPDATE domicilios
        SET hora_entrega = p_hora_entrega
        WHERE pedido_id = p_pedido_id;
        
        -- 2. Cambiar el estado del pedido en la tabla pedidos
        UPDATE pedidos
        SET estado = 'entregado'
        WHERE id = p_pedido_id;
    ELSE
        -- Si no existe domicilio, lanzar un error informativo
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: No se encontró un domicilio registrado para este ID de pedido.';
    END IF;
END //

DELIMITER ;
