-- ============================================================================
-- SCRIPT DE INSERTAR DATOS DE PRUEBA (SEMILLA) - PIZZERÍA DON PICCOLO
-- ============================================================================

USE pizzeria_don_piccolo;

-- Desactivar llaves foráneas y limpiar tablas de forma segura
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE historial_precios;
TRUNCATE TABLE pagos;
TRUNCATE TABLE domicilios;
TRUNCATE TABLE pedido_pizzas;
TRUNCATE TABLE pedidos;
TRUNCATE TABLE repartidores;
TRUNCATE TABLE pizza_ingredientes;
TRUNCATE TABLE ingredientes;
TRUNCATE TABLE pizzas;
TRUNCATE TABLE clientes;
TRUNCATE TABLE zonas;
SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================================
-- 1. INSERTAR ZONAS
-- ============================================================================
INSERT INTO zonas (nombre_zona, tarifa_envio) VALUES
('Zona Norte', 5000.00),
('Zona Sur', 7000.00),
('Zona Centro', 3000.00),
('Zona Oriente', 6000.00),
('Zona Occidente', 6500.00);

-- ============================================================================
-- 2. INSERTAR CLIENTES
-- ============================================================================
INSERT INTO clientes (nombre, telefono, direccion, correo_electronico) VALUES
('Juan Pérez', '3001234567', 'Calle 100 #15-20', 'juan.perez@email.com'),
('María Rodriguez', '3109876543', 'Carrera 7 #45-10', 'maria.rod@email.com'),
('Carlos Mendoza', '3154567890', 'Avenida Pepe Sierra #12-30', 'carlos.men@email.com'),
('Ana Gomez', '3203456789', 'Diagonal 45 #30-40', 'ana.gomez@email.com'),
('Luis Martinez', '3015556677', 'Calle 80 #60-15', 'luis.mart@email.com'),
('Elena Rios', '3114442233', 'Carrera 15 #110-50', 'elena.rios@email.com'),
('Pedro Garcia', '3187778899', 'Calle 26 #33-10', 'pedro.garcia@email.com');

-- ============================================================================
-- 3. INSERTAR INGREDIENTES
-- ============================================================================
INSERT INTO ingredientes (nombre, stock, stock_minimo, costo) VALUES
('Masa de Pizza', 100, 10, 1500.00),
('Salsa de Tomate', 150, 15, 800.00),
('Queso Mozzarella', 120, 20, 2500.00),
('Pepperoni', 80, 15, 3000.00),
('Jamón', 90, 15, 2000.00),
('Piña', 60, 10, 1200.00),
('Champiñones', 70, 12, 1800.00),
('Pimentón', 45, 10, 1000.00),
('Cebolla', 50, 10, 700.00),
('Albahaca', 8, 10, 600.00), -- STOCK POR DEBAJO DEL MÍNIMO (Para probar vistas)
('Aceitunas Negras', 5, 10, 1500.00); -- STOCK POR DEBAJO DEL MÍNIMO (Para probar vistas)

-- ============================================================================
-- 4. INSERTAR PIZZAS
-- ============================================================================
INSERT INTO pizzas (nombre, tamano, precio_base, tipo) VALUES
('Margarita', 'Personal', 18000.00, 'vegetariana'),
('Margarita', 'Mediana', 28000.00, 'vegetariana'),
('Margarita', 'Familiar', 38000.00, 'vegetariana'),
('Pepperoni', 'Personal', 22000.00, 'clásica'),
('Pepperoni', 'Mediana', 32000.00, 'clásica'),
('Pepperoni', 'Familiar', 42000.00, 'clásica'),
('Piccolo Especial', 'Personal', 25000.00, 'especial'),
('Piccolo Especial', 'Mediana', 36000.00, 'especial'),
('Piccolo Especial', 'Familiar', 48000.00, 'especial'),
('Hawaiana', 'Personal', 20000.00, 'clásica'),
('Hawaiana', 'Mediana', 30000.00, 'clásica'),
('Vegetariana Suprema', 'Mediana', 31000.00, 'vegetariana');

-- ============================================================================
-- 5. ASOCIAR INGREDIENTES A LAS PIZZAS
-- ============================================================================
INSERT INTO pizza_ingredientes (pizza_id, ingrediente_id, cantidad_requerida) VALUES
-- Margarita Personal (Masa, Salsa, Queso, Albahaca)
(1, 1, 1), (1, 2, 1), (1, 3, 1), (1, 10, 1),
-- Margarita Mediana
(2, 1, 2), (2, 2, 2), (2, 3, 2), (2, 10, 2),
-- Pepperoni Personal (Masa, Salsa, Queso, Pepperoni)
(4, 1, 1), (4, 2, 1), (4, 3, 1), (4, 4, 1),
-- Pepperoni Mediana
(5, 1, 2), (5, 2, 2), (5, 3, 2), (5, 4, 2),
-- Piccolo Especial Personal (Masa, Salsa, Queso, Pepperoni, Jamón, Champiñones)
(7, 1, 1), (7, 2, 1), (7, 3, 1), (7, 4, 1), (7, 5, 1), (7, 7, 1),
-- Hawaiana Personal (Masa, Salsa, Queso, Jamón, Piña)
(10, 1, 1), (10, 2, 1), (10, 3, 1), (10, 5, 1), (10, 6, 1);

-- ============================================================================
-- 6. INSERTAR REPARTIDORES
-- ============================================================================
INSERT INTO repartidores (nombre, zona_id, estado) VALUES
('Carlos Ruiz', 1, 'disponible'), -- Zona Norte
('Diego Rojas', 2, 'disponible'), -- Zona Sur
('Mauricio Diaz', 3, 'disponible'), -- Zona Centro
('Andres Prada', 4, 'no disponible'); -- Zona Oriente

-- ============================================================================
-- 7. CREAR PEDIDOS (El total será recalculado por los triggers)
-- ============================================================================

-- Pedido 1: Juan Pérez (Norte) - Domicilio - Entregado el 2026-07-02
INSERT INTO pedidos (id, cliente_id, fecha_hora, estado, modalidad)
VALUES (1, 1, '2026-07-02 12:30:00', 'pendiente', 'domicilio');

-- Pedido 2: María Rodriguez (Sur) - Domicilio - Entregado el 2026-07-03
INSERT INTO pedidos (id, cliente_id, fecha_hora, estado, modalidad)
VALUES (2, 2, '2026-07-03 19:15:00', 'pendiente', 'domicilio');

-- Pedido 3: Carlos Mendoza - Recoge en Tienda - Entregado el 2026-07-05
INSERT INTO pedidos (id, cliente_id, fecha_hora, estado, modalidad)
VALUES (3, 3, '2026-07-05 14:00:00', 'pendiente', 'recoge_tienda');

-- Pedido 4: Juan Pérez - Domicilio - Pendiente
INSERT INTO pedidos (id, cliente_id, fecha_hora, estado, modalidad)
VALUES (4, 1, '2026-07-08 20:30:00', 'pendiente', 'domicilio');

-- Pedido 5: Juan Pérez - Domicilio - Cancelado
INSERT INTO pedidos (id, cliente_id, fecha_hora, estado, modalidad)
VALUES (5, 1, '2026-07-09 13:00:00', 'cancelado', 'domicilio');

-- Adicionales de Juan Pérez (Para probar consulta de cliente frecuente > 5 pedidos en Julio 2026)
-- Pedido 6
INSERT INTO pedidos (id, cliente_id, fecha_hora, estado, modalidad)
VALUES (6, 1, '2026-07-10 11:00:00', 'pendiente', 'recoge_tienda');
-- Pedido 7
INSERT INTO pedidos (id, cliente_id, fecha_hora, estado, modalidad)
VALUES (7, 1, '2026-07-11 18:00:00', 'pendiente', 'recoge_tienda');
-- Pedido 8
INSERT INTO pedidos (id, cliente_id, fecha_hora, estado, modalidad)
VALUES (8, 1, '2026-07-12 19:00:00', 'pendiente', 'recoge_tienda');
-- Pedido 9
INSERT INTO pedidos (id, cliente_id, fecha_hora, estado, modalidad)
VALUES (9, 1, '2026-07-14 20:00:00', 'pendiente', 'recoge_tienda');

-- ============================================================================
-- 8. DETALLE DE PIZZAS POR PEDIDO
-- ============================================================================
-- Al insertar, se activará el trigger trg_actualizar_stock_ingredientes y
-- trg_calcular_total_pedido_insert.
-- ============================================================================
INSERT INTO pedido_pizzas (pedido_id, pizza_id, cantidad, precio_unitario) VALUES
-- Pedido 1: 1 Pepperoni Mediana, 1 Margarita Personal
(1, 5, 1, 32000.00), 
(1, 1, 1, 18000.00),
-- Pedido 2: 2 Piccolo Especial Personal
(2, 7, 2, 25000.00),
-- Pedido 3: 1 Hawaiana Personal
(3, 10, 1, 20000.00),
-- Pedido 4: 1 Pepperoni Personal, 1 Margarita Personal
(4, 4, 1, 22000.00), 
(4, 1, 1, 18000.00),
-- Pedido 5: 1 Hawaiana Personal (Cancelado, se resta stock al insertar pero no cuenta para ganancias)
(5, 10, 1, 20000.00),
-- Pedidos 6 al 9 de Juan Pérez (Recoge tienda)
(6, 1, 1, 18000.00),
(7, 1, 1, 18000.00),
(8, 1, 1, 18000.00),
(9, 1, 1, 18000.00);

-- ============================================================================
-- 9. REGISTRO DE DOMICILIOS (Para los pedidos con modalidad = 'domicilio')
-- ============================================================================
-- Al insertar se recalculará el total del pedido incluyendo el costo de envío.
-- ============================================================================
INSERT INTO domicilios (pedido_id, repartidor_id, hora_salida, hora_entrega, distancia_km, costo_envio) VALUES
-- Domicilio 1 (Pedido 1): Carlos Ruiz, ya entregado
(1, 1, '2026-07-02 12:45:00', '2026-07-02 13:10:00', 3.5, 5000.00),
-- Domicilio 2 (Pedido 2): Diego Rojas, ya entregado
(2, 2, '2026-07-03 19:30:00', '2026-07-03 20:05:00', 5.2, 7000.00),
-- Domicilio 4 (Pedido 4): Carlos Ruiz, pendiente de entrega (hora_entrega es NULL)
-- Al crearse, cambia el repartidor a 'no disponible' (esto se puede simular o actualizar manualmente)
(4, 1, '2026-07-08 20:45:00', NULL, 2.1, 5000.00);

-- Actualizar estado de repartidores que están en camino
UPDATE repartidores SET estado = 'no disponible' WHERE id = 1;

-- ============================================================================
-- 10. REGISTRO DE PAGOS (Para simular cobros)
-- ============================================================================
INSERT INTO pagos (pedido_id, monto, metodo, fecha_pago) VALUES
-- Pedido 1: Pagó con Tarjeta el valor total
(1, 64500.00, 'tarjeta', '2026-07-02 13:10:00'), -- (32k+18k) * 1.19 = 59.5k + 5k envio = 64.5k
-- Pedido 2: Pagó con App el valor total
(2, 66500.00, 'app', '2026-07-03 20:05:00'),   -- (50k) * 1.19 = 59.5k + 7k envio = 66.5k
-- Pedido 3: Pagó en Efectivo en tienda
(3, 23800.00, 'efectivo', '2026-07-05 14:10:00'); -- (20k) * 1.19 = 23.8k (sin envio)

-- ============================================================================
-- SIMULACIONES DE FLUJO PARA VALIDACIÓN
-- ============================================================================

-- Simulación 1: Cambiar el estado de los pedidos ya entregados
UPDATE pedidos SET estado = 'entregado' WHERE id IN (1, 2, 3, 6, 7, 8, 9);
