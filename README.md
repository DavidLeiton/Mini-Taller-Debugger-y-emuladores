# Minitaller: Emulación y Depuración en Sistemas Embebidos
## QEMU · GDB · Raspberry Pi OS · Python · pdb

> **Curso:** Taller de Sistemas Embebidos — ITCR
> **Autor:** David Leitón Flores
> **Entorno:** Docker (reproducible en cualquier laptop)

## Requisitos del host

| Herramienta       | Versión mínima |
|-------------------|----------------|
| Docker            | 20.10+         |
| docker compose    | v2+            |
| RAM disponible    | ≥ 4 GB         |
| Espacio en disco  | ≥ 5 GB         |

---

## Paso 0 — Descargar imágenes (una sola vez, antes del build)

Las imágenes no están en el repo por su tamaño. Descargarlas en `demo_gdb/images/`:

```bash
cd demo_gdb/images

# Kernel ARMv6 compatible con versatilepb + DTB
wget https://github.com/dhruvvyas90/qemu-rpi-kernel/raw/master/kernel-qemu-4.19.50-buster
wget https://github.com/dhruvvyas90/qemu-rpi-kernel/raw/master/versatile-pb.dtb

# Renombrar al nombre esperado por run_qemu_rpi.sh
mv kernel-qemu-4.19.50-buster kernel-qemu
```

```bash
# Verificar que unzip está instalado
which unzip || sudo apt install unzip

# Imagen Raspbian Buster Lite (archive.org — URL verificada)
wget --show-progress \
    "https://archive.org/download/2021-05-07-raspios-buster-armhf-lite/2021-05-07-raspios-buster-armhf-lite.zip" \
    -O raspios.zip
unzip raspios.zip
mv 2021-05-07-raspios-buster-armhf-lite.img raspios.img
rm raspios.zip
```

Verificar que los tres archivos existen:
```bash
ls -lh demo_gdb/images/
# raspios.img       ~1.8 GB
# kernel-qemu       ~4-5 MB
# versatile-pb.dtb  ~10-20 KB
```

---

## Gestión de contenedores

### Ver qué contenedores están corriendo
```bash
docker ps          # contenedores activos
docker ps -a       # activos + detenidos
```

### Limpiar contenedores huérfanos
```bash
docker compose down --remove-orphans
```
Hacer esto siempre que aparezcan warnings de `orphan containers` o el error
`Failed to get write lock` al arrancar QEMU.

### Nombre típico del contenedor
`docker compose run` genera nombres con este formato:
```
mini-taller-debugger-y-emuladores-embebidos-run-XXXXXXXX
```
Usar siempre `docker ps` para ver el nombre exacto.

---

## Cómo entrar al contenedor

### CASO A — Primera vez (repo recién clonado)
```bash
# Construir la imagen (~15-20 min, compila gdbserver ARMv6 desde fuente)
docker compose build

# Entrar al contenedor
docker compose run embebidos bash
```

### CASO B — Ya hice build, quiero entrar de nuevo
```bash
# Crear un contenedor nuevo
docker compose run embebidos bash

# O, si ya hay uno corriendo, abrir otra terminal en el mismo
docker ps
docker exec -it <nombre-del-contenedor> bash
```

### CASO C — Necesito una segunda o tercera terminal (para la demo)
```bash
docker ps
docker exec -it <nombre-del-contenedor> bash
```

---

## Demo del profesor: QEMU + GDB + Raspberry Pi OS

La demo requiere **3 terminales** abiertas simultáneamente.

### Antes de empezar — limpiar sesiones anteriores
```bash
docker compose down --remove-orphans
docker ps | grep minitaller
# No debe mostrar nada
```

---

### TERMINAL 1 — Arrancar QEMU con Raspberry Pi OS

```bash
docker compose run embebidos bash
```

```bash
cd /workspace/demo_gdb
./run_qemu_rpi.sh
```

Esperar ~60 segundos hasta ver:
```
raspberrypi login:
```

Login:
- Usuario: `pi` → Enter
- Password: `raspberry` → Enter (no se ve al escribir)

Debes ver:
```
pi@raspberrypi:~$
```

**No escribas nada más aquí todavía.**

---

### TERMINAL 2 — Copiar archivos al RPi OS

```bash
docker ps
docker exec -it <nombre-del-contenedor> bash
```

```bash
# PASO CRÍTICO: usar el binario pre-compilado con ARMv6 correcto.
# El volumen mount del compose sobreescribe demo_gdb/, por eso el binario
# correcto está guardado en /usr/local/bin/semaforo_rpi_prebuilt.
cp /usr/local/bin/semaforo_rpi_prebuilt /workspace/demo_gdb/semaforo_rpi

# Verificar arquitectura correcta
file /workspace/demo_gdb/semaforo_rpi
# → ELF 32-bit LSB executable, ARM ... for GNU/Linux 4.19.0

file /usr/local/bin/gdbserver-armv6
# → ELF 32-bit LSB executable, ARM ... for GNU/Linux 4.19.0
```

```bash
cd /workspace/demo_gdb

# Copiar gdbserver al RPi OS via SSH (puerto 5022 → RPi OS :22)
sshpass -p raspberry scp \
    -o StrictHostKeyChecking=no -P 5022 \
    /usr/local/bin/gdbserver-armv6 \
    pi@localhost:/tmp/gdbserver

# Copiar semaforo_rpi al RPi OS
sshpass -p raspberry scp \
    -o StrictHostKeyChecking=no -P 5022 \
    semaforo_rpi \
    pi@localhost:/tmp/semaforo_rpi

# Dar permisos y verificar
sshpass -p raspberry ssh \
    -o StrictHostKeyChecking=no -p 5022 pi@localhost \
    "chmod +x /tmp/gdbserver /tmp/semaforo_rpi && \
     echo '--- OK ---' && ls -lh /tmp/gdbserver /tmp/semaforo_rpi"
```

Debes ver:
```
--- OK ---
-rwxr-xr-x 1 pi pi 7.9M ... /tmp/gdbserver
-rwxr-xr-x 1 pi pi 454K ... /tmp/semaforo_rpi
```

---

### TERMINAL 1 — Lanzar gdbserver dentro del RPi OS

En el prompt `pi@raspberrypi:~$`:

```bash
/tmp/gdbserver :2345 /tmp/semaforo_rpi
```

Debes ver:
```
Process /tmp/semaforo_rpi created; pid = 462
Listening on port 2345
```

El programa queda **pausado esperando GDB**. No escribas más aquí.

---

### TERMINAL 3 — Conectar GDB y depurar

```bash
docker exec -it <nombre-del-contenedor> bash
gdb-multiarch /workspace/demo_gdb/semaforo_rpi
```

Dentro del prompt `(gdb)`:

```gdb
set architecture arm
target remote localhost:2345
```
→ `Remote debugging using localhost:2345`

```gdb
break main
continue
```
→ `Breakpoint 1, main () at semaforo_rpi.c:72`

---

### Comandos de la demo en clase

```gdb
print estado_actual          → $1 = ROJO
print ciclos_completados     → $2 = 0
print duracion_seg           → $3 = {5, 2, 4}
next                         → avanza una línea
break cambiar_estado         → breakpoint en cambio de estado
continue                     → corre hasta el cambio
step                         → entra dentro de la función
info locals                  → variables locales
info registers               → registros ARM (r0-r15, pc, sp, lr)
set variable ciclos_completados = 2   → modifica en tiempo real
continue                     → el semáforo termina antes
quit                         → salir de GDB
```

### Modo demo automático
```bash
gdb-multiarch -x /workspace/demo_gdb/demo.gdb /workspace/demo_gdb/semaforo_rpi
```
Ejecuta toda la secuencia automáticamente: conecta, breakpoints, imprime variables,
modifica `ciclos_completados` en vivo y termina solo.

---

### Salir limpiamente

```bash
# Terminal 3 (GDB)
quit

# Terminal 1 (QEMU): Ctrl+A luego X
# O desde el RPi OS:
sudo poweroff

# Limpiar todos los contenedores
docker compose down --remove-orphans
```

---

## Tutorial de estudiantes: Python + pdb

```bash
docker compose run embebidos bash
cd /workspace/tutorial_pdb

# Observar los síntomas de los bugs
python3 semaforo_vision.py

# Iniciar depuración con pdb
python3 -m pdb semaforo_vision.py

# Ver el tutorial completo
cat README.md
```

Las imágenes generadas se guardan en `/tmp/semaforo_*.png`.

---

## Arquitectura del sistema

```
┌──────────────────────────────────────────────────────────────┐
│  Laptop (host)                                               │
│                                                              │
│  ┌───────────────────────────────────────────────────────┐   │
│  │  Docker Container (Ubuntu 22.04)                      │   │
│  │                                                       │   │
│  │  ┌─────────────────────┐   ┌───────────────────────┐  │   │
│  │  │  QEMU (Terminal 1)  │   │   GDB  (Terminal 3)   │  │   │
│  │  │                     │   │                       │  │   │
│  │  │  qemu-system-arm    │◄──│  gdb-multiarch        │  │   │
│  │  │  -M versatilepb     │   │  target remote        │  │   │
│  │  │  arm1176 / 256MB    │   │  localhost:2345       │  │   │
│  │  │                     │   │                       │  │   │
│  │  │  ┌───────────────┐  │   │  break/step/print     │  │   │
│  │  │  │ Raspberry Pi  │  │   │  set variable         │  │   │
│  │  │  │ OS (Buster)   │  │   └───────────────────────┘  │   │
│  │  │  │               │  │                               │   │
│  │  │  │ gdbserver     │  │   ┌───────────────────────┐  │   │
│  │  │  │ :2345         │  │   │  Setup (Terminal 2)   │  │   │
│  │  │  │ semaforo_rpi  │  │   │  scp gdbserver        │  │   │
│  │  │  └───────────────┘  │   │  scp semaforo_rpi     │  │   │
│  │  └─────────────────────┘   └───────────────────────┘  │   │
│  │         puerto 5022 (SSH) y 2345 (GDB)                │   │
│  └───────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────┘
```

---

## Nota técnica: por qué el build es multi-stage

El toolchain `arm-linux-gnueabihf` de Ubuntu 22.04 genera código ARMv7.
Su `crt1.o` contiene instrucciones ARMv7 que causan `SIGILL` en el
arm1176 (ARMv6) de QEMU. La solución es compilar ambos binarios ARM
(`gdbserver` y `semaforo_rpi`) en Stage 1 con `dockcross/linux-armv6-lts`,
que tiene un toolchain construido desde cero para ARMv6 con los CRT correctos.
Stage 2 copia esos binarios a la imagen final de Ubuntu 22.04.

---

## Solución de problemas

| Síntoma | Causa | Solución |
|---------|-------|----------|
| `SIGILL` al hacer `continue` | Binario tiene CRT de ARMv7 | `cp /usr/local/bin/semaforo_rpi_prebuilt /workspace/demo_gdb/semaforo_rpi` antes del SCP |
| `Failed to get write lock` en QEMU | Otro contenedor tiene la imagen abierta | `docker compose down --remove-orphans` |
| `No such container` en `docker exec` | Nombre incorrecto | `docker ps` para ver el nombre actual |
| `Connection refused` en GDB | gdbserver no está corriendo | Relanzar `/tmp/gdbserver :2345 /tmp/semaforo_rpi` en Terminal 1 |
| `FATAL: kernel too old` en gdbserver | glibc pide kernel ≥ 5.4 | Verificar que Dockerfile usa `dockcross/linux-armv6-lts` (no `latest`) |
| `Permission denied` al hacer SCP | Permisos en `/home/pi` | Usar `/tmp/` como destino (ya está así en los comandos) |
| SSH no disponible tras 30 intentos | SSH no habilitado | Desde Terminal 1: `sudo systemctl enable ssh && sudo systemctl start ssh` |
| Warnings `orphan containers` | Contenedores de sesiones anteriores | `docker compose down --remove-orphans` |
| `Permission denied` al mover archivos a `images/` | Docker creó la carpeta como root | `sudo chown -R $USER:$USER demo_gdb/images/` |

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
