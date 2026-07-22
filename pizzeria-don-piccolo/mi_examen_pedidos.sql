-- ============================================================================
-- SCRIPT DE RESOLUCIÓN - MI EXAMEN (MÓDULO DE PEDIDOS) - PIZZERÍA DON PICCOLO 🍕
-- ============================================================================

-- 1. BASE DE DATOS DEL EXAMEN
CREATE DATABASE IF NOT EXISTS examen_pedidos_pizzeria
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE examen_pedidos_pizzeria;

-- Limpieza preventiva
DROP TABLE IF EXISTS detalle_pedidos;
DROP TABLE IF EXISTS pedidos;
DROP TABLE IF EXISTS pizzas;
DROP TABLE IF EXISTS clientes;

-- ============================================================================
-- A. CREACIÓN DE TABLAS (DDL)
-- ============================================================================

-- Tabla Clientes
CREATE TABLE clientes (
    id_cliente INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    telefono VARCHAR(20) NOT NULL,
    direccion VARCHAR(255) NOT NULL
) ENGINE=InnoDB;

-- Tabla Pizzas
CREATE TABLE pizzas (
    id_pizza INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    tamano ENUM('Mediana', 'Familiar', 'Personal') NOT NULL,
    precio_base DECIMAL(10, 2) NOT NULL CHECK (precio_base > 0)
) ENGINE=InnoDB;

-- Tabla Pedidos
CREATE TABLE pedidos (
    id_pedido INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente INT NOT NULL,
    fecha_pedido DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    metodo_pago ENUM('efectivo', 'tarjeta', 'nequi', 'daviplata') NOT NULL,
    estado ENUM('pendiente', 'en preparación', 'entregado', 'cancelado') NOT NULL DEFAULT 'pendiente',
    total DECIMAL(10, 2) NOT NULL DEFAULT 0.00 CHECK (total >= 0),
    CONSTRAINT fk_pedidos_clientes FOREIGN KEY (id_cliente) 
        REFERENCES clientes(id_cliente) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Tabla Detalle Pedidos (Relación muchos a muchos entre Pedidos y Pizzas)
CREATE TABLE detalle_pedidos (
    id_detalle INT AUTO_INCREMENT PRIMARY KEY,
    id_pedido INT NOT NULL,
    id_pizza INT NOT NULL,
    cantidad INT NOT NULL CHECK (cantidad > 0),
    precio_unitario DECIMAL(10, 2) NOT NULL CHECK (precio_unitario >= 0),
    subtotal DECIMAL(10, 2) GENERATED ALWAYS AS (cantidad * precio_unitario) STORED,
    CONSTRAINT fk_detalles_pedidos FOREIGN KEY (id_pedido) 
        REFERENCES pedidos(id_pedido) ON DELETE CASCADE,
    CONSTRAINT fk_detalles_pizzas FOREIGN KEY (id_pizza) 
        REFERENCES pizzas(id_pizza) ON DELETE RESTRICT
) ENGINE=InnoDB;


-- ============================================================================
-- B. INSERCIÓN DE DATOS DE PRUEBA
-- ============================================================================

INSERT INTO clientes (nombre, telefono, direccion) VALUES
('Carlos Mendoza', '3101112222', 'Calle 10 # 4-5'),
('Sofia Alvarez', '3153334444', 'Av 19 # 12-30'),
('Mateo Gomez', '3205556666', 'Carrera 8 # 15-20');

INSERT INTO pizzas (nombre, tamano, precio_base) VALUES
('Margarita', 'Personal', 15000.00),
('Pepperoni', 'Mediana', 22000.00),
('Especial Don Piccolo', 'Familiar', 35000.00);

-- Pedidos iniciales
INSERT INTO pedidos (id_cliente, metodo_pago, estado, total) VALUES
(1, 'efectivo', 'entregado', 37000.00), -- Pedido 1
(2, 'tarjeta', 'pendiente', 22000.00),  -- Pedido 2
(3, 'nequi', 'entregado', 70000.00);    -- Pedido 3

-- Detalles de pedido
INSERT INTO detalle_pedidos (id_pedido, id_pizza, cantidad, precio_unitario) VALUES
(1, 1, 1, 15000.00), -- 1 Margarita en pedido 1
(1, 2, 1, 22000.00), -- 1 Pepperoni en pedido 1 (Total = 37000)
(2, 2, 1, 22000.00), -- 1 Pepperoni en pedido 2
(3, 3, 2, 35000.00); -- 2 Especiales en pedido 3 (Total = 70000)
