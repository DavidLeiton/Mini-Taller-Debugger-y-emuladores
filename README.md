# Minitaller: Emulación y Depuración en Sistemas Embebidos
## QEMU · GDB · Raspberry Pi · Python · pdb

> **Curso:** Taller de Sistemas Embebidos — ITCR  
> **Duración:** 90–110 minutos  
> **Entorno:** Docker (reproducible en cualquier laptop)

---

## Estructura del repositorio

```
minitaller-embebidos/
├── Dockerfile                  ← entorno completo (QEMU + GDB + Python)
├── docker-compose.yml          ← inicio rápido
│
├── demo_gdb/                   ← Demo del profesor (QEMU + GDB)
│   ├── semaforo.c              ← programa C bare-metal
│   ├── startup.s               ← punto de entrada ARM
│   ├── linker.ld               ← script de enlace
│   ├── Makefile                ← compilación cruzada ARM
│   ├── run_qemu.sh             ← lanzar QEMU con gdbstub
│   └── demo.gdb                ← guion GDB para la demo
│
└── tutorial_pdb/               ← Tutorial para estudiantes
    ├── semaforo_vision.py      ← programa con 2 bugs (OpenCV)
    ├── semaforo_vision_SOLUCION.py  ← versión corregida
    └── README.md               ← tutorial paso a paso con pdb
```

---

## Requisitos del host

| Herramienta | Versión mínima |
|-------------|----------------|
| Docker      | 20.10+         |
| docker compose | v2+         |
| RAM disponible | ≥ 2 GB     |

---

## Inicio rápido

### Opción A — Docker Compose (recomendado)

```bash
# Construir la imagen (una sola vez, ~5 min)
docker compose build

# Abrir el contenedor principal
docker compose run embebidos
```

### Opción B — Docker directo

```bash
# Construir
docker build -t embebidos .

# Ejecutar con TTY interactivo
docker run -it --rm embebidos
```

---

## Demo del profesor: QEMU + GDB

### Terminal 1 — Compilar y lanzar QEMU

```bash
# Dentro del contenedor
cd /workspace/demo_gdb
make all                    # compila el semáforo para ARM
./run_qemu.sh               # lanza QEMU, la CPU queda DETENIDA
```

Verás:
```
========================================
  QEMU + GDB  |  Semáforo ARM Bare-Metal
  Máquina : versatilepb
  ⚡ QEMU iniciado y DETENIDO esperando GDB
  Abra otra terminal y ejecute:
      gdb-multiarch semaforo.elf
      (gdb) target remote localhost:1234
```

### Terminal 2 — Conectar GDB (modo demo automático)

```bash
# Nueva terminal, mismo contenedor
docker exec -it minitaller-embebidos bash
cd /workspace/demo_gdb

# Modo demo automático (ejecuta demo.gdb)
gdb-multiarch -x demo.gdb semaforo.elf
```

O bien, **modo manual paso a paso** para mostrar en clase:

```bash
gdb-multiarch semaforo.elf
(gdb) set architecture arm
(gdb) target remote localhost:1234
(gdb) break main
(gdb) continue
(gdb) print estado_actual
(gdb) print ciclos_completados
(gdb) next
(gdb) step
(gdb) info registers
(gdb) set variable ciclos_completados = 99
(gdb) continue
```

---

## Tutorial de estudiantes: Python + pdb

```bash
# Dentro del contenedor
cd /workspace/tutorial_pdb

# Ejecutar el programa con bugs
python3 semaforo_vision.py

# Seguir el tutorial paso a paso:
cat README.md
```

Las imágenes generadas se guardan en `/tmp/semaforo_*.png`.

---

## Arquitectura de la demo

```
┌─────────────────────────────────────────────────┐
│  Docker Container (Ubuntu 22.04)                │
│                                                 │
│  ┌─────────────────────┐  ┌───────────────────┐ │
│  │   QEMU (Terminal 1) │  │  GDB (Terminal 2) │ │
│  │                     │  │                   │ │
│  │  qemu-system-arm    │◄─┤  gdb-multiarch    │ │
│  │  -M versatilepb     │  │  target remote    │ │
│  │  -s -S              │  │  localhost:1234   │ │
│  │                     │  │                   │ │
│  │  [semaforo.elf]     │  │  break/step/print │ │
│  │  ARM bare-metal     │  │                   │ │
│  └─────────────────────┘  └───────────────────┘ │
│           ↑                                     │
│    gdbstub en :1234                             │
└─────────────────────────────────────────────────┘
```

---

## Comandos GDB de referencia rápida

```
break <función>          → poner breakpoint
break semaforo.c:42      → breakpoint en línea específica
continue  (c)            → continuar hasta próximo breakpoint
next      (n)            → siguiente línea (sin entrar funciones)
step      (s)            → siguiente línea (entra en funciones)
print <var>              → imprimir variable
print estado_actual      → ver estado del semáforo
info registers           → ver todos los registros ARM
info locals              → ver variables locales
set variable x = 99      → modificar variable en tiempo real
delete <n>               → eliminar breakpoint N
quit      (q)            → salir de GDB
```

---

## Solución de problemas comunes

| Problema | Solución |
|----------|----------|
| `Connection refused` al conectar GDB | Verificar que QEMU está corriendo con `-s -S` |
| `make: arm-none-eabi-gcc: not found` | Reconstruir la imagen Docker |
| `pdb` no aparece al ejecutar Python | Verificar que se agregó `breakpoint()` en el código |
| Imágenes OpenCV no se guardan | Verificar permisos en `/tmp` dentro del contenedor |

---

## Notas sobre QEMU y Raspberry Pi

La máquina **`versatilepb`** usada en esta demo es hardware ARM real emulado,
equivalente a la arquitectura de una **Raspberry Pi 1** (ARM926EJ-S).

QEMU también soporta emulación directa de Raspberry Pi:

```bash
# Raspberry Pi 2 (ARM Cortex-A7)
qemu-system-arm -M raspi2b ...

# Raspberry Pi 3 (AArch64 Cortex-A53)
qemu-system-aarch64 -M raspi3b ...
```

Para estos modelos se necesita una imagen de kernel y DTB específicos.
El flujo de GDB es **idéntico** en todos los casos.

---

*Generado para el Taller de Sistemas Embebidos — ITCR — 2026*


parte nueva

# Minitaller: Emulación y Depuración en Sistemas Embebidos

> **Curso:** Taller de Sistemas Embebidos — ITCR  
> **Duración:** 90–110 minutos  
> **Entorno:** Docker (reproducible en cualquier laptop)

---

## Estructura del repositorio

```
minitaller-embebidos/
├── Dockerfile                       ← Ubuntu 22.04 + QEMU + toolchains + gdbserver ARMv6
├── docker-compose.yml               ← servicios embebidos y tutorial-pdb
│
├── demo_gdb/                        ← Demo principal: QEMU + Raspberry Pi OS + GDB
│   ├── semaforo_rpi.c               ← programa C con printf/sleep para ARM Linux
│   ├── Makefile                     ← compila con arm-linux-gnueabihf-gcc
│   ├── run_qemu_rpi.sh              ← lanza QEMU con Raspberry Pi OS
│   ├── setup_gdbserver.sh           ← copia gdbserver y semaforo al RPi via SSH
│   ├── demo.gdb                     ← guion GDB automático para clase
│   └── images/                      ← ⚠ NO incluidos en el repo (ver abajo)
│       ├── raspios.img              ← Raspbian Buster Lite 2021-05-07 (1.8 GB)
│       ├── kernel-qemu              ← kernel-qemu-4.19.50-buster
│       └── versatile-pb.dtb        ← DTB para versatilepb
│
└── tutorial_pdb/                    ← Tutorial para estudiantes: Python + pdb
    ├── semaforo_vision.py           ← programa con 2 bugs (OpenCV)
    ├── semaforo_vision_SOLUCION.py  ← versión corregida
    └── README.md                    ← tutorial paso a paso con pdb
```

---

## Descargar imágenes (una sola vez)

```bash
# Kernel + DTB (ARMv6 compatible con versatilepb)
cd demo_gdb/images
wget https://github.com/dhruvvyas90/qemu-rpi-kernel/raw/master/kernel-qemu-4.19.50-buster
wget https://github.com/dhruvvyas90/qemu-rpi-kernel/raw/master/versatile-pb.dtb

# Imagen Raspbian Buster Lite
# Desde: https://archive.org/details/raspbian-buster-lite-2021-05-07
# Descargar: 2021-05-07-raspios-buster-armhf-lite.zip → extraer raspios.img
```

---

## Inicio rápido

```bash
# 1. Construir imagen Docker (primera vez, ~15 min — compila gdbserver ARMv6)
docker compose build

# 2. Abrir el contenedor principal
docker compose run embebidos
```

---

## Demo del profesor: QEMU + GDB + Raspberry Pi OS

### Terminal 1 — Arrancar QEMU

```bash
# Dentro del contenedor
cd /workspace/demo_gdb
./run_qemu_rpi.sh
```

Espera el prompt `pi@raspberrypi:~$` (≈ 60 s). Login: **pi / raspberry**

### Terminal 2 — Copiar gdbserver al RPi (una sola vez)

```bash
# Nueva terminal, mismo contenedor
docker exec -it minitaller-embebidos bash
cd /workspace/demo_gdb
./setup_gdbserver.sh
```

### Terminal 1 (dentro de QEMU) — Lanzar gdbserver

```bash
gdbserver :2345 ./semaforo_rpi
```

### Terminal 2 — Conectar GDB

```bash
# Modo demo automático
gdb-multiarch -x demo.gdb semaforo_rpi

# O modo manual paso a paso (para mostrar en clase)
gdb-multiarch semaforo_rpi
(gdb) set architecture arm
(gdb) target remote localhost:2345
(gdb) break main
(gdb) continue
(gdb) print estado_actual
(gdb) print ciclos_completados
(gdb) next
(gdb) set variable ciclos_completados = 2
(gdb) continue
```

---

## Tutorial de estudiantes: Python + pdb

```bash
# En el contenedor tutorial-pdb o embebidos
cd /workspace/tutorial_pdb

# Ejecutar programa con bugs (observar síntomas)
python3 semaforo_vision.py

# Iniciar depuración con pdb
python3 -m pdb semaforo_vision.py

# Ver tutorial completo
cat README.md
```

---

## Solución al problema principal: gdbserver para ARMv6

El Dockerfile cross-compila `gdbserver` estático para ARMv6 usando:

```
--host=arm-linux-gnueabihf          ← clave: indica cross-compilation
CC=arm-linux-gnueabihf-gcc          ← cross-compiler explícito
CFLAGS="-march=armv6zk -mfpu=vfp -mfloat-abi=hard"  ← ARMv6 exacto
LDFLAGS="-static -static-libgcc -static-libstdc++"  ← sin dependencias .so
```

El binario queda en `/usr/local/bin/gdbserver-armv6` y se copia al RPi OS
via SCP con `setup_gdbserver.sh`.

---

## Referencia GDB rápida

```
break <función>          → breakpoint
break semaforo_rpi.c:42  → breakpoint en línea
continue  (c)            → correr hasta próximo breakpoint
next      (n)            → siguiente línea
step      (s)            → entrar en función
print <var>              → inspeccionar variable
info locals              → todas las variables locales
info registers           → registros ARM
set variable x = 99      → modificar en tiempo real
bt                       → backtrace
quit      (q)            → salir
```

---

*Generado para el Taller de Sistemas Embebidos — ITCR — 2026*
