# Tutorial: Depuración en Python con `pdb`
## Semáforo con Visión por Computadora (OpenCV)

---

## Objetivo

Aplicar el flujo de depuración estándar usando `pdb` para encontrar y
corregir dos bugs reales en un programa que detecta el color activo de
un semáforo mediante procesamiento de imágenes.

**Conexión con GDB:** Los comandos de `pdb` son casi idénticos a los de GDB.
Al terminar este tutorial, el flujo mental te resultará familiar para ambas herramientas.

---

## ¿Qué es `pdb` y por qué usarlo?

`pdb` (Python DeBugger) es el depurador integrado en Python — viene incluido en
la biblioteca estándar, no requiere instalación. Su propósito es el mismo que GDB
en C/ARM: pausar la ejecución, inspeccionar el estado interno del programa y
avanzar línea a línea para entender exactamente qué está haciendo el código.

`print` sirve para confirmar una hipótesis que ya tienes.
Un depurador sirve cuando **todavía no sabes qué buscar**: puedes pausar el
programa, recorrer el estado completo y formular la hipótesis a partir de lo que
ves, en lugar de adivinar qué variables imprimir.

---

## Tabla de equivalencias GDB ↔ pdb

| Acción                | GDB              | pdb           |
|-----------------------|------------------|---------------|
| Poner breakpoint      | `break <línea>`  | `b <n>`       |
| Breakpoint en código  | —                | `breakpoint()`|
| Siguiente línea       | `next`           | `n`           |
| Entrar en función     | `step`           | `s`           |
| Imprimir variable     | `print <var>`    | `p <expr>`    |
| Continuar ejecución   | `continue`       | `c`           |
| Listar código         | `list`           | `l`           |
| Ver variables locales | `info locals`    | `p locals()`  |
| Salir del depurador   | `quit`           | `q`           |

---

## Paso 1 — Observar el problema

Ejecuta el programa **sin modificarlo**:

```bash
python3 semaforo_vision.py
```

Salida esperada (con los dos bugs):

```
====================================================
  SISTEMA DE VISIÓN  —  Detector de Semáforo
====================================================
   [img]  Guardada → /tmp/semaforo_rojo.png
 ✗  Real: ROJO           Detectado: VERDE        (2453 px)
   [img]  Guardada → /tmp/semaforo_verde.png
 ✗  Real: VERDE          Detectado: ROJO         (2453 px)
   [img]  Guardada → /tmp/semaforo_amarillo.png
 ✓  Real: AMARILLO       Detectado: AMARILLO     (2453 px)
   [img]  Guardada → /tmp/semaforo_verde_ruidoso.png
 ✗  Real: VERDE+ruido    Detectado: ROJO         (2453 px)

  Resultado: 1/4 correctas
```

**Observación inicial:** Rojo y Verde están invertidos (pruebas 1 y 2).
Amarillo funciona. La cuarta prueba, VERDE+ruido, también falla — pero aún
no sabemos por qué; puede ser el mismo bug que las dos primeras o uno
distinto. Lo averiguaremos con `pdb`.

---

## Paso 2 — Agregar un breakpoint con `breakpoint()`

Abre `semaforo_vision.py` y localiza la función `detectar_color_activo`.
Agrega `breakpoint()` justo **antes** de la declaración de los rangos:

```python
# Crear máscaras de color
    mascara_rojo     = cv2.inRange(hsv, rango_rojo_bajo,     rango_rojo_alto)
    mascara_verde    = cv2.inRange(hsv, rango_verde_bajo,    rango_verde_alto)
    mascara_amarillo = cv2.inRange(hsv, rango_amarillo_bajo, rango_amarillo_alto)

    ...
```

---

## Paso 3 — Ejecutar con pdb activo

```bash
python3 semaforo_vision.py
```

El programa procesa cuatro imágenes en secuencia, así que `breakpoint()` se
activará **cuatro veces** — una por imagen. Verás el prompt `(Pdb)`.

---

## Paso 4 — Inspeccionar Bug #1: una imagen a la vez

Cada pausa ocurre mientras se procesa una imagen diferente. En cada pausa,
**solo el foco activo de esa imagen está encendido**; los otros dos focos
están apagados y sus píxeles son oscuros.

La estrategia: en cada pausa, inspecciona el píxel del **foco activo** y
compáralo con los rangos declarados en el código.

> **Nota:** los bloques de código muestran el prompt `(Pdb)` como referencia
> visual, pero **no lo escribas** — solo escribe el comando que sigue.
> Si escribes `(Pdb) p hsv[60, 50]` incluyendo el prefijo, `pdb` responderá
> `SyntaxError`.

### Primera pausa — imagen ROJO activo

El foco rojo está en la fila 60, columna 50. Inspecciónalo:

```
(Pdb) p hsv[60, 50]
array([  0, 255, 220], dtype=uint8)
```

→ **Hue = 0**. Ese es el valor real del color rojo en el espacio HSV.

Ahora lista el código para ver qué rango tiene declarado para "rojo":

```
(Pdb) l
```

Verás entre las líneas listadas:

```python
rango_rojo_bajo  = np.array([ 35, 100, 100])
rango_rojo_alto  = np.array([ 85, 255, 255])
```

**Pregunta:** ¿Hue=0 cae dentro del rango [35, 85]? **No.**
El píxel rojo no será detectado como rojo. Tienes una hipótesis de bug.

Avanza a la siguiente imagen:

```
(Pdb) c
```

### Segunda pausa — imagen VERDE activo

El foco verde está en la fila 150, columna 50:

```
(Pdb) p hsv[150, 50]
array([ 60, 255, 200], dtype=uint8)
```

→ **Hue = 60**. Ese es el valor real del color verde en HSV.

Lista el rango declarado para "verde":

```
(Pdb) l
```

```python
rango_verde_bajo = np.array([  0, 100, 100])
rango_verde_alto = np.array([ 10, 255, 255])
```

**Pregunta:** ¿Hue=60 cae dentro del rango [0, 10]? **No.**

**¡Bug #1 encontrado!** Los rangos HSV de ROJO y VERDE están intercambiados.
El rango etiquetado "rojo" cubre Hue 35–85 (que es verde), y el etiquetado
"verde" cubre Hue 0–10 (que es rojo).

---

## Paso 5 — Confirmar Bug #1 con los conteos de píxeles

Aún en la segunda pausa (imagen VERDE activo), avanza hasta que se calculen
los conteos y luego imprímelos.

Son **6 líneas** antes del `p`: 3 para crear las máscaras + 3 para contarlas.
Una variable no existe hasta que su línea se ejecuta — si intentas imprimirla
antes, `pdb` responde `NameError`.

```
(Pdb) n
(Pdb) n
(Pdb) n
(Pdb) n
(Pdb) n
(Pdb) n
(Pdb) p pixeles_rojo, pixeles_verde, pixeles_amarillo
```

Con la imagen VERDE activa y Bug #1 presente, verás:

```
(2453, 0, 0)
```

El contador "rojo" (cuyo rango cubre verde) reporta 2453 píxeles.
El contador "verde" (cuyo rango cubre rojo) reporta 0. Bug #1 confirmado.

---

## Paso 6 — Salir, corregir Bug #1 y re-ejecutar

Sal del depurador:

```
(Pdb) q
```

Aplica solo la corrección de Bug #1 en `semaforo_vision.py`
(intercambia los rangos):

```python
rango_rojo_bajo  = np.array([  0, 100, 100])
rango_rojo_alto  = np.array([ 10, 255, 255])

rango_verde_bajo = np.array([ 35, 100, 100])
rango_verde_alto = np.array([ 85, 255, 255])
```

Ejecuta el programa **sin** `breakpoint()` para ver el estado actual:

```bash
python3 semaforo_vision.py
```

Salida esperada (Bug #1 corregido, Bug #2 todavía presente):

```
 ✓  Real: ROJO           Detectado: ROJO         (2453 px)
 ✓  Real: VERDE          Detectado: VERDE        (2453 px)
 ✓  Real: AMARILLO       Detectado: AMARILLO     (2453 px)
 ✗  Real: VERDE+ruido    Detectado: ROJO         (3 px)

  Resultado: 3/4 correctas
```

Las tres primeras pruebas pasan. La cuarta falla de forma llamativa:
el sistema detecta ROJO con apenas **3 píxeles** en lugar de VERDE con 2453.
Esto no puede ser un problema de rangos — los rangos ya están corregidos.
Algo en la **lógica de decisión** está mal.

---

## Paso 7 — Diagnosticar Bug #2 con pdb

Vuelve a agregar `breakpoint()` (si lo quitaste) y ejecuta:

```bash
python3 semaforo_vision.py
```

Avanza por las tres primeras pausas con `c` hasta llegar a la cuarta
(imagen VERDE+ruido):

```
(Pdb) c    ← pausa 1: ROJO, funciona bien
(Pdb) c    ← pausa 2: VERDE, funciona bien
(Pdb) c    ← pausa 3: AMARILLO, funciona bien
            ← ahora estás en la pausa 4: VERDE+ruido
```

Avanza hasta los conteos y examínalos (igual que antes: 6 `n` para pasar
las 3 máscaras y los 3 conteos):

```
(Pdb) n
(Pdb) n
(Pdb) n
(Pdb) n
(Pdb) n
(Pdb) n
(Pdb) p pixeles_rojo, pixeles_verde, pixeles_amarillo
```

Resultado:

```
(3, 2453, 0)
```

Solo **3 píxeles** de ruido rojo contra **2453 píxeles** de verde correcto.
Ahora lista la lógica de decisión:

```
(Pdb) l
```

Verás:

```python
if pixeles_rojo > 0:          # ← retorna ROJO con tan solo 3 píxeles
    return "ROJO", pixeles_rojo
elif pixeles_verde > 0:
    return "VERDE", pixeles_verde
```

**¡Bug #2 encontrado!** La condición retorna el **primer** color con cualquier
cantidad de píxeles, en lugar del color **dominante**. Tres píxeles de ruido
de fondo son suficientes para enmascarar 2453 píxeles de señal correcta.

---

## Paso 8 — Salir y corregir Bug #2

```
(Pdb) q
```

Corrige la lógica de decisión en `semaforo_vision.py`:

```python
conteos = {
    "ROJO":     pixeles_rojo,
    "VERDE":    pixeles_verde,
    "AMARILLO": pixeles_amarillo,
}
color_dominante = max(conteos, key=conteos.get)
if conteos[color_dominante] == 0:
    return "DESCONOCIDO", 0
return color_dominante, conteos[color_dominante]
```

---

## Paso 9 — Verificar la solución completa

Quita el `breakpoint()` y ejecuta:

```bash
python3 semaforo_vision.py
```

Salida esperada:

```
====================================================
  SISTEMA DE VISIÓN  —  Detector de Semáforo
====================================================
 ✓  Real: ROJO           Detectado: ROJO         (2453 px)
 ✓  Real: VERDE          Detectado: VERDE        (2453 px)
 ✓  Real: AMARILLO       Detectado: AMARILLO     (2453 px)
 ✓  Real: VERDE+ruido    Detectado: VERDE        (2453 px)

  Resultado: 4/4 correctas
====================================================
```

Si tu solución coincide con `semaforo_vision_SOLUCION.py`, ¡completaste el tutorial! ✓

---

## Resumen del flujo de depuración

```
Observar el fallo
      ↓
Agregar breakpoint()  ←→  GDB: break <función>
      ↓
Inspeccionar variables con p  ←→  GDB: print <var>
      ↓
Avanzar con n / c  ←→  GDB: next / continue
      ↓
Formular hipótesis del bug
      ↓
Corregir, re-ejecutar y validar
      ↓ (si aún falla)
Repetir desde "inspeccionar"
```

**La herramienta cambia. El razonamiento no.**