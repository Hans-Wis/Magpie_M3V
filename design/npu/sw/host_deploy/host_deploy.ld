/* gate_86 XIP-boot link (ADR-0069): SAME sources as host_deploy.ld, only the
 * VMA moves into the QSPI flash window. Stack stays in shared SRAM (crt0). */
OUTPUT_ARCH("riscv")
ENTRY(_start)

MEMORY
{
  flash (rx) : ORIGIN = 0x40000000, LENGTH = 1M
}

SECTIONS
{
  .text : { *(.init) *(.text*) } > flash
  .rodata : { *(.rodata*) } > flash
  .data : { *(.data*) } > flash
  .bss : { *(.bss*) *(.sbss*) *(COMMON) } > flash
}
