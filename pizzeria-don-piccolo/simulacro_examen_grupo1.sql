-- ============================================================================
-- SCRIPT DE RESOLUCIÓN - SIMULACRO EXAMEN 1 - PIZZERÍA DON PICCOLO 🍕
-- ============================================================================
-- Este script contiene las soluciones detalladas a todos los requerimientos 
-- solicitados en el Examen del Grupo 1. Puedes utilizarlo como referencia 
-- directa para estudiar las estructuras y lógica que te pedirán mañana.
-- ============================================================================

-- 1. CREACIÓN DE LA BASE DE DATOS DE PRUEBA
-- Creamos una base de datos limpia para simular el examen.
CREATE DATABASE IF NOT EXISTS simulacro_pizzeria_grupo1
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE simulacro_pizzeria_grupo1;

-- Limpieza preventiva de tablas por si ya existen
DROP TABLE IF EXISTS domicilios;
DROP TABLE IF EXISTS repartidores;
DROP TABLE IF EXISTS pedidos;

-- ============================================================================
-- REQUERIMIENTO 1: CREACIÓN DE TABLAS
-- ============================================================================

-- Tabla base necesaria para las llaves foráneas (Mock de Pedidos)
-- NOTA: Aunque no la pide explícitamente el examen, es indispensable crearla
-- primero con el campo "id_pedido" para poder enlazar la FK de domicilios.
CREATE TABLE pedidos (
    id_pedido INT AUTO_INCREMENT,
    cliente_id INT NOT NULL,
    fecha_hora DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    total DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    CONSTRAINT pk_pedidos PRIMARY KEY (id_pedido)
) ENGINE=InnoDB;

-- Crear la tabla: repartidores
-- Campos: id_repartidor (PK, autoincremental), nombre, telefono, zona_asignada, estado
CREATE TABLE repartidores (
    id_repartidor INT AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL,
    telefono VARCHAR(20) NOT NULL,
    zona_asignada VARCHAR(100) NOT NULL,
    estado ENUM('activo', 'inactivo') NOT NULL DEFAULT 'activo',
    CONSTRAINT pk_repartidores PRIMARY KEY (id_repartidor)
) ENGINE=InnoDB;

-- Crear la tabla: domicilios
-- Campos: id_domicilio (PK), id_pedido (FK), id_repartidor (FK), hora_salida, hora_entrega, estado
CREATE TABLE domicilios (
    id_domicilio INT AUTO_INCREMENT,
    id_pedido INT NOT NULL UNIQUE, -- Relación 1:1 (un domicilio pertenece a un único pedido)
    id_repartidor INT NOT NULL,
    hora_salida DATETIME NOT NULL,
    hora_entrega DATETIME NULL, -- Puede ser NULL si el repartidor aún no regresa
    estado ENUM('en_ruta', 'entregado', 'cancelado') NOT NULL DEFAULT 'en_ruta',
    CONSTRAINT pk_domicilios PRIMARY KEY (id_domicilio),
    CONSTRAINT fk_domicilios_pedidos FOREIGN KEY (id_pedido) 
        REFERENCES pedidos(id_pedido) ON DELETE CASCADE,
    CONSTRAINT fk_domicilios_repartidores FOREIGN KEY (id_repartidor) 
        REFERENCES repartidores(id_repartidor) ON DELETE RESTRICT
) ENGINE=InnoDB;


-- ============================================================================
-- INSERTAR DATOS DE PRUEBA (Para validar las consultas)
-- ============================================================================

-- Insertar Pedidos
INSERT INTO pedidos (cliente_id, total) VALUES 
(1, 45000.00), -- Pedido 1
(2, 62000.00), -- Pedido 2
(3, 28000.00), -- Pedido 3
(1, 35000.00), -- Pedido 4
(4, 50000.00); -- Pedido 5

-- Insertar Repartidores
INSERT INTO repartidores (nombre, telefono, zona_asignada, estado) VALUES
('Juan Pérez', '3001234567', 'Zona Norte', 'activo'),      -- Con entregas normales
('Maria Gómez', '3109876543', 'Zona Sur', 'activo'),       -- Con entregas y una demora
('Carlos Ruiz', '3205554433', 'Zona Centro', 'activo'),    -- Repartidor activo SIN entregas
('Ana López', '3151112222', 'Zona Occidente', 'inactivo'); -- Inactivo sin entregas

-- Insertar Domicilios (Casos de prueba)
INSERT INTO domicilios (id_pedido, id_repartidor, hora_salida, hora_entrega, estado) VALUES
-- Juan Pérez (Entregas a tiempo)
(1, 1, '2026-07-22 19:00:00', '2026-07-22 19:25:00', 'entregado'), -- 25 mins

-- María Gómez (Una a tiempo, una demorada > 40 minutos)
(2, 2, '2026-07-22 19:00:00', '2026-07-22 19:15:00', 'entregado'), -- 15 mins
(3, 2, '2026-07-22 19:30:00', '2026-07-22 20:15:00', 'entregado'), -- 45 mins (Demorado!)

-- Juan Pérez (Pedido cancelado)
(4, 1, '2026-07-22 19:40:00', NULL, 'cancelado');


-- ============================================================================
-- REQUERIMIENTO 2: CONSULTA DE ENTREGAS REALIZADAS POR REPARTIDOR
-- ============================================================================
-- Objetivo: Mostrar nombre, cantidad de entregas ('entregado') y el total acumulado monetario de esos pedidos.
-- Explicación: Usamos LEFT JOIN para no excluir a repartidores que no tengan entregas. 
-- Filtramos por d.estado = 'entregado' dentro del JOIN para contar solo los exitosos.
SELECT 
    r.nombre AS nombre_repartidor,
    COUNT(d.id_domicilio) AS entregas_realizadas,
    COALESCE(SUM(p.total), 0.00) AS total_acumulado_pedidos
FROM repartidores r
LEFT JOIN domicilios d ON r.id_repartidor = d.id_repartidor AND d.estado = 'entregado'
LEFT JOIN pedidos p ON d.id_pedido = p.id_pedido
GROUP BY r.id_repartidor, r.nombre
ORDER BY entregas_realizadas DESC;


-- ============================================================================
-- REQUERIMIENTO 3: CONSULTA DE PEDIDOS DEMORADOS (> 40 MINUTOS)
-- ============================================================================
-- Objetivo: Mostrar los pedidos cuya entrega tomó más de 40 minutos reales.
-- Explicación: TIMESTAMPDIFF calcula la diferencia entre hora_salida y hora_entrega en MINUTOS.
SELECT 
    d.id_pedido,
    r.nombre AS repartidor,
    d.hora_salida,
    d.hora_entrega,
    TIMESTAMPDIFF(MINUTE, d.hora_salida, d.hora_entrega) AS minutos_transcurridos
FROM domicilios d
JOIN repartidores r ON d.id_repartidor = r.id_repartidor
WHERE d.estado = 'entregado' 
  AND TIMESTAMPDIFF(MINUTE, d.hora_salida, d.hora_entrega) > 40;


-- ============================================================================
-- REQUERIMIENTO 4: REPARTIDORES ACTIVOS SIN ENTREGAS ASIGNADAS
-- ============================================================================
-- Objetivo: Mostrar repartidores con estado 'activo' que no tienen ningún domicilio.
-- Explicación: El LEFT JOIN trae todos los repartidores. La cláusula d.id_domicilio IS NULL 
-- filtra solo aquellos que no tienen coincidencias en la tabla domicilios (nunca se les asignó nada).
SELECT 
    r.id_repartidor,
    r.nombre AS nombre_repartidor,
    r.estado,
    r.zona_asignada
FROM repartidores r
LEFT JOIN domicilios d ON r.id_repartidor = d.id_repartidor
WHERE r.estado = 'activo' 
  AND d.id_domicilio IS NULL;


-- ============================================================================
-- REQUERIMIENTO 5: VISTA RESUMEN DE DESEMPEÑO
-- ============================================================================
-- Objetivo: Crear una vista que sirva para analizar el rendimiento promedio.
-- Campos: nombre_repartidor, entregas_totales, promedio_minutos_entrega.
CREATE OR REPLACE VIEW vista_desempeno_repartidor AS
SELECT 
    r.nombre AS nombre_repartidor,
    COUNT(d.id_domicilio) AS entregas_totales,
    ROUND(AVG(TIMESTAMPDIFF(MINUTE, d.hora_salida, d.hora_entrega)), 1) AS promedio_minutos_entrega
FROM repartidores r
-- Unimos con domicilios entregados para calcular promedios reales de entrega exitosa
LEFT JOIN domicilios d ON r.id_repartidor = d.id_repartidor AND d.estado = 'entregado'
GROUP BY r.id_repartidor, r.nombre;

-- Consulta para verificar el contenido de la vista creada:
SELECT * FROM vista_desempeno_repartidor;
