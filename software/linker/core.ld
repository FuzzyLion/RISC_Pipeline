OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY
{
    IMEM (rx) : ORIGIN = 0x00000000, LENGTH = 1K
}

SECTIONS
{
    .text 0x00000000 : ALIGN(4)
    {
        KEEP(*(.text.start))
        *(.text .text.*)
    } > IMEM

    .trap 0x00000100 : ALIGN(4)
    {
        KEEP(*(.trap .trap.*))
    } > IMEM
}

ASSERT(SIZEOF(.text) <= 0x100,
       "normal text overlaps trap handler")
       