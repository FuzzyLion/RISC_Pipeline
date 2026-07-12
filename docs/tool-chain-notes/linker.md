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
.text 0x00000000 : ALIGN(4)
```

Creates the output `.text` section at byte address `0x00000000` with four-byte
alignment.

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
.trap 0x00000100 : ALIGN(4)
{
    KEEP(*(.trap .trap.*))
} > IMEM
```

Places the trap handler at byte address `0x100`. Since `instr_mem` stores
32-bit words:

```text
byte address 0x100 / 4 = word index 0x40 = 64
```

The trap handler therefore begins at `mem_instr[64]`.

### `ASSERT(...)`

```ld
ASSERT(SIZEOF(.text) <= 0x100,
       "normal text overlaps trap handler")
```

Requires `.text` to fit below the trap section. The maximum is 256 bytes, or 64
normal 32-bit instructions. The linker stops with the provided message if this
condition is false.

## Related Notes

- [`ld.md`](ld.md): linker command-line options and map files.
- [`objcopy.md`](objcopy.md): conversion from ELF to the Verilog memory image.
