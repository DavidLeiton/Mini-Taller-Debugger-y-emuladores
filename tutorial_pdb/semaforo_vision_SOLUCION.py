"""
semaforo_vision_SOLUCION.py  —  Versión corregida
==================================================
SPOILER: No abrir antes de intentar el tutorial con pdb.

CORRECCIONES APLICADAS:
    Bug #1: Rangos HSV intercambiados para ROJO y VERDE.
    Bug #2: Lógica de decisión usaba primer-detectado
            en lugar del color dominante (más píxeles).
"""

import cv2
import numpy as np

NOMBRES_ESTADO = {0: "ROJO", 1: "VERDE", 2: "AMARILLO"}

POSICION_ROJO     = (50, 60)
POSICION_VERDE    = (50, 150)
POSICION_AMARILLO = (50, 240)


def crear_imagen_semaforo(foco_activo: int) -> np.ndarray:
    img = np.zeros((300, 100, 3), dtype=np.uint8)
    img[:] = (40, 40, 40)
    cv2.rectangle(img, (10, 10), (90, 290), (70, 70, 70), -1)
    focos = [
        (POSICION_ROJO,     (0,   0,   220)),
        (POSICION_VERDE,    (0,   200,   0)),
        (POSICION_AMARILLO, (0,   210, 210)),
    ]
    for i, (posicion, color) in enumerate(focos):
        if i == foco_activo:
            cv2.circle(img, posicion, 28, color, -1)
            cv2.circle(img, posicion, 30, (200, 200, 200), 1)
        else:
            cv2.circle(img, posicion, 28, (30, 30, 30), -1)
    return img


def detectar_color_activo(imagen: np.ndarray) -> tuple[str, int]:
    hsv = cv2.cvtColor(imagen, cv2.COLOR_BGR2HSV)

    # ── CORRECCIÓN Bug #1: rangos HSV correctos ───────────────
    # Rojo en HSV está cerca de Hue=0 (y también cerca de 180)
    # Verde en HSV está alrededor de Hue=60
    rango_rojo_bajo  = np.array([  0, 100, 100])   # ← CORREGIDO
    rango_rojo_alto  = np.array([ 10, 255, 255])   # ← CORREGIDO

    rango_verde_bajo = np.array([ 35, 100, 100])   # ← CORREGIDO
    rango_verde_alto = np.array([ 85, 255, 255])   # ← CORREGIDO

    rango_amarillo_bajo = np.array([20, 100, 100])
    rango_amarillo_alto = np.array([35, 255, 255])

    mascara_rojo     = cv2.inRange(hsv, rango_rojo_bajo,     rango_rojo_alto)
    mascara_verde    = cv2.inRange(hsv, rango_verde_bajo,    rango_verde_alto)
    mascara_amarillo = cv2.inRange(hsv, rango_amarillo_bajo, rango_amarillo_alto)

    pixeles_rojo     = cv2.countNonZero(mascara_rojo)
    pixeles_verde    = cv2.countNonZero(mascara_verde)
    pixeles_amarillo = cv2.countNonZero(mascara_amarillo)

    # ── CORRECCIÓN Bug #2: retornar el color DOMINANTE ────────
    conteos = {
        "ROJO":     pixeles_rojo,
        "VERDE":    pixeles_verde,
        "AMARILLO": pixeles_amarillo,
    }

    color_dominante = max(conteos, key=conteos.get)  # ← CORREGIDO

    if conteos[color_dominante] == 0:
        return "DESCONOCIDO", 0

    return color_dominante, conteos[color_dominante]


def main() -> None:
    print("=" * 52)
    print("  SOLUCIÓN CORREGIDA  —  Detector de Semáforo")
    print("=" * 52)
    print()

    resultados_correctos = 0
    for foco_activo in range(3):
        nombre_real = NOMBRES_ESTADO[foco_activo]
        imagen = crear_imagen_semaforo(foco_activo)
        color_detectado, pixeles = detectar_color_activo(imagen)
        correcto = (color_detectado == nombre_real)
        simbolo  = "✓" if correcto else "✗"
        print(f" {simbolo}  Real: {nombre_real:<10} "
              f"Detectado: {color_detectado:<12} "
              f"({pixeles} px)")
        if correcto:
            resultados_correctos += 1

    print()
    print(f"  Resultado: {resultados_correctos}/3 correctas")
    print("=" * 52)


if __name__ == "__main__":
    main()
