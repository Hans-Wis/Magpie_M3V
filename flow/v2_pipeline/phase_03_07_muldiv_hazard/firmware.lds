OUTPUT_ARCH("riscv")
ENTRY(_start)
MEMORY
{
  rom (rx) : ORIGIN = 0x00000000, LENGTH = 16K
}
SECTIONS
{
  . = ORIGIN(rom);
  .text : { *(.init) *(.text*) } > rom
  .rodata : { *(.rodata*) } > rom
  .data : { *(.data*) } > rom
  .bss : { *(.bss*) *(COMMON) } > rom
}
