#!/usr/bin/env bash
# ============================================================
# prepare_rpi.sh  —  Descarga Raspberry Pi OS y lo prepara
#                    para correr en QEMU
#
# Ejecutar UNA SOLA VEZ dentro del contenedor:
#   cd /workspace/demo_gdb
#   ./prepare_rpi.sh
#
# Qué hace:
#   1. Descarga kernel QEMU-compatible para RPi (versatilepb)
#   2. Descarga Raspberry Pi OS Lite (Buster, ~450 MB)
#   3. Monta la imagen y:
#      - Habilita SSH (crea /boot/ssh)
#      - Copia semaforo_rpi al home del usuario pi
#   4. Desmonta la imagen
#
# Resultado:
#   images/kernel-qemu          (kernel compatible con QEMU)
#   images/versatile-pb.dtb     (Device Tree Blob)
#   images/raspios.img          (Raspberry Pi OS Lite)
# ============================================================

set -e

WORKSPACE="/workspace/demo_gdb"
IMAGES_DIR="$WORKSPACE/images"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC}  $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

echo ""
echo "========================================================"
echo "  Preparando Raspberry Pi OS para QEMU"
echo "========================================================"
echo ""

cd "$WORKSPACE"
mkdir -p "$IMAGES_DIR"

# ── PASO 1: Kernel QEMU-compatible para Raspberry Pi ─────────
# Fuente: github.com/dhruvvyas90/qemu-rpi-kernel
# Este kernel está compilado específicamente para correr
# Raspberry Pi OS (Buster) en QEMU con la máquina versatilepb.
KERNEL_URL="https://github.com/dhruvvyas90/qemu-rpi-kernel/raw/master/kernel-qemu-4.19.50-buster"
DTB_URL="https://github.com/dhruvvyas90/qemu-rpi-kernel/raw/master/versatile-pb-buster.dtb"

if [ ! -f "$IMAGES_DIR/kernel-qemu" ]; then
    info "Descargando kernel QEMU-compatible para Raspberry Pi..."
    wget -q --show-progress "$KERNEL_URL" -O "$IMAGES_DIR/kernel-qemu"
    info "Kernel descargado: $(du -sh "$IMAGES_DIR/kernel-qemu" | cut -f1)"
else
    info "kernel-qemu ya existe, omitiendo descarga."
fi

if [ ! -f "$IMAGES_DIR/versatile-pb.dtb" ]; then
    info "Descargando Device Tree Blob..."
    wget -q --show-progress "$DTB_URL" -O "$IMAGES_DIR/versatile-pb.dtb"
    info "DTB descargado."
else
    info "versatile-pb.dtb ya existe, omitiendo descarga."
fi

# ── PASO 2: Raspberry Pi OS Lite (Buster) ────────────────────
# Versión Buster (2021-05-28) — compatible con el kernel QEMU
RASPIOS_URL="https://downloads.raspberrypi.org/raspios_lite_armhf/images/raspios_lite_armhf-2021-05-28/2021-05-28-raspios-buster-armhf-lite.zip"
RASPIOS_ZIP="$IMAGES_DIR/raspios.zip"
RASPIOS_IMG="$IMAGES_DIR/raspios.img"

if [ ! -f "$RASPIOS_IMG" ]; then
    if [ ! -f "$RASPIOS_ZIP" ]; then
        info "Descargando Raspberry Pi OS Lite (~450 MB)..."
        info "Esto puede tardar varios minutos según tu conexión."
        wget -q --show-progress "$RASPIOS_URL" -O "$RASPIOS_ZIP"
        info "Descarga completa: $(du -sh "$RASPIOS_ZIP" | cut -f1)"
    else
        info "Archivo ZIP ya existe, omitiendo descarga."
    fi

    info "Extrayendo imagen..."
    cd "$IMAGES_DIR"
    unzip -q "$RASPIOS_ZIP"
    # Renombrar el .img a raspios.img
    mv 2021-05-28-raspios-buster-armhf-lite.img raspios.img 2>/dev/null || \
    mv *.img raspios.img 2>/dev/null || true
    cd "$WORKSPACE"
    info "Imagen extraída: $(du -sh "$RASPIOS_IMG" | cut -f1)"
else
    info "raspios.img ya existe, omitiendo descarga."
fi

# ── PASO 3: Compilar semaforo_rpi ────────────────────────────
info "Compilando semaforo_rpi para ARM Linux..."
arm-linux-gnueabihf-gcc \
    -O0 -g -Wall -static -no-pie \
    semaforo_rpi.c -o semaforo_rpi
file semaforo_rpi
info "Compilación exitosa."

# ── PASO 4: Modificar la imagen de Raspberry Pi OS ───────────
info "Montando la imagen de Raspberry Pi OS..."

# Crear puntos de montaje
mkdir -p /mnt/rpi-boot /mnt/rpi-root

# Asociar la imagen con dispositivos de loop
LOOP_DEV=$(losetup -f --show -P "$RASPIOS_IMG")
info "Dispositivo loop: $LOOP_DEV"

# Esperar a que el kernel cree los dispositivos de partición
sleep 1

# Montar partición boot (FAT32) y root (ext4)
mount "${LOOP_DEV}p1" /mnt/rpi-boot
mount "${LOOP_DEV}p2" /mnt/rpi-root

# Habilitar SSH en el primer arranque
touch /mnt/rpi-boot/ssh
info "SSH habilitado."

# Copiar semaforo_rpi al home del usuario pi
cp semaforo_rpi /mnt/rpi-root/home/pi/semaforo_rpi
chmod +x /mnt/rpi-root/home/pi/semaforo_rpi
info "semaforo_rpi copiado a /home/pi/ en la imagen."

# Desmontar
umount /mnt/rpi-boot
umount /mnt/rpi-root
losetup -d "$LOOP_DEV"
info "Imagen desmontada correctamente."

# ── Resumen ───────────────────────────────────────────────────
echo ""
echo "========================================================"
echo -e "  ${GREEN}✔ Raspberry Pi OS listo para QEMU${NC}"
echo "========================================================"
echo ""
echo "  Archivos en images/:"
echo "    kernel-qemu      (kernel QEMU-compatible para RPi)"
echo "    versatile-pb.dtb (Device Tree Blob)"
echo "    raspios.img      (Raspberry Pi OS Lite - Buster)"
echo ""
echo "  Credenciales de Raspberry Pi OS:"
echo "    Usuario  : pi"
echo "    Password : raspberry"
echo ""
echo "  Siguiente paso:"
echo "    ./run_qemu_rpi.sh"
echo "========================================================"
echo ""