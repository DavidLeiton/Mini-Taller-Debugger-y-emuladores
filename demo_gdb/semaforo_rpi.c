/*
 * semaforo_rpi.c  —  Simulador de semáforo para Raspberry Pi OS
 *
 * Compilar con:
 *   arm-linux-gnueabihf-gcc -static -no-pie -O0 -g -o semaforo_rpi semaforo_rpi.c
 *
 * Uso en clase (demo GDB):
 *   Terminal 1 (dentro de QEMU): gdbserver :2345 ./semaforo_rpi
 *   Terminal 2 (host Docker):    gdb-multiarch semaforo_rpi
 *                                  (gdb) target remote localhost:2345
 *                                  (gdb) break main
 *                                  (gdb) continue
 */

#include <stdio.h>
#include <unistd.h>
#include <string.h>

/* ── Tipos ─────────────────────────────────────────────────────────────────── */
typedef enum {
    ROJO     = 0,
    AMARILLO = 1,
    VERDE    = 2
} EstadoSemaforo;

/* ── Tablas de configuración ───────────────────────────────────────────────── */
const char* nombre_estado[3] = { "ROJO", "AMARILLO", "VERDE" };
const int   duracion_seg[3]  = {  5,      2,          4 };

/* ── Variables globales (visibles fácilmente desde GDB) ─────────────────────
 *   (gdb) print estado_actual
 *   (gdb) print ciclos_completados
 *   (gdb) set variable ciclos_completados = 2
 */
EstadoSemaforo estado_actual      = ROJO;
int            ciclos_completados = 0;
int            tiempo_en_estado   = 0;

/* ── Funciones ──────────────────────────────────────────────────────────────── */
void imprimir_estado(void)
{
    printf("[Ciclo %d]  %-8s  |  duracion: %d s  |  tiempo: %d s\n",
           ciclos_completados,
           nombre_estado[estado_actual],
           duracion_seg[estado_actual],
           tiempo_en_estado);
    fflush(stdout);
}

void cambiar_estado(void)
{
    estado_actual    = (EstadoSemaforo)((estado_actual + 1) % 3);
    tiempo_en_estado = 0;

    if (estado_actual == ROJO)
        ciclos_completados++;
}

void ejecutar_ciclo(void)
{
    imprimir_estado();
    sleep(1);                   /* ← buen lugar para breakpoints */
    tiempo_en_estado++;

    if (tiempo_en_estado >= duracion_seg[estado_actual])
        cambiar_estado();
}

/* ── main ───────────────────────────────────────────────────────────────────── */
int main(void)
{
    printf("==========================================\n");
    printf("  Semaforo ARMv6  —  Raspberry Pi OS\n");
    printf("  PID: %d\n", getpid());
    printf("==========================================\n\n");

    while (ciclos_completados < 3)
        ejecutar_ciclo();

    printf("\nSimulacion finalizada: %d ciclos completados.\n",
           ciclos_completados);
    return 0;
}