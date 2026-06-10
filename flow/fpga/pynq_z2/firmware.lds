MEMORY
{
    ram (rwx) : ORIGIN = 0x20000000, LENGTH = 16K
}

ENTRY(_start)

SECTIONS
{
    .text : {
        KEEP(*(.init))
        *(.text*)
        *(.rodata*)
    } > ram

    .data : {
        *(.sdata*)
        *(.data*)
    } > ram

    .bss (NOLOAD) : {
        *(.sbss*)
        *(.bss*)
        *(COMMON)
    } > ram

    . = ALIGN(4);
    _end = .;
    _stack_top = ORIGIN(ram) + LENGTH(ram);
}
