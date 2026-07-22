# 🍕 Guía de Sustentación Técnica - Pizzería Don Piccolo

Esta guía está diseñada para prepararte para las preguntas más difíciles y técnicas que un evaluador te podría hacer durante la sustentación de tu base de datos. Está estructurada en base al código de tu proyecto.

---

## 🎯 1. Decisiones de Diseño Críticas (El "Por Qué")

Un evaluador experimentado no te preguntará qué es una tabla; te preguntará **por qué estructuraste las tablas de esa forma**.

### ❓ ¿Por qué `pedido_pizzas` guarda el `precio_unitario` si ese dato ya está en `pizzas.precio_base`?
* **Respuesta técnica (Histórico de Precios)**: Si no guardamos el `precio_unitario` en la tabla intermedia, estaríamos obligados a calcular el total del pedido consultando directamente `pizzas.precio_base`. Si mañana la pizza Margarita sube de precio de $18,000 a $22,000, **todos los pedidos del mes pasado cambiarían de valor retrospectivamente**, alterando la contabilidad.
* **Concepto clave**: Rompemos la tercera forma normal (3FN) de manera intencional para guardar una "foto" o captura del precio en el momento exacto de la compra.

### ❓ ¿Por qué la tabla `pagos` está separada de `pedidos`? (Relación 1:1)
* **Respuesta técnica (Normalización y Escalabilidad)**: Un pedido tiene un único pago (`pedido_id` es `UNIQUE` en la tabla `pagos`), lo que mantiene la integridad 1:1. Separarlo permite:
  1. No sobrecargar la tabla `pedidos` con campos financieros que solo se llenan al final.
  2. Facilitar que en el futuro un pedido se pueda pagar con múltiples métodos (ej. mitad efectivo, mitad tarjeta), simplemente cambiando la relación a 1:N (quitando el `UNIQUE` de `pedido_id` en `pagos`).

### ❓ ¿Por qué las horas en la tabla `domicilios` (`hora_salida` y `hora_entrega`) aceptan valores nulos (`NULL`)?
* **Respuesta técnica**: Porque representan eventos en tiempo real:
  * `hora_salida` es `NULL` mientras el pedido está "pendiente" o "en preparación".
  * `hora_entrega` es `NULL` mientras el repartidor está en la calle. Esto nos permite calcular la duración del viaje (`TIMESTAMPDIFF` entre salida y entrega) únicamente para los domicilios ya completados.

---

## ⚡ 2. ¿Qué pasa si borro esto? (Integridad Referencial)

Los evaluadores aman preguntar qué pasa si intentas romper la base de datos.

### ❓ ¿Qué pasa si borro un Cliente que ya tiene pedidos registrados?
* **Respuesta**: El sistema arrojará un **error de restricción de llave foránea (FK)**.
* **Explicación técnica**: En la tabla `pedidos` (línea 100 de `database.sql`), definiste:
  ```sql
  CONSTRAINT fk_pedidos_clientes FOREIGN KEY (cliente_id) REFERENCES clientes(id) ON DELETE RESTRICT
  ```
  El uso de `ON DELETE RESTRICT` impide borrar un cliente si tiene historial. Esto protege la contabilidad del negocio (no puedes tener pedidos de un cliente inexistente).

### ❓ ¿Qué pasa si borro un Pedido que tiene pizzas y un domicilio asignado?
* **Respuesta**: Se borrarán automáticamente en cascada las pizzas del pedido en `pedido_pizzas` y su registro de entrega en `domicilios`.
* **Explicación técnica**: En `pedido_pizzas` (línea 112) y `domicilios` (línea 128) definiste:
  ```sql
  ON DELETE CASCADE
  ```
  Esto es correcto porque si el pedido (el padre) desaparece, las líneas del pedido y el domicilio (los hijos) ya no tienen sentido de existir (se convierten en datos huérfanos).

### ❓ ¿Qué pasa si borro una Pizza que está en `pizza_ingredientes` (su receta), pero nadie la ha pedido aún?
* **Respuesta**: Se borrará la pizza y su receta de ingredientes se eliminará automáticamente.
* **Explicación técnica**: En `pizza_ingredientes` (línea 74), definiste `ON DELETE CASCADE` para la pizza. Al borrarla, se borra su asociación con los ingredientes. Sin embargo, en `pedido_pizzas` (línea 115) definiste `ON DELETE RESTRICT` para la pizza. Si esa pizza **ya fue comprada en algún pedido**, el sistema **bloqueará** el borrado.

---

## ⚙️ 3. Explicación de Triggers (Automatización de Procesos)

Aquí demostrarás que tu base de datos tiene "inteligencia propia".

### ❓ ¿Cómo funciona el descuento de stock de ingredientes cuando se crea un pedido?
* **Explicación paso a paso de `trg_actualizar_stock_ingredientes`**:
  1. El disparador se ejecuta **después de insertar** (`AFTER INSERT`) una fila en la tabla intermedia `pedido_pizzas` (cuando agregas una pizza a un pedido).
  2. Hace un `JOIN` entre la receta (`pizza_ingredientes`) y los insumos (`ingredientes`) para saber qué ingredientes usa esa pizza y en qué cantidad (`cantidad_requerida`).
  3. Ejecuta un `UPDATE` restando del stock:
     $$\text{Stock Nuevo} = \text{Stock Anterior} - (\text{Cantidad Requerida} \times \text{Pizzas Pedidas})$$
     *(Usando `NEW.cantidad` y `NEW.pizza_id` que son las variables temporales del registro recién insertado).*

### ❓ ¿Por qué tienes 5 triggers diferentes para actualizar el "total" del pedido?
* **Respuesta**: Porque el total de un pedido depende de **dos factores variables** que pueden cambiar en momentos diferentes:
  1. **Las pizzas del pedido** (`pedido_pizzas`): Puede haber un `INSERT` (agregar pizza), `UPDATE` (cambiar cantidad) o `DELETE` (quitar pizza).
  2. **El envío** (`domicilios`): El pedido se crea inicialmente sin envío (si es para recoger en tienda). Si luego se decide enviar a domicilio, se inserta o modifica un registro en `domicilios` que agrega la tarifa de envío.
* **Explicación técnica**: Para garantizar que el total en la tabla `pedidos` sea **siempre consistente**, debemos interceptar cualquier cambio en estas dos tablas satélites y llamar a la función `fn_calcular_total_pedido`.

### ❓ ¿Qué hace exactamente `trg_actualizar_repartidor_disponible`?
* **Respuesta**: Automatiza la disponibilidad del personal de entrega.
* **Lógica interna**: Detecta cuando el campo `hora_entrega` en la tabla `domicilios` pasa de ser `NULL` a tener una fecha/hora (es decir, el repartidor regresó de entregar la pizza). En ese instante, hace un `UPDATE` en la tabla `repartidores` cambiando su `estado` a `'disponible'` para que pueda recibir otro pedido.

---

## 🧮 4. Funciones y Procedimientos (Lógica de Negocio)

### ❓ ¿Cuál es la diferencia entre una Función y un Procedimiento Almacenado en tu proyecto?
* **Función (`fn_calcular_total_pedido`)**:
  * **Retorna un único valor** (un `DECIMAL`).
  * Puede ser llamada directamente dentro de un `SELECT` o un `SET` (por ejemplo, dentro de tus triggers).
  * Es `DETERMINISTIC` porque para un mismo pedido y estado actual de sus pizzas/envíos siempre devolverá el mismo resultado.
* **Procedimiento (`sp_registrar_entrega_pedido`)**:
  * No retorna un valor directo, sino que **ejecuta una acción o transacción** (hace múltiples `UPDATE` en cascada: cambia la hora de entrega en `domicilios` y el estado del pedido a `'entregado'`).
  * Puede recibir parámetros de entrada (`IN`) y ejecutar control de flujo con condicionales (`IF-ELSE`).
  * Se invoca con la palabra clave `CALL`.

### ❓ En `sp_registrar_entrega_pedido`, ¿qué significa `SIGNAL SQLSTATE '45000'`?
* **Respuesta técnica**: Es la forma en que MySQL **lanza una excepción o error controlado**.
* **Explicación**: Si el administrador intenta registrar la entrega de un pedido que fue configurado como "recoge en tienda" (y por ende no tiene registro en la tabla `domicilios`), la variable `v_existe_domicilio` será `0`. El procedimiento captura esto y cancela la operación lanzando el error personalizado: *'Error: No se encontró un domicilio registrado para este ID de pedido.'*, evitando que la base de datos quede en un estado inconsistente.

---

## 📊 5. Vistas y Consultas de Reportes

### ❓ ¿Qué ventaja tiene usar la vista `vista_desempeno_repartidores` en lugar de hacer la consulta cada vez?
* **Respuesta técnica (Abstracción y Seguridad)**:
  1. **Simplificación**: Oculta la complejidad de los cálculos matemáticos como `TIMESTAMPDIFF` (para calcular minutos de entrega) y las agrupaciones (`GROUP BY`). El programador del frontend solo hace `SELECT * FROM vista_desempeno_repartidores`.
  2. **Seguridad**: Permite darle acceso al departamento de operaciones para que vea el rendimiento de los repartidores sin darles permisos de lectura directa sobre las tablas críticas de `domicilios` o `pedidos`.

### ❓ ¿Se pueden insertar o actualizar datos a través de la vista `vista_desempeno_repartidores`?
* **Respuesta**: **No, es una vista no actualizable**.
* **Explicación técnica**: Las vistas que contienen funciones de agregación (`COUNT`, `AVG`), cláusulas `GROUP BY`, o uniones (`JOIN`) no permiten operaciones de escritura (`INSERT`/`UPDATE`), ya que MySQL no sabría a qué fila física de las tablas base aplicar la modificación.

### ❓ En la Consulta 5, ¿cuál es la diferencia entre el `WHERE` y el `HAVING`?
```sql
SELECT c.nombre, SUM(p.total) AS total_gastado
FROM clientes c
JOIN pedidos p ON c.id = p.cliente_id
WHERE p.estado <> 'cancelado'
GROUP BY c.id
HAVING total_gastado > 150000.00
```
* **Respuesta**:
  * **`WHERE`**: Filtra **filas individuales** antes de agruparlas. Aquí descarta los pedidos cancelados antes de sumar.
  * **`HAVING`**: Filtra **grupos** después de aplicar la función de agregación (`SUM(p.total)`). No puedes usar `WHERE total_gastado > 150000.00` porque `total_gastado` no existe hasta que se realiza la agrupación.

---

## 💡 Consejos para la Sustentación

1. **Usa términos técnicos**: No digas "la tabla que une pizzas con pedidos", di **"la entidad asociativa o tabla intermedia de la relación muchos a muchos"**.
2. **Habla del motor InnoDB**: Si te preguntan por qué usas `ENGINE=InnoDB` en la creación de las tablas, di que es porque **soporta transacciones, llaves foráneas e integridad referencial**, a diferencia del antiguo `MyISAM`.
3. **Muestra el flujo**: Si te piden probar el sistema, propón este flujo lógico:
   > *"Voy a insertar un nuevo pedido para un cliente. Al agregar las pizzas en `pedido_pizzas`, verán cómo el disparador reduce el stock físico de ingredientes en tiempo real y cómo otro disparador calcula automáticamente el total de la factura aplicando el 19% de IVA."*
