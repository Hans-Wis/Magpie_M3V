OUTPUT_ARCH("riscv")
ENTRY(_start)

MEMORY
{
  ram (rwx) : ORIGIN = 0x00001000, LENGTH = 2M
}

SECTIONS
{
  . = ORIGIN(ram);
  .text : {
    KEEP(*(.text.start))
    *(.text.init)
    *(.text*)
    *(.init)
  } > ram

  . = ALIGN(16);
  .rodata : { *(.rodata*) } > ram

  . = ALIGN(16);
  .data : {
    *(.data*)
    *(.region*)
    *(.h*_region*)
    *(.s_region*)
    *(.h*_s_region*)
    *(.amo*)
    *(.h*_amo*)
  } > ram

  . = ALIGN(16);
  .tohost : { *(.tohost) } > ram

  . = ALIGN(16);
  .sdata : { *(.sdata*) } > ram
  . = ALIGN(16);
  .bss : { *(.bss*) *(COMMON) } > ram
}
