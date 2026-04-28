#!/bin/bash
# run_qemu_rpi.sh  —  Lanza QEMU emulando Raspberry Pi OS (Buster Lite)
#
# Prerrequisitos:
#   images/raspios.img      (Raspbian Buster Lite 2021-05-07)
#   images/kernel-qemu      (kernel-qemu-4.19.50-buster)
#   images/versatile-pb.dtb (del repo dhruvvyas90/qemu-rpi-kernel)
#
# Login del OS: pi / raspberry
# Puerto SSH:   5022 del host  →  22 del OS
# Puerto GDB:   2345 del host  →  2345 del OS

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
IMAGES="$SCRIPT_DIR/images"

# ── Verificar imágenes ────────────────────────────────────────────────────────
for f in raspios.img kernel-qemu versatile-pb.dtb; do
    if [ ! -f "$IMAGES/$f" ]; then
        echo "ERROR: falta $IMAGES/$f"
        echo ""
        echo "Descarga:"
        echo "  kernel + dtb: https://github.com/dhruvvyas90/qemu-rpi-kernel"
        echo "  imagen:       https://archive.org/details/raspbian-buster-lite-2021-05-07"
        exit 1
    fi
done

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║   QEMU  —  Raspberry Pi OS (arm1176 / versatilepb)   ║"
echo "╠══════════════════════════════════════════════════════╣"
echo "║  Login   : pi / raspberry                            ║"
echo "║  SSH     : ssh -p 5022 pi@localhost                  ║"
echo "╠══════════════════════════════════════════════════════╣"
echo "║  FLUJO DE DEMO (en otra terminal):                   ║"
echo "║                                                      ║"
echo "║  1) Espera a ver el prompt:  pi@raspberrypi:~$       ║"
echo "║  2) Ejecuta setup:  ./setup_gdbserver.sh             ║"
echo "║  3) Dentro del QEMU:                                 ║"
echo "║       gdbserver :2345 ./semaforo_rpi                 ║"
echo "║  4) En otra terminal (GDB host):                     ║"
echo "║       gdb-multiarch semaforo_rpi                     ║"
echo "║       (gdb) target remote localhost:2345             ║"
echo "║       (gdb) break main                               ║"
echo "║       (gdb) continue                                 ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""
echo "Arrancando QEMU... (el boot tarda ~60 segundos)"
echo ""

cd "$SCRIPT_DIR"
exec qemu-system-arm \
    -M versatilepb \
    -cpu arm1176 \
    -m 256M \
    -kernel images/kernel-qemu \
    -dtb    images/versatile-pb.dtb \
    -hda    images/raspios.img \
    -append "root=/dev/sda2 panic=1 rootfstype=ext4 rw console=ttyAMA0,115200 loglevel=3" \
    -nographic \
    -nic user,hostfwd=tcp::5022-:22,hostfwd=tcp::2345-:2345