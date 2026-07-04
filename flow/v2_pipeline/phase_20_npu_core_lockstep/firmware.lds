OUTPUT_ARCH("riscv")
ENTRY(_start)
MEMORY
{
  tcm (rwx) : ORIGIN = 0x00000000, LENGTH = 8K
}
SECTIONS
{
  . = ORIGIN(tcm);
  .text : { *(.init) *(.text*) } > tcm
  .rodata : { *(.rodata*) } > tcm
  .data : { *(.data*) } > tcm
  .bss : { *(.bss*) *(COMMON) } > tcm
}
