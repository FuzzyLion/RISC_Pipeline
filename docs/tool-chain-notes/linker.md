# Linker Script Notes

This note explains the linker script syntax currently used in
[`software/linker/core.ld`](../../software/linker/core.ld). It does not cover
general-purpose linker script features that are not used by this project.

## Current Script

```ld
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
```

## Main Statements

### `OUTPUT_ARCH(riscv)`

Marks the output ELF as a RISC-V executable. This does not select the supported
instruction subset; `-march=rv32i_zicsr` performs that job during assembly.

### `ENTRY(_start)`

Records `_start` as the default ELF entry symbol. It does not set the hardware
PC. The processor reset logic still determines the first fetch address.

### `MEMORY { ... }`

Describes the address range available to the linker:

```ld
IMEM (rx) : ORIGIN = 0x00000000, LENGTH = 1K
```

- `IMEM` is the region name.
- `r` marks the region as readable.
- `x` marks the region as executable.
- `ORIGIN` is the first byte address.
- `LENGTH` is 1024 bytes.

The RTL instruction memory contains 256 words, and each word is four bytes:

```text
256 words * 4 bytes = 1024 bytes
```

The `MEMORY` block does not create RAM. It only gives the linker an address
range and a size limit.

### `SECTIONS { ... }`

Defines how input sections are combined into output sections.

```ld
.text ORIGIN(IMEM) : ALIGN(4)
```

Creates the output `.text` section at the first byte of `IMEM`, currently
`0x00000000`, with four-byte alignment.

```ld
KEEP(*(.text.start))
```

Collects every input section named `.text.start`. The `*` matches any input
object file. `KEEP` prevents the startup section from being removed if section
garbage collection is enabled later.

```ld
*(.text .text.*)
```

Collects ordinary `.text` sections and named subsections such as `.text.main`.

```ld
} > IMEM
```

Places the output section in the `IMEM` region. The linker reports an overflow
if the linked image exceeds the region.

### Trap Section

```ld
.trap ALIGN(4) :
{
    KEEP(*(.trap .trap.*))
} > IMEM
```

Places `.trap` at the next four-byte-aligned address after `.text`. The trap
handler address is therefore determined by the final size of the linked
program instead of a fixed partition. Startup code obtains that address from
the `trap_handler` symbol and writes it to `mtvec`:

```asm
la   t0, trap_handler
csrw mtvec, t0
```

This compact layout avoids limiting ordinary program text to the first 256
bytes of the 1 KiB instruction memory.

### `ASSERT(...)`

```ld
ASSERT(ADDR(.trap) + SIZEOF(.trap) <= ORIGIN(IMEM) + LENGTH(IMEM),
       "instruction image exceeds IMEM")
```

Checks that the end of `.trap`, which follows `.text`, remains inside `IMEM`.
The linker stops with the provided message if the complete executable image
exceeds 1024 bytes.

## Related Notes

- [`ld.md`](ld.md): linker command-line options and map files.
- [`objcopy.md`](objcopy.md): conversion from ELF to the Verilog memory image.
