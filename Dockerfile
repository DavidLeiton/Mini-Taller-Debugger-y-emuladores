# ═══════════════════════════════════════════════════════════════════════════════
# STAGE 1 — dockcross/linux-armv6-lts
#
# Compila AMBOS binarios ARM con el toolchain correcto:
#   • gdbserver-armv6  → corre dentro del RPi OS, depura el semáforo
#   • semaforo_rpi     → el programa a depurar
#
# Por qué dockcross y no arm-linux-gnueabihf de Ubuntu:
#   Ubuntu 22.04 arm-linux-gnueabihf tiene crt1.o compilado para ARMv7.
#   Al linkear cualquier binario estático, _start contiene instrucciones
#   ARMv7 que dan SIGILL en el arm1176 (ARMv6) de QEMU versatilepb.
#   dockcross/linux-armv6-lts tiene crt1.o compilado para ARMv6.
# ═══════════════════════════════════════════════════════════════════════════════
FROM dockcross/linux-armv6-lts AS builder

USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
        wget make texinfo \
    && rm -rf /var/lib/apt/lists/*

# ── Copiar fuente del semáforo ────────────────────────────────────────────────
COPY demo_gdb/semaforo_rpi.c /tmp/semaforo_rpi.c

# ── Compilar semaforo_rpi para ARMv6 ─────────────────────────────────────────
RUN ${CC} \
        -march=armv6 -marm -mfpu=vfp -mfloat-abi=hard \
        -static -no-pie -O0 -g \
        -o /tmp/semaforo_rpi \
        /tmp/semaforo_rpi.c \
    && echo "=== semaforo_rpi ===" \
    && file /tmp/semaforo_rpi

# ── Compilar gdbserver estático para ARMv6 ───────────────────────────────────
RUN cd /tmp \
    && wget -q https://ftp.gnu.org/gnu/gdb/gdb-8.3.1.tar.gz \
    && tar xf gdb-8.3.1.tar.gz \
    && cd gdb-8.3.1/gdb/gdbserver \
    && ./configure \
        --host="${CROSS_TRIPLE}" \
        CC="${CC}" CXX="${CXX}" AR="${AR}" RANLIB="${RANLIB}" \
        CFLAGS="-march=armv6 -marm -mfpu=vfp -mfloat-abi=hard -O1" \
        CXXFLAGS="-march=armv6 -marm -mfpu=vfp -mfloat-abi=hard -O1" \
        LDFLAGS="-static -static-libgcc -static-libstdc++" \
        --disable-werror \
    && make -j"$(nproc)" \
    && cp gdbserver /tmp/gdbserver-armv6 \
    && echo "=== gdbserver-armv6 ===" \
    && file /tmp/gdbserver-armv6 \
    && cd /tmp && rm -rf gdb-8.3.1 gdb-8.3.1.tar.gz


# ═══════════════════════════════════════════════════════════════════════════════
# STAGE 2 — Imagen principal Ubuntu 22.04
# ═══════════════════════════════════════════════════════════════════════════════
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Copiar binarios ARM compilados correctamente en Stage 1
COPY --from=builder /tmp/gdbserver-armv6  /usr/local/bin/gdbserver-armv6
COPY --from=builder /tmp/semaforo_rpi     /usr/local/bin/semaforo_rpi_prebuilt

RUN chmod +x /usr/local/bin/gdbserver-armv6 /usr/local/bin/semaforo_rpi_prebuilt

RUN apt-get update && apt-get install -y \
    qemu-system-arm \
    gcc-arm-none-eabi \
    binutils-arm-none-eabi \
    gcc-arm-linux-gnueabihf \
    binutils-arm-linux-gnueabihf \
    gdb-multiarch \
    kpartx \
    dosfstools \
    e2fsprogs \
    wget curl make file \
    openssh-client sshpass \
    vim less \
    python3 python3-pip \
    && rm -rf /var/lib/apt/lists/*

RUN ln -sf /usr/bin/gdb-multiarch /usr/local/bin/gdb

RUN pip3 install --no-cache-dir \
    opencv-python-headless==4.9.0.80 \
    numpy==1.26.4

WORKDIR /workspace
COPY . /workspace/

# Copiar el semaforo_rpi pre-compilado al lugar esperado por los scripts
RUN cp /usr/local/bin/semaforo_rpi_prebuilt /workspace/demo_gdb/semaforo_rpi \
    && chmod +x /workspace/demo_gdb/semaforo_rpi

RUN echo "=== Verificacion final ===" \
    && file /usr/local/bin/gdbserver-armv6 \
    && file /workspace/demo_gdb/semaforo_rpi \
    && echo "========================="

CMD ["/bin/bash"]