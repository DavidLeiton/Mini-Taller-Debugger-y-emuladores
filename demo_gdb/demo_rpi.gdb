# ============================================================
# demo_rpi.gdb  —  Guion GDB para debug con gdbserver en RPi OS
#
# DIFERENCIA clave con el enfoque anterior:
#   Antes: GDB conectaba al gdbstub de QEMU (nivel de máquina)
#   Ahora: GDB conecta a gdbserver corriendo DENTRO de RPi OS
#
# Esto es exactamente como se depura en la industria:
#   el gdbserver corre en el dispositivo embebido real,
#   GDB corre en la laptop del ingeniero.
#
# PRE-REQUISITOS:
#   Terminal 1: ./run_qemu_rpi.sh  (RPi OS corriendo)
#   Dentro de RPi OS: gdbserver :2345 ~/semaforo_rpi
#   Terminal 2: gdb-multiarch -x demo_rpi.gdb semaforo_rpi
# ============================================================

# ── Configuración de arquitectura ────────────────────────────
set architecture arm
set endian little

# ── Conectar al gdbserver dentro de Raspberry Pi OS ──────────
# Puerto 2345 en localhost (port forward de QEMU)
echo \n[GDB] Conectando a gdbserver en Raspberry Pi OS...\n
echo      (gdbserver corre DENTRO del OS en la RPi emulada)\n
target remote localhost:2345

# ── Cargar símbolos del semaforo ─────────────────────────────
echo [GDB] Cargando símbolos de debug de semaforo_rpi...\n
file semaforo_rpi

# ── Breakpoint inicial en main() ─────────────────────────────
break main
echo [GDB] Breakpoint 1 → main()\n

# ── Iniciar la ejecución ──────────────────────────────────────
echo [GDB] Iniciando ejecución del semaforo en RPi OS...\n
continue

# ══════════════════════════════════════════════════════════════
# COMANDOS PARA EJECUTAR MANUALMENTE EN CLASE
# ══════════════════════════════════════════════════════════════

# ── BLOQUE A: Ver el estado inicial ──────────────────────────
#   (gdb) list                        → código fuente actual
#   (gdb) print estado_actual         → ROJO
#   (gdb) print ciclos_completados    → 0
#   (gdb) print tiempo_en_estado      → 0

# ── BLOQUE B: Avanzar paso a paso ────────────────────────────
#   (gdb) next    → ejecuta printf del banner
#   (gdb) next
#   (gdb) next
#   (en Terminal 1 aparece el banner del semáforo en RPi OS)

# ── BLOQUE C: next vs step ───────────────────────────────────
#   (gdb) break imprimir_estado
#   (gdb) continue
#   (gdb) step    → entra DENTRO de printf
#   (gdb) next    → ejecuta la línea sin entrar

# ── BLOQUE D: Breakpoint en transición ───────────────────────
#   (gdb) delete                      → (confirmar con y)
#   (gdb) break transicionar_estado
#   (gdb) continue
#   (gdb) print estado_actual         → estado antes del cambio
#   (gdb) next
#   (gdb) print estado_actual         → estado después del cambio

# ── BLOQUE E: Modificación en tiempo real ────────────────────
#   (gdb) set variable estado_actual = AMARILLO
#   (gdb) set variable ciclos_completados = 99
#   (gdb) continue
#   (en Terminal 1: AMARILLO | Ciclos: 99)

# ── BLOQUE F: Cierre ─────────────────────────────────────────
#   (gdb) delete                      → (y)
#   (gdb) continue
#   (gdb) quit
#
#   Dentro de RPi OS (Terminal 1):
#     Ctrl+C  para detener gdbserver
#     sudo shutdown -h now  para apagar el OS
#   Salir de QEMU: Ctrl+A, luego X
