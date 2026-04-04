MEMORY {
    ISRAM (rx)  : ORIGIN = 0x00000000, LENGTH = 8K
    DSRAM (rwx) : ORIGIN = 0x00002000, LENGTH = 8K
}

SECTIONS {
    .text : {
        *(.text*)
    } > ISRAM

    .data : {
        *(.data*)
    } > DSRAM

    .bss : {
        *(.bss*)
        *(COMMON)
    } > DSRAM
}
