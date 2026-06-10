OUTPUT_ARCH("riscv")
ENTRY(_start)
MEMORY
{
  ram (rwx) : ORIGIN = 0x00001000, LENGTH = 256K
}
SECTIONS
{
  . = ORIGIN(ram);
  .text : { *(.text*) *(.init) } > ram
  . = ALIGN(8);
  .rodata : { *(.rodata*) } > ram
  . = ALIGN(8);
  .data : {
    *(.data*)
    *(.region*)
    *(.h*_region*)
    *(.s_region*)
    *(.h*_s_region*)
    *(.amo*)
    *(.h*_amo*)
  } > ram
  . = ALIGN(8);
  .sdata : { *(.sdata*) } > ram
  . = ALIGN(8);
  .bss : { *(.bss*) *(COMMON) } > ram
  . = ALIGN(8);
  .user_stack : { *(.user_stack*) } > ram
}
