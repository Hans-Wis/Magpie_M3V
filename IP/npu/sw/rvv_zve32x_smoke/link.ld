ENTRY(_start)
SECTIONS {
  . = 0x80000000;
  .text   : { *(.text._start) *(.text*) }
  .rodata : { *(.rodata*) }
  .data   : { *(.data*) *(.sdata*) }
  .bss    : { *(.bss*) *(.sbss*) }
  . = ALIGN(64);
  .tohost : { *(.tohost) }
}
