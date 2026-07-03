OUTPUT_ARCH("riscv")
ENTRY(_start)
MEMORY
{
  ram (rwx) : ORIGIN = 0x80000000, LENGTH = 256K
}
SECTIONS
{
  . = ORIGIN(ram);
  .text : { *(.init) *(.text*) } > ram
}
