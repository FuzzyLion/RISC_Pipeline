OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY
{
    IMEM (rx) : ORIGIN = 0x00000000, LENGTH = 1K
}

SECTIONS
{
    .text ORIGIN(IMEM) : ALIGN(4)
    {
        KEEP(*(.text.start))
        *(.text .text.*)
    } > IMEM

    .trap ALIGN(4) :
    {
        KEEP(*(.trap .trap.*))
    } > IMEM
}

ASSERT(ADDR(.trap) + SIZEOF(.trap) <= ORIGIN(IMEM) + LENGTH(IMEM),
       "instruction image exceeds IMEM")
