OUTPUT_ARCH("riscv")
ENTRY(_start)

MEMORY
{
  imem (rx) : ORIGIN = 0x00000000, LENGTH = 32K
}

SECTIONS
{
  .text : { *(.init) *(.text*) } > imem
  .rodata : { *(.rodata*) } > imem
  .data : { *(.data*) } > imem
  .bss : { *(.bss*) *(.sbss*) *(COMMON) } > imem
}
