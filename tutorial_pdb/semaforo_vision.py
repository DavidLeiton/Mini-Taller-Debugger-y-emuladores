"""
semaforo_vision.py  —  Sistema de visión para detectar semáforos
================================================================
CONTEXTO DEL TUTORIAL:
    Este programa analiza imágenes de semáforos y detecta qué
    luz está activa (roja, verde o amarilla).

    El programa TIENE DOS BUGS intencionados.
    Usa pdb para encontrarlos y corregirlos.

CÓMO INICIAR EL TUTORIAL:
    1. Ejecutar el programa y observar el error:
           python3 semaforo_vision.py

    2. Activar pdb con breakpoint manual:
           Agrega  breakpoint()  dentro de detectar_color_activo()

    3. Comandos pdb que vas a necesitar:
           l          → listar código alrededor de la línea actual
           n          → ejecutar siguiente línea (sin entrar a funciones)
           s          → entrar dentro de una función llamada
           p <expr>   → imprimir valor de variable o expresión
           c          → continuar hasta el próximo breakpoint
           q          → salir del depurador
================================================================
"""

import cv2
import numpy as np


# ── Constantes del semáforo ───────────────────────────────────
NOMBRES_ESTADO = {0: "ROJO", 1: "VERDE", 2: "AMARILLO"}

# Posiciones de los focos en la imagen sintética
POSICION_ROJO     = (50, 60)
POSICION_VERDE    = (50, 150)
POSICION_AMARILLO = (50, 240)


# ── Creación de imagen sintética ──────────────────────────────

def crear_imagen_semaforo(foco_activo: int) -> np.ndarray:
    """
    Genera una imagen de 100×300 píxeles con un semáforo.
    foco_activo: 0=rojo, 1=verde, 2=amarillo
    """
    img = np.zeros((300, 100, 3), dtype=np.uint8)
    img[:] = (40, 40, 40)   # fondo gris oscuro

    # Carcasa del semáforo
    cv2.rectangle(img, (10, 10), (90, 290), (70, 70, 70), -1)

    # Focos — colores en formato BGR
    focos = [
        (POSICION_ROJO,     (0,   0,   220)),   # rojo
        (POSICION_VERDE,    (0,   200,   0)),   # verde
        (POSICION_AMARILLO, (0,   210, 210)),   # amarillo
    ]

    for i, (posicion, color) in enumerate(focos):
        if i == foco_activo:
            cv2.circle(img, posicion, 28, color, -1)
            cv2.circle(img, posicion, 30, (200, 200, 200), 1)  # borde
        else:
            cv2.circle(img, posicion, 28, (30, 30, 30), -1)    # apagado

    return img


# ── Detección de color ────────────────────────────────────────

def detectar_color_activo(imagen: np.ndarray) -> tuple[str, int]:
    """
    Analiza una imagen BGR y detecta qué foco del semáforo está activo.

    Retorna: (nombre_color, cantidad_pixeles_detectados)

    ⚠️  Esta función contiene DOS BUGS.
         Usa pdb para encontrarlos.
    """

    # Convertir de BGR (OpenCV) a HSV para detección de color robusta
    hsv = cv2.cvtColor(imagen, cv2.COLOR_BGR2HSV)

    # ── BUG #1 ──────────────────────────────────────────────────
    # Los rangos HSV para ROJO y VERDE están INTERCAMBIADOS.
    # En HSV:
    #   Rojo    → Hue ≈   0–10  y  170–180
    #   Verde   → Hue ≈  35–85
    #   Amarillo→ Hue ≈  20–35
    #
    # Pista para el alumno: imprime el valor HSV del píxel central
    # de cada foco con:
    #   (pdb) p hsv[60, 50]    ← centro del foco ROJO
    #   (pdb) p hsv[150, 50]   ← centro del foco VERDE
    # y compara con los rangos declarados abajo.
    # ─────────────────────────────────────────────────────────────

    rango_rojo_bajo  = np.array([ 35, 100, 100])   # BUG: rango de VERDE
    rango_rojo_alto  = np.array([ 85, 255, 255])   # BUG: rango de VERDE

    rango_verde_bajo = np.array([  0, 100, 100])   # BUG: rango de ROJO
    rango_verde_alto = np.array([ 10, 255, 255])   # BUG: rango de ROJO

    rango_amarillo_bajo = np.array([20, 100, 100])  # ← correcto
    rango_amarillo_alto = np.array([35, 255, 255])  # ← correcto

    # Crear máscaras de color
    mascara_rojo     = cv2.inRange(hsv, rango_rojo_bajo,     rango_rojo_alto)
    mascara_verde    = cv2.inRange(hsv, rango_verde_bajo,    rango_verde_alto)
    mascara_amarillo = cv2.inRange(hsv, rango_amarillo_bajo, rango_amarillo_alto)

    # Contar píxeles de cada color detectado
    pixeles_rojo     = cv2.countNonZero(mascara_rojo)
    pixeles_verde    = cv2.countNonZero(mascara_verde)
    pixeles_amarillo = cv2.countNonZero(mascara_amarillo)

    # ── BUG #2 ──────────────────────────────────────────────────
    # La lógica de decisión es incorrecta.
    # Retorna el PRIMER color con algún píxel, no el DOMINANTE.
    # Esto hace que si hay ruido o coincidencia parcial, falle.
    #
    # Corrección esperada: encontrar el color con MÁS píxeles.
    # Pista para el alumno:
    #   (pdb) p pixeles_rojo, pixeles_verde, pixeles_amarillo
    # ─────────────────────────────────────────────────────────────

    if pixeles_rojo > 0:          # BUG: retorna rojo si hay CUALQUIER píxel rojo
        return "ROJO", pixeles_rojo
    elif pixeles_verde > 0:
        return "VERDE", pixeles_verde
    elif pixeles_amarillo > 0:
        return "AMARILLO", pixeles_amarillo
    else:
        return "DESCONOCIDO", 0


# ── Guardar imágenes para inspección visual ───────────────────

def guardar_imagen_debug(imagen: np.ndarray, nombre: str) -> None:
    """Guarda la imagen en disco para inspección (sin display)."""
    ruta = f"/tmp/{nombre}.png"
    cv2.imwrite(ruta, imagen)
    print(f"   [img]  Guardada → {ruta}")


# ── Programa principal ────────────────────────────────────────

def main() -> None:
    print("=" * 52)
    print("  SISTEMA DE VISIÓN  —  Detector de Semáforo")
    print("=" * 52)
    print()

    resultados_correctos = 0
    total_pruebas = 3

    for foco_activo in range(total_pruebas):
        nombre_real = NOMBRES_ESTADO[foco_activo]

        # Generar imagen del semáforo con el foco indicado
        imagen = crear_imagen_semaforo(foco_activo)

        # Guardar imagen para que el alumno pueda inspeccionarla
        guardar_imagen_debug(imagen, f"semaforo_{nombre_real.lower()}")

        # Detectar color (aquí están los bugs)
        color_detectado, pixeles = detectar_color_activo(imagen)

        # Reportar resultado
        correcto = (color_detectado == nombre_real)
        simbolo  = "✓" if correcto else "✗"
        print(f" {simbolo}  Real: {nombre_real:<10} "
              f"Detectado: {color_detectado:<12} "
              f"({pixeles} px)")

        if correcto:
            resultados_correctos += 1

    print()
    print("-" * 52)
    print(f"  Resultado: {resultados_correctos}/{total_pruebas} correctas")

    if resultados_correctos < total_pruebas:
        print()
        print("  ⚠  El sistema tiene errores de detección.")
        print("     Usa pdb para encontrar los bugs:")
        print()
        print("     1. Agrega  breakpoint()  dentro de")
        print("        detectar_color_activo(), antes de")
        print("        la declaración de rangos HSV.")
        print()
        print("     2. Ejecuta:  python3 semaforo_vision.py")
        print()
        print("     3. En pdb prueba:")
        print("          p hsv[60, 50]     ← píxel del foco ROJO")
        print("          p hsv[150, 50]    ← píxel del foco VERDE")
        print("          p pixeles_rojo, pixeles_verde, pixeles_amarillo")
    else:
        print()
        print("  ✔  Todos los colores detectados correctamente.")

    print("=" * 52)


if __name__ == "__main__":
    main()
