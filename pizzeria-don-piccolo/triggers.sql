-- ============================================================================
-- DISPARADORES (TRIGGERS) - PIZZERÍA DON PICCOLO
-- ============================================================================

USE pizzeria_don_piccolo;

-- Eliminar triggers existentes para evitar errores de duplicación
DROP TRIGGER IF EXISTS trg_actualizar_stock_ingredientes;
DROP TRIGGER IF EXISTS trg_auditoria_precio_pizza;
DROP TRIGGER IF EXISTS trg_actualizar_repartidor_disponible;
DROP TRIGGER IF EXISTS trg_calcular_total_pedido_insert;
DROP TRIGGER IF EXISTS trg_calcular_total_pedido_update;
DROP TRIGGER IF EXISTS trg_calcular_total_pedido_delete;
DROP TRIGGER IF EXISTS trg_calcular_total_domicilio_insert;
DROP TRIGGER IF EXISTS trg_calcular_total_domicilio_update;
DROP TRIGGER IF EXISTS trg_acumular_puntos;
DROP TRIGGER IF EXISTS trg_alerta_stock_critico;
DROP TRIGGER IF EXISTS trg_validar_stock_antes_pedido;
DROP TRIGGER IF EXISTS trg_envio_gratis_vip;

DELIMITER //

-- ============================================================================
-- 1. TRIGGER: trg_actualizar_stock_ingredientes
-- ============================================================================
-- Descuenta automáticamente del stock de ingredientes la cantidad requerida
-- por la pizza cuando se inserta una línea en el pedido.
-- ============================================================================
CREATE TRIGGER trg_actualizar_stock_ingredientes
AFTER INSERT ON pedido_pizzas
FOR EACH ROW
BEGIN
    -- Actualizar stock restando (cantidad_requerida_ingrediente * cantidad_pizzas_pedidas)
    UPDATE ingredientes i
    JOIN pizza_ingredientes pi ON i.id = pi.ingrediente_id
    SET i.stock = i.stock - (pi.cantidad_requerida * NEW.cantidad)
    WHERE pi.pizza_id = NEW.pizza_id;
END //

-- ============================================================================
-- 2. TRIGGER: trg_auditoria_precio_pizza
-- ============================================================================
-- Registra en la tabla historial_precios cualquier cambio en el precio base de
-- una pizza, guardando el precio anterior, el nuevo, la fecha y el usuario.
-- ============================================================================
CREATE TRIGGER trg_auditoria_precio_pizza
AFTER UPDATE ON pizzas
FOR EACH ROW
BEGIN
    IF OLD.precio_base <> NEW.precio_base THEN
        INSERT INTO historial_precios (pizza_id, precio_anterior, precio_nuevo, usuario)
        VALUES (NEW.id, OLD.precio_base, NEW.precio_base, CURRENT_USER());
    END IF;
END //

-- ============================================================================
-- 3. TRIGGER: trg_actualizar_repartidor_disponible
-- ============================================================================
-- Cambia automáticamente el estado del repartidor asignado a "disponible" cuando
-- se registra la hora de entrega en el domicilio.
-- ============================================================================
CREATE TRIGGER trg_actualizar_repartidor_disponible
AFTER UPDATE ON domicilios
FOR EACH ROW
BEGIN
    -- Verificar que se haya registrado la hora de entrega (antes nula)
    IF NEW.hora_entrega IS NOT NULL AND OLD.hora_entrega IS NULL THEN
        UPDATE repartidores
        SET estado = 'disponible'
        WHERE id = NEW.repartidor_id;
    END IF;
END //

-- ============================================================================
-- 4. TRIGGERS ADICIONALES PARA CALCULAR AUTOMÁTICAMENTE EL TOTAL DEL PEDIDO
-- ============================================================================
-- Mantienen actualizada la columna "total" en la tabla pedidos mediante la
-- función fn_calcular_total_pedido cuando se insertan, actualizan o eliminan
-- pizzas de un pedido, o cuando se agrega/modifica el domicilio.
-- ============================================================================

CREATE TRIGGER trg_calcular_total_pedido_insert
AFTER INSERT ON pedido_pizzas
FOR EACH ROW
BEGIN
    UPDATE pedidos
    SET total = fn_calcular_total_pedido(NEW.pedido_id)
    WHERE id = NEW.pedido_id;
END //

CREATE TRIGGER trg_calcular_total_pedido_update
AFTER UPDATE ON pedido_pizzas
FOR EACH ROW
BEGIN
    UPDATE pedidos
    SET total = fn_calcular_total_pedido(NEW.pedido_id)
    WHERE id = NEW.pedido_id;
END //

CREATE TRIGGER trg_calcular_total_pedido_delete
AFTER DELETE ON pedido_pizzas
FOR EACH ROW
BEGIN
    UPDATE pedidos
    SET total = fn_calcular_total_pedido(OLD.pedido_id)
    WHERE id = OLD.pedido_id;
END //

CREATE TRIGGER trg_calcular_total_domicilio_insert
AFTER INSERT ON domicilios
FOR EACH ROW
BEGIN
    UPDATE pedidos
    SET total = fn_calcular_total_pedido(NEW.pedido_id)
    WHERE id = NEW.pedido_id;
END //

CREATE TRIGGER trg_calcular_total_domicilio_update
AFTER UPDATE ON domicilios
FOR EACH ROW
BEGIN
    UPDATE pedidos
    SET total = fn_calcular_total_pedido(NEW.pedido_id)
    WHERE id = NEW.pedido_id;
END //

-- ============================================================================
-- 5. TRIGGER: trg_acumular_puntos (AFTER UPDATE ON pedidos)
-- ============================================================================
-- Acumula puntos de fidelidad en la ficha del cliente cuando su pedido 
-- es entregado. Acumula 1 punto por cada $10,000 del total.
-- ============================================================================
CREATE TRIGGER trg_acumular_puntos
AFTER UPDATE ON pedidos
FOR EACH ROW
BEGIN
    IF NEW.estado = 'entregado' AND OLD.estado <> 'entregado' THEN
        UPDATE clientes
        SET puntos = puntos + FLOOR(NEW.total / 10000)
        WHERE id = NEW.cliente_id;
    END IF;
END //

-- ============================================================================
-- 6. TRIGGER: trg_alerta_stock_critico (AFTER UPDATE ON ingredientes)
-- ============================================================================
-- Inserta una fila de auditoría en alertas_stock cuando el stock de un 
-- ingrediente cae por debajo del nivel mínimo.
-- ============================================================================
CREATE TRIGGER trg_alerta_stock_critico
AFTER UPDATE ON ingredientes
FOR EACH ROW
BEGIN
    IF NEW.stock < NEW.stock_minimo AND OLD.stock >= OLD.stock_minimo THEN
        INSERT INTO alertas_stock (ingrediente_id, stock_registrado)
        VALUES (NEW.id, NEW.stock);
    END IF;
END //

-- ============================================================================
-- 7. TRIGGER: trg_validar_stock_antes_pedido (BEFORE INSERT ON pedido_pizzas)
-- ============================================================================
-- Valida que haya suficiente stock de todos los ingredientes requeridos 
-- para la pizza antes de permitir su inserción. Si no hay suficiente, 
-- aborta la transacción lanzando un SIGNAL SQLSTATE.
-- ============================================================================
CREATE TRIGGER trg_validar_stock_antes_pedido
BEFORE INSERT ON pedido_pizzas
FOR EACH ROW
BEGIN
    DECLARE v_nombre_ingrediente VARCHAR(50) DEFAULT NULL;
    DECLARE v_stock_disponible INT DEFAULT 0;
    DECLARE v_stock_requerido INT DEFAULT 0;
    DECLARE v_mensaje_error VARCHAR(255);

    -- Buscar si hay algún ingrediente que no alcance en inventario
    SELECT i.nombre, i.stock, (pi.cantidad_requerida * NEW.cantidad)
    INTO v_nombre_ingrediente, v_stock_disponible, v_stock_requerido
    FROM pizza_ingredientes pi
    JOIN ingredientes i ON pi.ingrediente_id = i.id
    WHERE pi.pizza_id = NEW.pizza_id 
      AND i.stock < (pi.cantidad_requerida * NEW.cantidad)
    LIMIT 1;

    -- Si se detecta falta de stock, abortar la transacción
    IF v_nombre_ingrediente IS NOT NULL THEN
        SET v_mensaje_error = CONCAT('ERROR: STOCK INSUFICIENTE PARA ', v_nombre_ingrediente, 
                                     ' REQUERIDO: ', v_stock_requerido, 
                                     ' DISPONIBLE: ', v_stock_disponible);
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = v_mensaje_error;
    END IF;
END //

-- ============================================================================
-- 8. TRIGGER: trg_envio_gratis_vip (BEFORE INSERT ON domicilios)
-- ============================================================================
-- Modifica el costo_envio a $0.00 si el cliente asociado al pedido 
-- ha gastado más de $100,000 en consumos históricos en la pizzería.
-- ============================================================================
CREATE TRIGGER trg_envio_gratis_vip
BEFORE INSERT ON domicilios
FOR EACH ROW
BEGIN
    DECLARE v_total_gastado DECIMAL(10, 2) DEFAULT 0.00;
    DECLARE v_cliente_id INT;

    -- Buscar cliente
    SELECT cliente_id INTO v_cliente_id 
    FROM pedidos 
    WHERE id = NEW.pedido_id;

    -- Calcular consumo histórico
    SELECT COALESCE(SUM(total), 0.00) INTO v_total_gastado
    FROM pedidos
    WHERE cliente_id = v_cliente_id AND estado <> 'cancelado';

    -- Aplicar costo de envío cero si es VIP
    IF v_total_gastado > 100000.00 THEN
        SET NEW.costo_envio = 0.00;
    END IF;
END //

DELIMITER ;
