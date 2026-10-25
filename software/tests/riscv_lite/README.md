# riscv_lite Test Environment

This directory contains the local test environment introduced in Phase 3 to
adapt selected `riscv-tests` user-level RV32I programs to this core.

The official `riscv-tests` environment assumes a broader privileged and
host-reporting contract built around CSR setup, trap vectors, `ecall`, and
`tohost`. The core now has a basic CSR and trap path, but it does not implement
that complete contract. The lightweight environment keeps the macro names
expected by the test sources while expanding them into plain RV32I code that
does not depend on privileged behavior.

## Directory Roles

- `tools/riscv-tests/` is the upstream reference repository. Keep it unchanged.
- `software/tests/riscv_lite/env/riscv_test.h` is this project's lightweight
  replacement for the official physical test environment.
- `software/scripts/build_riscv_lite_test.sh` compiles a selected official
  `.S` file into the `.hex` instruction-memory format used by the current
  Verilator tests.
- `sim/build/riscv_lite/` stores generated `.elf`, `.dump`, and simulator output.
- `programs/asm/` stores local hand-written programs; `programs/hex/` stores
  their instruction images. Upstream instruction images are generated under
  `programs/hex/riscv_lite/`. These upstream images and the intermediate output
  under `sim/build/` are intentionally not committed.

To prepare the ignored upstream dependency, run this from the repository root:

```bash
git clone --recurse-submodules https://github.com/riscv-software-src/riscv-tests.git tools/riscv-tests
```

## Macro Contract

The official test body includes `riscv_test.h` and expects these names:

- `RVTEST_RV32U` selects a user-level RV32 test environment.
- `RVTEST_CODE_BEGIN` emits the `_start` entry point and startup code.
- `RVTEST_CODE_END` marks the end of the test code.
- `TESTNUM` names the register that holds the current test case number.
- `RVTEST_PASS` reports success.
- `RVTEST_FAIL` reports failure.
- `RVTEST_DATA_BEGIN` and `RVTEST_DATA_END` delimit test data.

For this core, pass/fail is reported through `x31`:

- `x31 = 1` means pass.
- `x31 = 2` means failure before a test number was available.
- Odd values greater than 1 encode a failing test number as `(x31 - 1) / 2`.

## Why The Directives Exist

The assembler directives are layout instructions for the assembler and linker.
They are not CPU instructions.

- `.section .text` puts following instructions in the code section.
- `.section .data` puts following values in the data section.
- `.align 2` aligns the next label to a 4-byte boundary.
- `.globl _start` makes `_start` visible to the linker as the program entry.
- Labels such as `_start:` and `begin_signature:` name addresses.

The current instruction-memory flow extracts executable instructions from the
ELF dump into a `.hex` file. Because data memory is not initialized from ELF
sections yet, start with RV32I tests that do not require initialized `.data`.

## Current Runner

Run:

```bash
bash sim/run_isa_lite.sh
```

This builds each selected upstream source, writes instruction images under
`programs/hex/riscv_lite/` and intermediate output under
`sim/build/riscv_lite/`, and runs the program on the current core. The default
set is limited to tests that have been observed passing and do not require
initialized data memory, CSR behavior, traps, or privileged execution.

You can also run a subset by name:

```bash
bash sim/run_isa_lite.sh addi beq
```

The legacy single-test wrapper still works:

```bash
bash sim/run_isa_lite_addi.sh
```

## Why Some rv32ui Tests Are Skipped For Now

Start with tests whose behavior fits the ISA-lite environment: integer ALU,
compares, branches, jumps, x0, and bypassing. These tests mainly
exercise instruction decode, ALU behavior, forwarding, branch redirects, and
writeback.

Defer the load/store-oriented official cases such as `lb`, `lh`, `lw`, `sb`,
`sh`, `sw`, `st_ld`, `ld_st`, and `ma_data` until the test flow can initialize
data memory from ELF sections or a separate data-memory image. The current
`.hex` flow extracts only executable instruction words for instruction memory.

Defer `fence_i` because it has architectural meaning for instruction-cache
coherence, which is outside the current core. The core now has directed
misaligned-access trap tests, but upstream cases that depend on the official
privileged trap environment should wait until that environment contract is
supported.

Some otherwise relevant ALU tests are also temporarily too large for the
current instruction memory. For example, the official `rv32ui/add.S` expands to
more than the current 256 instruction words. That is a testbench capacity
limit, not an ISA reason to avoid R-type tests. Add those cases after either
increasing instruction memory capacity intentionally or creating smaller local
programs for the same behavior.
