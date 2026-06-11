SECTIONS {
    . = 0x80000000;
    .memory : {
        *(.init);
        . = ALIGN(4);
        *(.text);
        *(*);
        . = ALIGN(4);
        end = .;
    }
}
