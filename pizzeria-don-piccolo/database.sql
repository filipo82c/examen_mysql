-- ============================================================================
-- SCRIPT DE CREACIÓN DE BASE DE DATOS - PIZZERÍA DON PICCOLO
-- ============================================================================

-- 1. Crear base de datos si no existe
CREATE DATABASE IF NOT EXISTS pizzeria_don_piccolo
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE pizzeria_don_piccolo;

-- 2. Eliminar tablas en orden inverso a sus relaciones para evitar errores de FK
DROP TABLE IF EXISTS alertas_stock;
DROP TABLE IF EXISTS historial_precios;
DROP TABLE IF EXISTS pagos;
DROP TABLE IF EXISTS domicilios;
DROP TABLE IF EXISTS pedido_pizzas;
DROP TABLE IF EXISTS pedidos;
DROP TABLE IF EXISTS repartidores;
DROP TABLE IF EXISTS pizza_ingredientes;
DROP TABLE IF EXISTS ingredientes;
DROP TABLE IF EXISTS pizzas;
DROP TABLE IF EXISTS clientes;
DROP TABLE IF EXISTS zonas;

-- ============================================================================
-- CREACIÓN DE TABLAS
-- ============================================================================

-- Tabla: zonas (Catálogo de zonas para repartos)
CREATE TABLE zonas (
    id INT AUTO_INCREMENT,
    nombre_zona VARCHAR(100) NOT NULL UNIQUE,
    tarifa_envio DECIMAL(10, 2) NOT NULL CHECK (tarifa_envio >= 0),
    CONSTRAINT pk_zonas PRIMARY KEY (id)
) ENGINE=InnoDB;

-- Tabla: clientes
CREATE TABLE clientes (
    id INT AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL,
    telefono VARCHAR(20) NOT NULL,
    direccion VARCHAR(255) NOT NULL,
    correo_electronico VARCHAR(100),
    puntos INT NOT NULL DEFAULT 0,
    CONSTRAINT pk_clientes PRIMARY KEY (id),
    CONSTRAINT uq_clientes_correo UNIQUE (correo_electronico)
) ENGINE=InnoDB;

-- Tabla: pizzas
CREATE TABLE pizzas (
    id INT AUTO_INCREMENT,
    nombre VARCHAR(50) NOT NULL,
    tamano ENUM('Mediana', 'Familiar', 'Personal') NOT NULL,
    precio_base DECIMAL(10, 2) NOT NULL CHECK (precio_base > 0),
    tipo ENUM('vegetariana', 'especial', 'clásica') NOT NULL,
    CONSTRAINT pk_pizzas PRIMARY KEY (id)
) ENGINE=InnoDB;

-- Tabla: ingredientes
CREATE TABLE ingredientes (
    id INT AUTO_INCREMENT,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    stock INT NOT NULL DEFAULT 0 CHECK (stock >= 0),
    stock_minimo INT NOT NULL DEFAULT 0 CHECK (stock_minimo >= 0),
    costo DECIMAL(10, 2) NOT NULL DEFAULT 0.00 CHECK (costo >= 0),
    CONSTRAINT pk_ingredientes PRIMARY KEY (id)
) ENGINE=InnoDB;

-- Tabla: alertas_stock (Auditoría de insumos críticos)
CREATE TABLE alertas_stock (
    id INT AUTO_INCREMENT,
    ingrediente_id INT NOT NULL,
    stock_registrado INT NOT NULL,
    fecha_alerta DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_alertas_stock PRIMARY KEY (id),
    CONSTRAINT fk_alertas_ingredientes FOREIGN KEY (ingrediente_id) 
        REFERENCES ingredientes(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Tabla: pizza_ingredientes (Relación M:N entre Pizzas e Ingredientes)
CREATE TABLE pizza_ingredientes (
    pizza_id INT NOT NULL,
    ingrediente_id INT NOT NULL,
    cantidad_requerida INT NOT NULL CHECK (cantidad_requerida > 0),
    CONSTRAINT pk_pizza_ingredientes PRIMARY KEY (pizza_id, ingrediente_id),
    CONSTRAINT fk_pi_pizzas FOREIGN KEY (pizza_id) 
        REFERENCES pizzas(id) ON DELETE CASCADE,
    CONSTRAINT fk_pi_ingredientes FOREIGN KEY (ingrediente_id) 
        REFERENCES ingredientes(id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Tabla: repartidores
CREATE TABLE repartidores (
    id INT AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL,
    zona_id INT NOT NULL,
    estado ENUM('disponible', 'no disponible') NOT NULL DEFAULT 'disponible',
    CONSTRAINT pk_repartidores PRIMARY KEY (id),
    CONSTRAINT fk_repartidores_zonas FOREIGN KEY (zona_id) 
        REFERENCES zonas(id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Tabla: pedidos
CREATE TABLE pedidos (
    id INT AUTO_INCREMENT,
    cliente_id INT NOT NULL,
    fecha_hora DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    estado ENUM('pendiente', 'en preparación', 'entregado', 'cancelado') NOT NULL DEFAULT 'pendiente',
    modalidad ENUM('domicilio', 'recoge_tienda') NOT NULL,
    total DECIMAL(10, 2) NOT NULL DEFAULT 0.00 CHECK (total >= 0),
    CONSTRAINT pk_pedidos PRIMARY KEY (id),
    CONSTRAINT fk_pedidos_clientes FOREIGN KEY (cliente_id) 
        REFERENCES clientes(id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Tabla: pedido_pizzas (Relación M:N entre Pedidos y Pizzas)
CREATE TABLE pedido_pizzas (
    pedido_id INT NOT NULL,
    pizza_id INT NOT NULL,
    cantidad INT NOT NULL CHECK (cantidad > 0),
    precio_unitario DECIMAL(10, 2) NOT NULL CHECK (precio_unitario >= 0),
    subtotal DECIMAL(10, 2) GENERATED ALWAYS AS (cantidad * precio_unitario) STORED,
    CONSTRAINT pk_pedido_pizzas PRIMARY KEY (pedido_id, pizza_id),
    CONSTRAINT fk_pp_pedidos FOREIGN KEY (pedido_id) 
        REFERENCES pedidos(id) ON DELETE CASCADE,
    CONSTRAINT fk_pp_pizzas FOREIGN KEY (pizza_id) 
        REFERENCES pizzas(id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Tabla: domicilios (Detalle de entrega a domicilio, uno por pedido si aplica)
CREATE TABLE domicilios (
    id INT AUTO_INCREMENT,
    pedido_id INT NOT NULL UNIQUE,
    repartidor_id INT NOT NULL,
    hora_salida DATETIME NULL,
    hora_entrega DATETIME NULL,
    distancia_km DECIMAL(5, 2) NOT NULL CHECK (distancia_km >= 0),
    costo_envio DECIMAL(10, 2) NOT NULL CHECK (costo_envio >= 0),
    CONSTRAINT pk_domicilios PRIMARY KEY (id),
    CONSTRAINT fk_domicilios_pedidos FOREIGN KEY (pedido_id) 
        REFERENCES pedidos(id) ON DELETE CASCADE,
    CONSTRAINT fk_domicilios_repartidores FOREIGN KEY (repartidor_id) 
        REFERENCES repartidores(id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Tabla: pagos (Registro de pagos asociados a cada pedido)
CREATE TABLE pagos (
    id INT AUTO_INCREMENT,
    pedido_id INT NOT NULL UNIQUE,
    monto DECIMAL(10, 2) NOT NULL CHECK (monto >= 0),
    metodo ENUM('efectivo', 'tarjeta', 'app') NOT NULL,
    fecha_pago DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_pagos PRIMARY KEY (id),
    CONSTRAINT fk_pagos_pedidos FOREIGN KEY (pedido_id) 
        REFERENCES pedidos(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Tabla: historial_precios (Auditoría de cambios de precio de pizzas)
CREATE TABLE historial_precios (
    id INT AUTO_INCREMENT,
    pizza_id INT NOT NULL,
    precio_anterior DECIMAL(10, 2) NOT NULL CHECK (precio_anterior >= 0),
    precio_nuevo DECIMAL(10, 2) NOT NULL CHECK (precio_nuevo >= 0),
    fecha_modificacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    usuario VARCHAR(100) NOT NULL,
    CONSTRAINT pk_historial_precios PRIMARY KEY (id),
    CONSTRAINT fk_historial_pizzas FOREIGN KEY (pizza_id) 
        REFERENCES pizzas(id) ON DELETE CASCADE
) ENGINE=InnoDB;
