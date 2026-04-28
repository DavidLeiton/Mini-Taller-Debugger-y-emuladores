# demo.gdb  —  Guion GDB para demo en clase (modo automático)
#
# Uso:
#   gdb-multiarch -x demo.gdb semaforo_rpi
#
# Requisito: gdbserver :2345 ./semaforo_rpi   corriendo dentro de QEMU

set architecture arm
set pagination off
set print pretty on

echo \n
echo =========================================================\n
echo   DEMO GDB  —  Depuracion de semaforo en Raspberry Pi OS\n
echo   Conectando a gdbserver en localhost:2345...\n
echo =========================================================\n
echo \n

target remote localhost:2345

echo \n[1] Poniendo breakpoint en main()\n
break main

echo \n[2] Corriendo hasta main...\n
continue

echo \n[3] Estado inicial de variables globales:\n
print estado_actual
print ciclos_completados
print duracion_seg

echo \n[4] Avanzar paso a paso (next):\n
next
next
next

echo \n[5] Inspeccion despues de 3 pasos:\n
print estado_actual
print tiempo_en_estado

echo \n[6] Poner breakpoint en cambiar_estado()\n
break cambiar_estado

echo \n[7] Continuar hasta cambio de estado...\n
continue

echo \n[8] Dentro de cambiar_estado() — ver estado antes del cambio:\n
print estado_actual
step
print estado_actual

echo \n[9] Modificar variable en tiempo real:\n
set variable ciclos_completados = 2
print ciclos_completados

echo \n[10] Continuar ejecucion hasta el final...\n
continue

echo \n
echo =========================================================\n
echo   Demo completada. El semaforo termino en 3 ciclos.\n
echo   Comandos utiles para explorar mas:\n
echo     info locals       — variables locales\n
echo     info registers    — registros ARM\n
echo     disassemble       — ver codigo ARM generado\n
echo     bt                — backtrace de llamadas\n
echo =========================================================\n
quit
