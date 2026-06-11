SECTIONS {
    . = 0x000000;
    .text : { *(.init) *(.text*) }
    .rodata : ALIGN(4) { *(.rodata*) *(.srodata*) }
    .data : ALIGN(4) { *(.data*) *(.sdata*) }
    .bss : ALIGN(4) {
        __bss_start = .;
        *(.bss*) *(.sbss*) *(COMMON)
        . = ALIGN(4);
        __bss_end = .;
    }
    end = .;
}
