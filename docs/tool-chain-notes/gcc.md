# GCC Notes

## Role in This Project

`riscv64-elf-gcc` is used as a driver for the RISC-V assembler and linker. The
current project builds assembly programs directly; GCC is not compiling C code
in this flow.

```text
Assembly source
  -> GCC driver
  -> assembler
  -> linker
  -> ELF executable
```

GCC does not simulate the processor and does not generate the final Verilog
memory image.

## Current Command Shape

The local smoke build uses the following options:

```bash
riscv64-elf-gcc \
  -march=rv32i_zicsr \
  -mabi=ilp32 \
  -nostdlib \
  -nostartfiles \
  -Wl,-T,"$LINKER_SCRIPT" \
  -Wl,-e,"$ENTRY_POINT" \
  -Wl,-Map,"$MAP_FILE" \
  -Wl,--no-relax \
  -o "$ELF_FILE" \
  "${PREPROCESSED_FILES[@]}"
```

## Options Used

### `-march=rv32i_zicsr`

Allows RV32I instructions and the CSR instruction subset. The toolchain rejects
instructions such as `csrw` when `zicsr` is not enabled.

### `-mabi=ilp32`

Selects the 32-bit integer ABI used by RV32 programs.

### `-nostdlib`

Prevents the standard C library from being linked. The processor does not yet
provide the runtime environment expected by that library.

### `-nostartfiles`

Prevents GCC from adding its default startup files. This project provides its
own `_start` code.

### `-Wl,...`

Passes options to the linker. For example:

```text
-Wl,-T,software/linker/core.ld
```

means that GCC passes `-T software/linker/core.ld` to `ld`.

### `-o <file>`

Sets the output ELF filename.

## ISA-Lite Differences

The ISA-lite script additionally uses:

```bash
-x assembler-with-cpp
-I<include-directory>
```

`-x assembler-with-cpp` runs the C preprocessor before assembly. `-I` adds
directories that contain test macros and local environment headers.

## Inputs and Output

```text
Input:  .s or .S assembly sources
Output: .elf executable
```

The ELF is inspected with `objdump` and converted to a memory image with
`objcopy`.
