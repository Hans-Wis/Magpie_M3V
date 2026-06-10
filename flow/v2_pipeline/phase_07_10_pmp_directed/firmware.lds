SECTIONS {
    .memory : {
        . = 0x000000;
        *(.init);
        *(.text.init);
        . = ALIGN(4);
        *(.text);
        *(.text*);
        *(.rodata*);
        *(.srodata*);
        *(.data*);
        *(.sdata*);
        *(.bss*);
        *(COMMON);
        . = ALIGN(4);
        end = .;
    }
}
