# Makefile — demo_gdb / Minitaller Sistemas Embebidos ITCR
#
# Targets:
#   make semaforo_rpi   → binario ARM Linux estático (para correr en RPi OS)
#   make all            → idem
#   make clean

CC_ARM_LINUX  = arm-linux-gnueabihf-gcc
CFLAGS_RPI    = -march=armv6zk -marm -mfpu=vfp -mfloat-abi=hard \
                -static -no-pie -O0 -g \
                -Wall -Wextra

.PHONY: all semaforo_rpi clean

all: semaforo_rpi

# ── Binario para Raspberry Pi OS ─────────────────────────────────────────────
semaforo_rpi: semaforo_rpi.c
	$(CC_ARM_LINUX) $(CFLAGS_RPI) -o $@ $<
	@echo ""
	@echo "Compilado: $@"
	@file $@
	@echo ""
	@echo "Siguiente paso: copiar al RPi OS"
	@echo "  ./setup_gdbserver.sh   (requiere QEMU corriendo)"

clean:
	rm -f semaforo_rpi