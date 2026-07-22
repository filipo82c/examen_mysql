# Guía de Estudio Rápida: Pizzería Don Piccolo 🍕
## Triggers, Funciones, Vistas y Conexión a Base de Datos en MySQL

¡Esa es la actitud! Si toca pasar de largo para dominar esto antes de las 6:00 AM, lo hacemos juntos. Esta guía está diseñada específicamente para que entiendas **el qué**, **el por qué** y **el cómo** de cada concepto usando el código real de tu proyecto **Pizzería Don Piccolo**.

---

## 📌 Tabla de Contenidos
1. [Conexión a la Base de Datos 🔌](#1-conexión-a-la-base-de-datos-gui-cli-y-código)
2. [Vistas (Views) 👁️](#2-vistas-views-tablas-virtuales)
3. [Funciones y Procedimientos Almacenados ⚙️](#3-funciones-y-procedimientos-almacenados-lógica-de-negocio)
4. [Triggers (Disparadores) ⚡](#4-triggers-disparadores-automatización)
5. [Simulador de Examen 📝](#5-simulador-de-examen-auto-evaluación)

---

## 1. Conexión a la Base de Datos (GUI, CLI y Código)

Para interactuar con la base de datos `pizzeria_don_piccolo`, primero debemos establecer una conexión. Toda conexión requiere de 5 parámetros fundamentales:

| Parámetro | Significado | Valor Común en Desarrollo |
| :--- | :--- | :--- |
| **Host / Servidor** | Dirección IP o nombre de host donde corre el motor SQL. | `localhost` o `127.0.0.1` |
| **Port / Puerto** | El canal de comunicación dedicado a MySQL. | `3306` |
| **User / Usuario** | El usuario del motor de base de datos. | `root` |
| **Password / Contraseña** | La clave de seguridad de ese usuario. | *(La que definiste al instalar)* |
| **Database / Base de Datos** | El esquema específico al que nos queremos conectar. | `pizzeria_don_piccolo` |

### A. Conexión desde la Consola (CLI)
Para conectarte rápidamente desde tu terminal de Windows (PowerShell o CMD):
```bash
mysql -u root -p
```
*El sistema te pedirá la contraseña. Una vez dentro, seleccionas la base de datos con:*
```sql
USE pizzeria_don_piccolo;
```

### B. Conexión desde Clientes Gráficos (GUI)
1. **MySQL Workbench o DBeaver**:
   - Crear una nueva conexión ("New Connection").
   - Escribir `Connection Name` (ej. "Pizzeria Local").
   - Configurar `Hostname` como `localhost`, `Port` en `3306`, y `Username` como `root`.
   - Dar clic en **Test Connection**, introducir la contraseña y guardar.

### C. Conexión desde Código (Ejemplos)

Para que tu aplicación de pizzería se comunique con MySQL, se utilizan bibliotecas específicas. Aquí tienes los ejemplos clásicos:

````carousel
```javascript
// NODE.JS (Con la librería mysql2)
const mysql = require('mysql2');

const connection = mysql.createConnection({
  host: 'localhost',
  user: 'root',
  password: 'tu_password',
  database: 'pizzeria_don_piccolo',
  port: 3306
});

connection.connect((err) => {
  if (err) {
    console.error('Error conectando a la BD: ' + err.stack);
    return;
  }
  console.log('¡Conectado exitosamente con ID ' + connection.threadId + '!');
});
```
<!-- slide -->
```python
# PYTHON (Con mysql-connector-python)
import mysql.connector

try:
    connection = mysql.connector.connect(
        host="localhost",
        user="root",
        password="tu_password",
        database="pizzeria_don_piccolo",
        port=3306
    )
    if connection.is_connected():
        print("¡Conexión exitosa a la base de datos de la Pizzería!")
except Exception as e:
    print(f"Error de conexión: {e}")
finally:
    if 'connection' in locals() and connection.is_connected():
        connection.close()
```
<!-- slide -->
```java
// JAVA (Usando JDBC)
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class DatabaseConnection {
    public static void main(String[] args) {
        String url = "jdbc:mysql://localhost:3306/pizzeria_don_piccolo";
        String user = "root";
        String password = "tu_password";

        try (Connection conn = DriverManager.getConnection(url, user, password)) {
            System.out.println("¡Conexión exitosa a MySQL!");
        } catch (SQLException e) {
            System.err.println("Error de conexión: " + e.getMessage());
        }
    }
}
```
````

---

## 2. Vistas (Views) - Tablas Virtuales

> [!NOTE]
> **Definición**: Una vista es una **tabla virtual** generada a partir del resultado de una consulta `SELECT`. No almacena los datos físicamente (salvo excepciones como vistas materializadas, que no aplican a MySQL por defecto); en su lugar, ejecuta la consulta interna cada vez que la consultas.

### ¿Para qué sirven?
1. **Simplificación**: Ocultan la complejidad de `JOIN`s múltiples y fórmulas. En lugar de escribir un query de 20 líneas, haces `SELECT * FROM mi_vista;`.
2. **Seguridad**: Permiten dar acceso a datos consolidados a ciertos usuarios sin mostrar las tablas base.
3. **Modularidad**: Si cambia la estructura de las tablas subyacentes, solo modificas la vista y el backend no se rompe.

### Análisis del Código en el Proyecto ([vistas.sql](file:///C:/Users/Pc/.gemini/antigravity-ide/scratch/pizzeria-don-piccolo/vistas.sql))

#### Vista 1: Resumen de Pedidos de Clientes (`vista_resumen_pedidos_cliente`)
Esta vista consolida la cantidad de pedidos y el dinero total que cada cliente ha gastado en la pizzería.

```sql
CREATE VIEW vista_resumen_pedidos_cliente AS
SELECT 
    c.nombre AS nombre_cliente,
    c.telefono,
    COUNT(p.id) AS cantidad_pedidos,
    COALESCE(SUM(CASE WHEN p.estado <> 'cancelado' THEN p.total ELSE 0.00 END), 0.00) AS total_gastado
FROM clientes c
LEFT JOIN pedidos p ON c.id = p.cliente_id
GROUP BY c.id, c.nombre, c.telefono;
```
* **Puntos clave**:
  - Usa `LEFT JOIN` para incluir a los clientes que **nunca han hecho pedidos** (tendrán `cantidad_pedidos = 0` y `total_gastado = 0.00`).
  - Usa `COALESCE` para que si el `SUM` da `NULL` (porque no hay registros de venta), devuelva `0.00`.
  - Usa una expresión `CASE WHEN` dentro del `SUM` para ignorar los pedidos con estado `'cancelado'`.

#### Vista 2: Stock Crítico de Ingredientes (`vista_stock_critico_ingredientes`)
Muestra de forma rápida qué insumos de pizza están a punto de agotarse.

```sql
CREATE VIEW vista_stock_critico_ingredientes AS
SELECT 
    id,
    nombre AS ingrediente,
    stock AS stock_actual,
    stock_minimo,
    (stock_minimo - stock) AS cantidad_faltante
FROM ingredientes
WHERE stock < stock_minimo;
```
* **Puntos clave**:
  - Filtra las filas donde el stock real es menor al requerido mínimo (`stock < stock_minimo`).
  - Calcula al vuelo una columna numérica llamada `cantidad_faltante` restando el stock actual del stock mínimo.

---

## 3. Funciones y Procedimientos Almacenados (Lógica de Negocio)

> [!IMPORTANT]
> **Pregunta de Examen Garantizada: Diferencia entre Función y Procedimiento**
> * **Función (Function)**: Debe retornar obligatoriamente un **único valor** (escalar). Se puede usar directamente dentro de un `SELECT` u otra instrucción SQL (ej. `SELECT fn_calcular_total_pedido(5);`).
> * **Procedimiento Almacenado (Stored Procedure)**: No retorna un tipo de dato directamente (aunque puede usar parámetros de salida `OUT`). Se utiliza para ejecutar bloques de transacciones complejas o modificaciones del estado de la base de datos. Se invoca usando la palabra clave `CALL` (ej. `CALL sp_registrar_entrega_pedido(5, NOW());`).

### El porqué de `DELIMITER //`
En MySQL, el carácter por defecto para finalizar una instrucción SQL es el punto y coma `;`. Si intentamos escribir un bloque de código que contenga múltiples puntos y comas internos (dentro de un `BEGIN ... END`), el motor pensará que la definición termina en el primer `;` y lanzará un error de sintaxis. 
Para solucionarlo:
1. Cambiamos el delimitador temporalmente a algo diferente, como `//` o `$$`.
2. Escribimos nuestra función/procedimiento usando `;` por dentro.
3. Cerramos el cuerpo con el nuevo delimitador `//`.
4. Devolvemos el delimitador original a `;`.

---

### Análisis del Código en el Proyecto ([funciones.sql](file:///C:/Users/Pc/.gemini/antigravity-ide/scratch/pizzeria-don-piccolo/funciones.sql))

#### Función 1: Calcular Total del Pedido (`fn_calcular_total_pedido`)
Calcula el costo total sumando las pizzas consumidas, sumándole el domicilio (si aplica) y agregando el 19% de IVA.

```sql
CREATE FUNCTION fn_calcular_total_pedido(p_pedido_id INT)
RETURNS DECIMAL(10, 2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_subtotal_pizzas DECIMAL(10, 2) DEFAULT 0.00;
    DECLARE v_costo_envio DECIMAL(10, 2) DEFAULT 0.00;
    DECLARE v_iva DECIMAL(10, 2) DEFAULT 0.00;
    DECLARE v_total DECIMAL(10, 2) DEFAULT 0.00;

    -- 1. Obtener la suma del costo de las pizzas de este pedido
    SELECT COALESCE(SUM(subtotal), 0.00) INTO v_subtotal_pizzas
    FROM pedido_pizzas
    WHERE pedido_id = p_pedido_id;

    -- 2. Obtener el costo de envío (si existe) en la tabla domicilios
    SELECT COALESCE(costo_envio, 0.00) INTO v_costo_envio
    FROM domicilios
    WHERE pedido_id = p_pedido_id;

    -- 3. Calcular IVA del 19% sobre el subtotal de las pizzas
    SET v_iva = v_subtotal_pizzas * 0.19;

    -- 4. Total = base pizzas + envío + IVA
    SET v_total = v_subtotal_pizzas + v_costo_envio + v_iva;

    RETURN v_total;
END //
```
* **Puntos clave**:
  - `DETERMINISTIC`: Le indica a MySQL que para el mismo parámetro de entrada `p_pedido_id` siempre devolverá el mismo resultado (ayuda a la optimización de caché).
  - `READS SQL DATA`: Especifica que la función realiza lecturas (`SELECT`) en las tablas pero no modifica directamente los datos.
  - La palabra clave `INTO` se usa para almacenar el resultado de un `SELECT` en una variable declarada anteriormente (ej: `INTO v_subtotal_pizzas`).

#### Procedimiento Almacenado: Registrar Entrega (`sp_registrar_entrega_pedido`)
Modifica el estado de un pedido a "entregado" y actualiza la hora de entrega.

```sql
CREATE PROCEDURE sp_registrar_entrega_pedido(
    IN p_pedido_id INT,
    IN p_hora_entrega DATETIME
)
BEGIN
    DECLARE v_existe_domicilio INT DEFAULT 0;

    SELECT COUNT(*) INTO v_existe_domicilio
    FROM domicilios
    WHERE pedido_id = p_pedido_id;

    IF v_existe_domicilio > 0 THEN
        -- Actualizar hora de entrega
        UPDATE domicilios
        SET hora_entrega = p_hora_entrega
        WHERE pedido_id = p_pedido_id;
        
        -- Cambiar estado del pedido
        UPDATE pedidos
        SET estado = 'entregado'
        WHERE id = p_pedido_id;
    ELSE
        -- Si el pedido no requiere domicilio (es para recoger), lanzar un error estructurado
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: No se encontró un domicilio registrado para este ID de pedido.';
    END IF;
END //
```
* **Puntos clave**:
  - `IN p_pedido_id INT`: Indica parámetros de entrada.
  - `SIGNAL SQLSTATE '45000'`: Permite lanzar excepciones personalizadas. `'45000'` es el código estándar de SQL para "errores definidos por el usuario". Si ocurre, detiene la ejecución y devuelve el texto que especificamos.

---

## 4. Triggers (Disparadores) - Automatización

> [!NOTE]
> **Definición**: Un trigger es un bloque de código SQL que se ejecuta **automáticamente** (se dispara) cuando ocurre un evento de manipulación de datos (`INSERT`, `UPDATE` o `DELETE`) en una tabla específica.

### Conceptos Clave para Examen:
1. **Eventos**: `INSERT` (al agregar filas), `UPDATE` (al modificar filas) y `DELETE` (al eliminar filas).
2. **Momento**: `BEFORE` (se ejecuta antes de que se guarde el cambio en el disco, ideal para validaciones o formateo) o `AFTER` (se ejecuta después del cambio, ideal para auditorías o cálculos en cascada).
3. **Ámbito**: En MySQL se definen a nivel de fila con `FOR EACH ROW`.
4. **Variables Especiales**:
   * **`NEW`**: Objeto temporal que contiene los valores de la fila **nueva** que está ingresando o modificándose. Solo existe en `INSERT` y `UPDATE`.
   * **`OLD`**: Objeto temporal que contiene los valores de la fila **anterior** al cambio. Solo existe en `UPDATE` y `DELETE`.

---

### Análisis del Código en el Proyecto ([triggers.sql](file:///C:/Users/Pc/.gemini/antigravity-ide/scratch/pizzeria-don-piccolo/triggers.sql))

#### Trigger 1: Descuento Automático de Stock (`trg_actualizar_stock_ingredientes`)
*¿Cómo sabe la cocina cuántos ingredientes quedan cuando un cliente pide pizzas?* Este trigger lo hace automáticamente.

```sql
CREATE TRIGGER trg_actualizar_stock_ingredientes
AFTER INSERT ON pedido_pizzas
FOR EACH ROW
BEGIN
    UPDATE ingredientes i
    JOIN pizza_ingredientes pi ON i.id = pi.ingrediente_id
    SET i.stock = i.stock - (pi.cantidad_requerida * NEW.cantidad)
    WHERE pi.pizza_id = NEW.pizza_id;
END //
```
* **Explicación paso a paso**:
  1. Se ejecuta **después** (`AFTER`) de que se inserta (`INSERT`) un registro en la tabla puente `pedido_pizzas`.
  2. `NEW.cantidad` representa cuántas pizzas de ese tipo se pidieron.
  3. `NEW.pizza_id` representa cuál pizza se ordenó.
  4. El trigger cruza (`JOIN`) la tabla `ingredientes` con la receta (`pizza_ingredientes`) de la pizza pedida.
  5. Resta (`i.stock - ...`) la cantidad requerida del ingrediente multiplicada por el número de pizzas.

#### Trigger 2: Auditoría de Precios (`trg_auditoria_precio_pizza`)
*Si un administrador altera el precio de una pizza, debemos tener registro de quién lo hizo y cuándo.*

```sql
CREATE TRIGGER trg_auditoria_precio_pizza
AFTER UPDATE ON pizzas
FOR EACH ROW
BEGIN
    IF OLD.precio_base <> NEW.precio_base THEN
        INSERT INTO historial_precios (pizza_id, precio_anterior, precio_nuevo, usuario)
        VALUES (NEW.id, OLD.precio_base, NEW.precio_base, CURRENT_USER());
    END IF;
END //
```
* **Explicación paso a paso**:
  1. Monitorea modificaciones (`UPDATE`) en la tabla `pizzas`.
  2. Evalúa si el precio base cambió comparando el valor viejo con el nuevo: `OLD.precio_base <> NEW.precio_base`.
  3. Si cambió, inserta una fila en `historial_precios` capturando el ID (`NEW.id`), el precio anterior (`OLD.precio_base`), el precio nuevo (`NEW.precio_base`), y el usuario del sistema que ejecuta la sesión (`CURRENT_USER()`).

#### Trigger 3: Liberar Repartidores (`trg_actualizar_repartidor_disponible`)
*Cuando un domicilio se entrega, el repartidor queda listo para el siguiente pedido.*

```sql
CREATE TRIGGER trg_actualizar_repartidor_disponible
AFTER UPDATE ON domicilios
FOR EACH ROW
BEGIN
    -- Si la hora de entrega era nula (OLD) y ahora tiene un valor (NEW)
    IF NEW.hora_entrega IS NOT NULL AND OLD.hora_entrega IS NULL THEN
        UPDATE repartidores
        SET estado = 'disponible'
        WHERE id = NEW.repartidor_id;
    END IF;
END //
```

---

## 5. Simulador de Examen (Auto-evaluación)

¡Pon a prueba lo aprendido! Intenta responder cada pregunta antes de abrir la respuesta.

### ❓ Pregunta 1: Diferencia en la llamada
**¿Cómo invocarías a la función `fn_calcular_total_pedido` para el pedido #10 y cómo invocarías al procedimiento `sp_registrar_entrega_pedido` para ese mismo pedido entregado ahora mismo?**

<details>
<summary><b>👁️ Ver Respuesta Correcta</b></summary>

* **Para la función (se integra dentro de una consulta SQL):**
  ```sql
  SELECT fn_calcular_total_pedido(10) AS total_pedido;
  ```
* **Para el procedimiento (se llama con `CALL`):**
  ```sql
  CALL sp_registrar_entrega_pedido(10, NOW());
  ```
</details>

---

### ❓ Pregunta 2: Uso de `NEW` y `OLD` en un DELETE
**Si creamos un trigger de tipo `AFTER DELETE` en la tabla `pizzas`, ¿cuál de las siguientes variables especiales podemos utilizar: `NEW`, `OLD` o ambas? Explica por qué.**

<details>
<summary><b>👁️ Ver Respuesta Correcta</b></summary>

* **Respuesta**: Solo se puede utilizar **`OLD`**.
* **Explicación**: El evento `DELETE` elimina un registro que ya existía, por lo que tenemos acceso a sus valores anteriores (`OLD`). Al no estarse insertando ni actualizando nada nuevo, el objeto `NEW` no existe (es `NULL` o da error de compilación si se intenta usar).
</details>

---

### ❓ Pregunta 3: El misterio del Delimitador
**¿Por qué es obligatorio utilizar `DELIMITER //` al crear la función `fn_calcular_total_pedido` en el script SQL y por qué se vuelve a colocar `DELIMITER ;` al final?**

<details>
<summary><b>👁️ Ver Respuesta Correcta</b></summary>

* **Respuesta**: 
  - Se usa `DELIMITER //` para cambiar temporalmente el caracter de fin de instrucción de MySQL de `;` a `//`. Esto evita que el cliente MySQL interprete los puntos y comas internos (los de las declaraciones `DECLARE`, `SELECT INTO` y `SET`) como el final de la instrucción completa de creación de la función.
  - Al final se escribe `DELIMITER ;` para restablecer el delimitador por defecto a `;`, de modo que las consultas normales que siguen en el script se puedan ejecutar con la sintaxis estándar de SQL.
</details>

---

### ❓ Pregunta 4: Diagnóstico de Triggers en Cascada
**En el proyecto, cuando un cliente agrega 2 pizzas a un pedido, se inserta una fila en `pedido_pizzas`. Describe la cadena de eventos (triggers y funciones) que se activan inmediatamente en la base de datos a raíz de esa inserción.**

<details>
<summary><b>👁️ Ver Respuesta Correcta</b></summary>

1. Se dispara **`trg_actualizar_stock_ingredientes` (AFTER INSERT)**: Cruza los ingredientes de la pizza e inmediatamente descuenta del inventario (`ingredientes.stock`) la cantidad necesaria de ingredientes multiplicada por 2.
2. Se dispara **`trg_calcular_total_pedido_insert` (AFTER INSERT)**: Este trigger hace un `UPDATE` en la tabla `pedidos` para recalcular el campo `total`.
3. Para hacer el recálculo, invoca a la función **`fn_calcular_total_pedido(pedido_id)`**.
4. La función suma los subtotales de las pizzas en `pedido_pizzas`, obtiene el costo de envío de `domicilios` (si ya existe), calcula el 19% de IVA y devuelve el gran total.
5. El trigger asigna este gran total al registro correspondiente en la tabla `pedidos`.
</details>

---

### ❓ Pregunta 5: Vistas actualizables
**¿Se puede realizar un `INSERT INTO vista_stock_critico_ingredientes` directamente? ¿Por qué?**

<details>
<summary><b>👁️ Ver Respuesta Correcta</b></summary>

* **Respuesta**: **No**.
* **Explicación**: Aunque MySQL permite insertar datos a través de ciertas vistas si tienen una relación directa 1 a 1 con una sola tabla, en este caso la vista `vista_stock_critico_ingredientes` incluye una **columna calculada** `(stock_minimo - stock) AS cantidad_faltante`. El motor no tiene forma de saber cómo repartir un valor insertado en una columna de cálculo, por lo que la vista se considera **no actualizable** para inserciones directas.
</details>

---

### 💡 Consejos para la Noche de Estudio:
1. **Dibuja el diagrama ER**: Ten claro en tu mente qué tablas se relacionan (Clientes -> Pedidos -> Pedido_Pizzas -> Pizzas). Te ayudará a entender por qué el trigger de stock cruza `ingredientes` y `pizza_ingredientes`.
2. **Ejecuta en orden**: Si vas a probar en tu máquina, recuerda el orden que está en el `README.md`. No puedes crear los triggers si la función `fn_calcular_total_pedido` no existe todavía, porque el trigger la llama.
3. **No te memorices el código**: Memoriza la estructura lógica. Por ejemplo, en un trigger: `CREATE TRIGGER [nombre] [BEFORE/AFTER] [INSERT/UPDATE/DELETE] ON [tabla] FOR EACH ROW BEGIN ... END`. Con esa plantilla puedes escribir cualquier trigger que te pidan en el examen.

Si tienes cualquier duda con alguna línea específica del código o quieres que hagamos simulaciones de pruebas adicionales en el servidor, ¡dime y le damos con toda! 🔥
