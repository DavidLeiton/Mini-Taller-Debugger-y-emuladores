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

## Tabla de equivalencias GDB ↔ pdb

| Acción               | GDB             | pdb         |
|----------------------|-----------------|-------------|
| Poner breakpoint     | `break <línea>` | `break <n>` |
| Siguiente línea      | `next`          | `n`         |
| Entrar en función    | `step`          | `s`         |
| Imprimir variable    | `print <var>`   | `p <expr>`  |
| Continuar ejecución  | `continue`      | `c`         |
| Listar código        | `list`          | `l`         |
| Ver variables locales| `info locals`   | `p locals()`|
| Salir del depurador  | `quit`          | `q`         |

---

## Paso 1 — Observar el problema

Ejecuta el programa **sin modificarlo**:

```bash
python3 semaforo_vision.py
```

Salida esperada (con los bugs):

```
====================================================
  SISTEMA DE VISIÓN  —  Detector de Semáforo
====================================================
   [img]  Guardada → /tmp/semaforo_rojo.png
 ✗  Real: ROJO       Detectado: VERDE         (XX px)
   [img]  Guardada → /tmp/semaforo_verde.png
 ✗  Real: VERDE      Detectado: ROJO          (XX px)
   [img]  Guardada → /tmp/semaforo_amarillo.png
 ✓  Real: AMARILLO   Detectado: AMARILLO      (XX px)
```

**Observación:** Rojo y Verde están invertidos. Amarillo funciona.
Esto sugiere que los **rangos HSV están intercambiados** para esos dos colores.

---

## Paso 2 — Agregar un breakpoint con `breakpoint()`

Abre `semaforo_vision.py` y localiza la función `detectar_color_activo`.
Agrega `breakpoint()` justo **antes** de la declaración de los rangos:

```python
def detectar_color_activo(imagen: np.ndarray) -> tuple[str, int]:
    hsv = cv2.cvtColor(imagen, cv2.COLOR_BGR2HSV)

    breakpoint()   # ← agrega esta línea aquí

    rango_rojo_bajo  = np.array([...])
    ...
```

---

## Paso 3 — Ejecutar con pdb activo

```bash
python3 semaforo_vision.py
```

El programa se detiene en el `breakpoint()`. Verás el prompt `(Pdb)`.

---

## Paso 4 — Inspeccionar los valores HSV reales

El color **rojo** en HSV tiene Hue cercano a **0** (o a 180).
El color **verde** tiene Hue cercano a **60**.

Verifica los píxeles de los focos en la imagen actual:

```python
(Pdb) p hsv[60, 50]       # píxel en el centro del foco ROJO
(Pdb) p hsv[150, 50]      # píxel en el centro del foco VERDE
(Pdb) p hsv[240, 50]      # píxel en el centro del foco AMARILLO
```

Resultado esperado (valores en formato `[H, S, V]`):

```
array([  0, 255, 220], dtype=uint8)   ← foco rojo  → Hue ≈ 0
array([ 60, 255, 200], dtype=uint8)   ← foco verde → Hue ≈ 60
array([ 30, 255, 210], dtype=uint8)   ← foco amarillo → Hue ≈ 30
```

---

## Paso 5 — Comparar con los rangos declarados

Lista el código para ver los rangos:

```python
(Pdb) l
```

Verás:

```python
rango_rojo_bajo  = np.array([ 35, 100, 100])   # ← Hue 35–85 = VERDE, no rojo!
rango_rojo_alto  = np.array([ 85, 255, 255])

rango_verde_bajo = np.array([  0, 100, 100])   # ← Hue 0–10  = ROJO, no verde!
rango_verde_alto = np.array([ 10, 255, 255])
```

**¡Bug #1 encontrado!** Los rangos de rojo y verde están intercambiados.

---

## Paso 6 — Avanzar con `n` para ver los conteos

```python
(Pdb) n     # ejecuta hasta después de crear las máscaras
(Pdb) n
(Pdb) n
(Pdb) n
(Pdb) p pixeles_rojo, pixeles_verde, pixeles_amarillo
```

Con el semáforo en **ROJO** activo, verás algo como:

```
(0, 1963, 0)
```

Cero píxeles "rojos" detectados, y 1963 "verdes". Confirma el Bug #1.

---

## Paso 7 — Continuar e inspeccionar el Bug #2

```python
(Pdb) c     # continua hasta el próximo breakpoint (siguiente llamada)
```

Ahora estás en la llamada con **VERDE** activo. Avanza hasta los conteos:

```python
(Pdb) n   (×4 veces)
(Pdb) p pixeles_rojo, pixeles_verde, pixeles_amarillo
```

Resultado (asumiendo que ya corregiste mentalmente Bug #1):

```
(1820, 0, 0)
```

Ahora lista la lógica de decisión:

```python
(Pdb) l
```

Verás:

```python
if pixeles_rojo > 0:          # ← retorna si hay CUALQUIER píxel rojo
    return "ROJO", pixeles_rojo
```

**¡Bug #2 encontrado!** La condición retorna al primer color con **cualquier**
cantidad de píxeles, en lugar de al color **dominante**.

---

## Paso 8 — Salir y corregir

```python
(Pdb) q
```

Ahora corrige los dos bugs en `semaforo_vision.py`:

**Corrección Bug #1:** Intercambiar los rangos:
```python
rango_rojo_bajo  = np.array([  0, 100, 100])
rango_rojo_alto  = np.array([ 10, 255, 255])

rango_verde_bajo = np.array([ 35, 100, 100])
rango_verde_alto = np.array([ 85, 255, 255])
```

**Corrección Bug #2:** Usar el color dominante:
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

## Paso 9 — Verificar la solución

```bash
python3 semaforo_vision.py
```

Salida esperada:

```
====================================================
  SISTEMA DE VISIÓN  —  Detector de Semáforo
====================================================
 ✓  Real: ROJO       Detectado: ROJO          (XX px)
 ✓  Real: VERDE      Detectado: VERDE         (XX px)
 ✓  Real: AMARILLO   Detectado: AMARILLO      (XX px)

  Resultado: 3/3 correctas
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
Avanzar con n / s  ←→  GDB: next / step
      ↓
Formular hipótesis del bug
      ↓
Corregir y validar
```

**La herramienta cambia. El razonamiento no.**
