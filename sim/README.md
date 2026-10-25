# Simulation Scripts

This directory contains the build and execution scripts for directed
SystemVerilog tests, processor smoke programs, and the selected ISA-lite test
flow.

## Documentation

Use the following documents as the source of truth for each topic:

- [Project overview and current status](../README.md)
- [Core architecture](../docs/core-architecture.md)
- [Verification strategy and test boundaries](../docs/verification.md)
- [GCC notes](../docs/tool-chain-notes/gcc.md)
- [GNU ld notes](../docs/tool-chain-notes/ld.md)
- [Linker script notes](../docs/tool-chain-notes/linker.md)
- [objcopy notes](../docs/tool-chain-notes/objcopy.md)
- [objdump notes](../docs/tool-chain-notes/objdump.md)
- [Verilator notes](../docs/tool-chain-notes/verilator.md)
- [ISA-lite test environment](../software/tests/riscv_lite/README.md)

This README is only an operational entry point. Detailed tool options,
verification rationale, failure analysis, and architectural claims belong in
the linked documents.

## Common Commands

Run the complete directed regression:

```bash
bash sim/run_regression.sh
```

Run the selected ISA-lite tests:

```bash
bash sim/run_isa_lite.sh
```

Run one ISA-lite test:

```bash
bash sim/run_isa_lite.sh ori
```

Build one local assembly program:

```bash
bash sim/build_hex.sh \
  programs/asm/smoke_basic.s \
  programs/hex/smoke_basic.hex
```

If the output argument is omitted, `build_hex.sh` writes
`programs/hex/<source-basename>.hex`. Keep local assembly sources in
`programs/asm/`; the shared trap handler remains in `software/runtime/`.

Build an image from multiple assembly sources:

```bash
bash sim/build_hex.sh \
  <primary-source.s> \
  <output.hex> \
  <additional-source.s> ...
```

## Script Groups

| Scripts | Purpose |
| --- | --- |
| `run_control_unit.sh`, `run_imm_ext.sh`, `run_alu_op.sh` | Focused combinational control and datapath tests |
| `run_pc_target_gen.sh`, `run_hazard_unit.sh` | Redirect and hazard-control tests |
| `run_reg_file.sh`, `run_data_mem.sh` | Focused sequential storage tests |
| `run_basic_smoke.sh`, `run_smoke_*.sh` | Integrated processor smoke programs |
| `run_isa_lite.sh` | Selected upstream RV32UI tests |
| `run_regression.sh` | Unified directed regression entry point |

Integrated processor tests compile the RTL through
[`rtl/filelist.f`](../rtl/filelist.f), whose paths are relative to the repository
root. Module tests list only the packages and modules they need. When moving a
source file, update both the RTL filelist and any direct module-test references.

## Program Build Flow

`build_hex.sh` converts local assembly sources into an instruction-memory
image:

```text
assembly sources
  -> RISC-V GCC, assembler, and linker
  -> ELF
  -> dump and map reports
  -> objcopy Verilog hex
  -> $readmemh
  -> instr_mem
```

The local build uses [`software/linker/core.ld`](../software/linker/core.ld) to
place `.text` at byte address `0x00000000` and `.trap` at the next aligned
address after `.text`. See the linker, `ld`, `objcopy`, and `objdump` notes
above for the details of this flow.

## Generated Files

Instruction images are grouped under `programs/hex/`; intermediate compiler
and simulator output stays under the ignored `sim/build/` directory:

| Path | Contents |
| --- | --- |
| `programs/asm/` | Local hand-written assembly sources |
| `programs/hex/` | Local program instruction images |
| `programs/hex/riscv_lite/` | Generated upstream ISA-lite instruction images, ignored by Git |
| `sim/build/programs/` | Preprocessed assembly, ELF, dump, and map files for local programs |
| `sim/build/<test>/obj_dir/` | Verilator-generated C++ and simulation executables |
| `sim/build/riscv_lite/` | ISA-lite ELF, dump, and Verilator output |

HEX images and intermediate output can be regenerated from the assembly
sources. Edit assembly sources, not generated instruction images. The local
HEX images remain tracked; ISA-lite images and intermediate output are ignored.

## Build-Path Boundary

The repository currently has two related but separate program build paths:

- `sim/build_hex.sh` builds local smoke and Phase 4 trap programs. It uses the
  project linker script and preserves non-contiguous `.text` and `.trap`
  addresses.
- `software/scripts/build_riscv_lite_test.sh` builds the selected ISA-lite
  tests introduced in Phase 3. It currently handles a continuous executable instruction
  stream and does not load trap or data sections.

Changes to one build path do not automatically apply to the other.
