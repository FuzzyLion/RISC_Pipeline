# Simulation and Program Build Guide

This directory contains the scripts used to build RISC-V programs and run the
SystemVerilog verification environment. This guide explains how the scripts,
toolchain, generated files, and RTL simulation fit together.

Project-wide verification scope and test strategy are documented in
[`docs/verification.md`](../docs/verification.md). This document focuses on the
local build and simulation workflow under `sim/`.

## Workflow Overview

```text
RISC-V assembly source (.s)
    |
    | sim/build_hex.sh
    v
Preprocessed assembly (.preprocessed.s)
    |
    | riscv64-elf-gcc drives the assembler and linker
    v
ELF executable (.elf)
    |                         |
    | riscv64-elf-objdump     | linker -Map
    v                         v
Disassembly (.dump)          Link map (.map)
    |
    | riscv64-elf-objcopy -O verilog
    v
Instruction-memory image (.hex)
    |
    | SystemVerilog $readmemh
    v
instr_mem
    |
    | Verilator compiles RTL and the testbench
    v
Native simulation executable
```

Each tool has a separate responsibility:

- GCC coordinates assembly and linking.
- The linker assigns final addresses to code and symbols.
- `objdump` produces a human-readable disassembly.
- `objcopy` converts the ELF image into a memory initialization format.
- Verilator compiles the RTL and testbench into a native simulation program.

## Common Commands

Run the complete directed regression:

```bash
bash sim/run_regression.sh
```

Build a single-file smoke program:

```bash
bash sim/build_hex.sh \
  programs/smoke_basic.s \
  programs/smoke_basic.hex
```

Link startup code, a program, and a trap handler into one image:

```bash
bash sim/build_hex.sh \
  <startup.s> \
  <output.hex> \
  <main.s> \
  <trap_handler.s>
```

The command-line format is:

```text
build_hex.sh <primary-source.s> [output.hex] [additional-source.s ...]
```

The primary source name is also used for generated ELF, dump, and map filenames
under `sim/build/programs/`.

## Program Build Script

[`build_hex.sh`](build_hex.sh) performs the following steps:

1. Checks that the input files and required RISC-V tools are available.
2. Removes the `//` end-of-line comments used by local assembly programs.
3. Detects whether the input sources define an `_start` symbol.
4. Invokes GCC, the assembler, and the linker to create an ELF executable.
5. Uses `objdump` to create a readable disassembly.
6. Uses `objcopy` to create a Verilog hex file that preserves section addresses.

When `_start:` is defined, the ELF entry point is `_start`. Legacy smoke
programs without `_start` continue to use address zero as their entry point.

The ELF entry point does not set the hardware PC. The processor reset logic
still starts execution at PC `0`, so startup code must be linked at address
`0x00000000`.

## GCC and Linker Options

The build script uses `riscv64-elf-gcc` as a driver for the assembler and
linker. The important options are:

| Option | Purpose |
| --- | --- |
| `-march=rv32i_zicsr` | Enables RV32I instructions and the CSR instruction subset |
| `-mabi=ilp32` | Selects the 32-bit integer ABI |
| `-nostdlib` | Prevents linking the standard C library |
| `-nostartfiles` | Prevents linking toolchain-provided startup code |
| `-Wl,...` | Passes the following option to the linker |
| `-Wl,--no-relax` | Prevents linker relaxation from rewriting instruction sequences |

This is a bare-metal processor environment. It does not provide an operating
system, standard C runtime, or the memory layout expected by a hosted program.

The following options configure the linker:

```bash
-Wl,-T,"$LINKER_SCRIPT"
-Wl,-e,"$ENTRY_POINT"
-Wl,-Map,"$MAP_FILE"
```

| Linker option | Purpose | Changes section placement |
| --- | --- | --- |
| `-T core.ld` | Uses the project linker script | Yes |
| `-e _start` | Records the ELF entry symbol | No |
| `-Map file.map` | Writes a link-layout report | No |

## Linker Script and Memory Layout

The local linker script is
[`software/linker/core.ld`](../software/linker/core.ld). It defines the
instruction-memory region and places executable sections at fixed byte
addresses.

An assembly directive such as:

```asm
.section .trap, "ax", @progbits
```

creates an input section. The linker script collects matching input sections
into an output section:

```ld
.trap 0x00000100 : ALIGN(4)
{
    KEEP(*(.trap .trap.*))
} > IMEM
```

The current instruction-memory layout is:

```text
0x00000000  .text, including _start
0x00000100  .trap, including trap_handler
0x000003FF  Last byte of the 1 KiB instruction memory
```

The linker assertion that limits `.text` to `0x100` bytes prevents normal code
from overlapping the trap handler.

## Generated Files

| File | Primary consumer | Contents |
| --- | --- | --- |
| `.elf` | Linker and debug tools | Machine code, sections, addresses, symbols, and entry metadata |
| `.dump` | Developers | Disassembled addresses, machine words, and instructions |
| `.map` | Developers | Section placement, sizes, input files, and symbol addresses |
| `.hex` | `$readmemh` | Instruction words and memory-address markers |

The generated ELF, dump, map, and preprocessed assembly files are written under
`sim/build/programs/`. These files are build artifacts and may be regenerated.

Useful ELF inspection commands include:

```bash
riscv64-elf-readelf -S sim/build/programs/<name>.elf
riscv64-elf-nm -n sim/build/programs/<name>.elf
```

A correctly linked trap image should report values similar to:

```text
.text         0x00000000
_start        0x00000000
.trap         0x00000100
trap_handler  0x00000100
```

## objdump and objcopy

`objdump` is used for inspection. Its output includes addresses, machine words,
and decoded instructions:

```text
00000000: 00000297  auipc x5,0
00000004: 10028293  addi  x5,x5,256
00000100: 30200073  mret
```

`objcopy` is used for format conversion. Verilog output preserves gaps between
sections with address markers:

```text
@00000000
00000297 10028293
@00000040
30200073
```

The CPU uses byte addresses, while `instr_mem` is an array of 32-bit words.
With `--verilog-data-width=4`, the hex address is therefore calculated as:

```text
CPU byte address 0x100 / 4 = hex word address 0x40
```

The previous `objdump + awk` flow extracted machine words but discarded their
addresses. That was sufficient for one continuous `.text` section starting at
zero. It is not sufficient when `.text` and `.trap` are separated by an address
gap.

## Link Map Files

A map file is a linker-generated report. It is not loaded by the processor and
does not affect execution. It is useful for checking:

- Output-section addresses and sizes.
- Which input files contributed each section.
- Final addresses of `_start`, `main`, and `trap_handler`.
- Unexpected growth or overlap between `.text` and `.trap`.

Searching the map file for `.text`, `.trap`, or a symbol name is usually enough
for routine checks.

## Verilator Simulation

`build_hex.sh` creates a program image but does not run the processor. The
`run_*.sh` scripts invoke Verilator:

```text
SystemVerilog RTL + SystemVerilog testbench
    -> Verilator
    -> Native simulation executable
    -> Test execution
```

RISC-V GCC does not simulate RTL, and Verilator does not compile RISC-V
assembly. The two workflows meet when `$readmemh` loads the generated hex file
into `instr_mem`.

Testbench failures should use `$fatal(1, ...)` so the simulation process returns
a nonzero status. Successful tests should terminate with `$finish`.

## Troubleshooting

| Symptom | First checks |
| --- | --- |
| Assembler reports `illegal operands` | Instruction encoding, immediate range, and `-march` |
| Linker reports a section overlap | `core.ld`, section sizes, and the map file |
| `trap_handler` has the wrong address | ELF section table, symbol table, and map file |
| Dump addresses are correct but the CPU jumps incorrectly | Hex address markers, `mtvec_reg`, and the PC mux |
| `$readmemh` loads instructions at the wrong location | `objcopy` format and byte-to-word address conversion |
| Verilator compilation fails | RTL/testbench ports, shared types, and filelists |
| Simulation times out | Reset PC, entry code, control-flow loops, and completion protocol |

For trap and linker debugging, the following sequence provides a focused
checklist:

1. Confirm that `_start` is linked at `0x00000000`.
2. Confirm that `trap_handler` is linked at `0x00000100`.
3. Confirm that the hex file contains `@00000040`.
4. Confirm that startup code writes the handler address to `mtvec`.
5. Confirm that `mtvec_reg` receives `0x00000100` in the RTL simulation.
6. Confirm that trap entry redirects the PC to `mtvec_reg`.

## ISA-Lite Build Path

`software/scripts/build_riscv_lite_test.sh` is a separate build path for the
lightweight Phase 3 `riscv-tests` integration. It currently extracts a
continuous executable instruction stream and does not load `.trap` or data
sections.

`sim/build_hex.sh` is used by local smoke tests and Phase 4 trap programs. It
uses `core.ld` and `objcopy` to preserve `.text` and `.trap` addresses. Updating
one path does not automatically add the same capabilities to the other.
