OUTPUT_ARCH("riscv")
ENTRY(_start)
MEMORY
{
  ram (rwx) : ORIGIN = 0x80000000, LENGTH = 4K
}
SECTIONS
{
  . = ORIGIN(ram);
  .text : { *(.init) *(.text*) } > ram
  .rodata : { *(.rodata*) } > ram
  .data : { *(.data*) } > ram
  .bss : { *(.bss*) *(COMMON) } > ram
}
