#!/bin/bash
# setup_gdbserver.sh  —  Copia gdbserver y semaforo_rpi al Raspberry Pi OS
#                        (se ejecuta UNA VEZ después del primer boot de QEMU)
#
# Requisitos:
#   • QEMU corriendo con ./run_qemu_rpi.sh (en otra terminal)
#   • Docker con sshpass instalado
#   • /usr/local/bin/gdbserver-armv6 compilado en el Dockerfile

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RPI_HOST="localhost"
RPI_PORT="5022"
RPI_USER="pi"
RPI_PASS="raspberry"
SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=5"

GDBSERVER_SRC="/usr/local/bin/gdbserver-armv6"
SEMAFORO_SRC="$SCRIPT_DIR/semaforo_rpi"

# ── Verificar binarios locales ────────────────────────────────────────────────
echo "[setup] Verificando binarios..."

if [ ! -f "$GDBSERVER_SRC" ]; then
    echo "ERROR: $GDBSERVER_SRC no existe"
    echo "  ¿Se construyó correctamente el Docker? (docker compose build)"
    exit 1
fi

if [ ! -f "$SEMAFORO_SRC" ]; then
    echo "[setup] Compilando semaforo_rpi..."
    make -C "$SCRIPT_DIR" semaforo_rpi
fi

echo "[setup] gdbserver-armv6 : $(file $GDBSERVER_SRC | cut -d: -f2)"
echo "[setup] semaforo_rpi    : $(file $SEMAFORO_SRC  | cut -d: -f2)"

# ── Esperar a que SSH esté disponible ─────────────────────────────────────────
echo ""
echo "[setup] Esperando SSH en localhost:$RPI_PORT ..."
for i in $(seq 1 30); do
    if sshpass -p "$RPI_PASS" ssh $SSH_OPTS -p "$RPI_PORT" "$RPI_USER@$RPI_HOST" \
            "echo ok" &>/dev/null; then
        echo "[setup] SSH disponible ✓"
        break
    fi
    echo "  ... intento $i/30"
    sleep 5
done

# ── Copiar archivos ───────────────────────────────────────────────────────────
echo ""
echo "[setup] Copiando gdbserver (ARMv6 estático)..."
sshpass -p "$RPI_PASS" scp $SSH_OPTS \
    -P "$RPI_PORT" \
    "$GDBSERVER_SRC" \
    "$RPI_USER@$RPI_HOST:~/gdbserver"

echo "[setup] Copiando semaforo_rpi..."
sshpass -p "$RPI_PASS" scp $SSH_OPTS \
    -P "$RPI_PORT" \
    "$SEMAFORO_SRC" \
    "$RPI_USER@$RPI_HOST:~/semaforo_rpi"

# ── Permisos y verificación ───────────────────────────────────────────────────
echo "[setup] Ajustando permisos..."
sshpass -p "$RPI_PASS" ssh $SSH_OPTS -p "$RPI_PORT" "$RPI_USER@$RPI_HOST" \
    "chmod +x ~/gdbserver ~/semaforo_rpi && echo 'OK' && ls -lh ~/gdbserver ~/semaforo_rpi"

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║   Setup completado ✓                                 ║"
echo "║                                                      ║"
echo "║  Dentro del QEMU (login: pi / raspberry):            ║"
echo "║    gdbserver :2345 ./semaforo_rpi                    ║"
echo "║                                                      ║"
echo "║  En esta terminal (host Docker):                     ║"
echo "║    gdb-multiarch semaforo_rpi                        ║"
echo "║    (gdb) set architecture arm                        ║"
echo "║    (gdb) target remote localhost:2345                ║"
echo "║    (gdb) break main                                  ║"
echo "║    (gdb) continue                                    ║"
echo "╚══════════════════════════════════════════════════════╝"