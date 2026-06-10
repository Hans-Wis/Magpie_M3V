OUTPUT_ARCH("riscv")
ENTRY(_start)
MEMORY
{
  ram (rwx) : ORIGIN = 0x00000000, LENGTH = 256K
}
SECTIONS
{
  . = ORIGIN(ram);
  .text : { *(.init) *(.text*) } > ram
  .rodata : { *(.srodata*) *(.rodata*) } > ram
  .data : { *(.sdata*) *(.data*) } > ram
  .bss : {
    __bss_start = .;
    *(.sbss*) *(.bss*) *(COMMON)
    __bss_end = .;
  } > ram
  . = ALIGN(16);
  __stack_top = ORIGIN(ram) + LENGTH(ram);
}
