/* ============================================================
 * linker.ld  —  Script de enlace bare-metal Raspberry Pi 2B
 *
 * Mapa de memoria BCM2836 (RPi 2B):
 *   0x00000000 - 0x3EFFFFFF : RAM (hasta 1 GB)
 *   0x3F000000 - 0x3FFFFFFF : Periféricos (GPU, UART, etc.)
 *   0x3F201000              : UART0 PL011
 *
 * QEMU con -kernel carga el ELF y salta al entry point.
 * 0x8000 es la dirección de carga estándar del kernel en RPi.
 * ============================================================ */

ENTRY(_start)

SECTIONS
{
    /* ── Dirección de carga estándar de RPi ──────────────── */
    . = 0x8000;

    /* ── Código ──────────────────────────────────────────── */
    .text :
    {
        *(.text*)
        *(.rodata*)
    }

    /* ── Datos inicializados ─────────────────────────────── */
    .data :
    {
        *(.data*)
    }

    /* ── BSS (variables globales sin inicializar) ─────────── */
    .bss :
    {
        _bss_start = .;
        *(.bss*)
        *(COMMON)
        _bss_end = .;
    }

    /* ── Stack: 16 KB ─────────────────────────────────────── */
    . = ALIGN(8);
    . = . + 0x4000;
    _stack_top = .;
}
