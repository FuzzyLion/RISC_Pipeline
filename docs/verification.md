# Phase 3 Verification Notes

This document records the current Phase 3 verification flow for the RV32I
pipeline core. The goal of this phase is not to prove that the processor is a
complete RISC-V implementation. The goal is to build a clear baseline that can
catch common datapath, control, hazard, and program-level integration bugs
before adding CSR, exceptions, interrupts, SoC integration, cache, and FPU
support.

## Current Scope

The current core implements a five-stage RV32I-style pipeline with directed
support for integer ALU operations, ALU-immediate operations, branches, jumps,
loads, stores, forwarding, load-use stalls, and EX-stage redirects. System
instructions, CSR behavior, exceptions, interrupts, instruction-cache
coherence, and architectural trap handling are intentionally outside the Phase
3 boundary.

Verification is split into two layers:

- Module-level Verilator tests check focused combinational or local sequential
  behavior such as decode control, immediate generation, ALU operation,
  register file semantics, data-memory byte lanes, branch target generation,
  and hazard control.
- Program-level smoke and ISA-lite tests run real instruction streams through
  the integrated pipeline and check architectural effects after the pipeline
  executes them.

These two layers are deliberately complementary. Module tests are better for
localizing a broken control signal or datapath rule. Program-level tests are
better for catching integration bugs such as forwarding, pipeline register
field loss, redirect flushing, writeback selection, and interactions between
multiple instructions.

## How To Run The Baseline

Run the directed regression:

```bash
bash sim/run_regression.sh
```

Run the selected upstream RV32UI ISA-lite tests:

```bash
bash sim/run_isa_lite.sh
```

Run one ISA-lite test by name:

```bash
bash sim/run_isa_lite.sh ori
```

The current ISA-lite runner builds each selected upstream `rv32ui` test through
`software/scripts/build_riscv_lite_test.sh`, extracts the instruction words into
`sim/build/riscv_lite/hex/`, loads that `.hex` file into instruction memory,
and uses `tb/core_isa_lite_tb.sv` to watch `x31` for pass/fail completion.

## Directory Roles

`programs/` is the source directory for local hand-written processor-level test
programs. Files such as `programs/smoke_alu.s` and `programs/smoke_branch.s`
express stable test intent and are part of this project. Their matching `.hex`
images are the instruction-memory inputs used by the smoke testbenches.

`sim/build/programs/` is build output. Scripts such as
`sim/build_hex.sh` use files from `programs/` as input and generate temporary
`.elf`, `.dump`, and preprocessed assembly files under `sim/build/programs/`.
Those files are useful for debugging and disassembly, but they can be deleted
and regenerated at any time.

The selected upstream `riscv-tests` flow follows the same rule: the external
source lives under ignored `tools/riscv-tests/`, the local adaptation lives
under tracked `software/tests/riscv_lite/`, and generated `.elf`, `.dump`, and
`.hex` files live under ignored `sim/build/riscv_lite/`.

## riscv-tests Integration

The upstream `riscv-tests` repository is kept under `tools/riscv-tests/` and
should stay unchanged. The project provides a lightweight local environment in
`software/tests/riscv_lite/env/riscv_test.h`.

The official test sources expect environment macros such as
`RVTEST_CODE_BEGIN`, `RVTEST_PASS`, `RVTEST_FAIL`, and `TESTNUM`. The official
environment normally depends on privileged features that this core does not
implement yet, including CSR setup, trap vectors, `ecall`, and `tohost`.

The local environment keeps the same macro names but changes the completion
protocol:

- `x31 = 1` means the test passed.
- `x31 = 2` means the test failed before a numbered test case was available.
- Odd values greater than 1 encode the failing test number as
  `(x31 - 1) / 2`.

This is why the ISA-lite tests can run on the current user-level core without
CSR or exception support. It also means this is not a full upstream
`riscv-tests` integration yet.

`TESTNUM` is a normal architectural register, not protected testbench state.
In this environment it is defined as `gp`, which is `x3`. Each upstream
`TEST_*` macro writes the current test number into `x3` before running its
instruction sequence, and the shared failure path encodes the current `x3`
value into `x31`.

This convention works only if the test body and the CPU both preserve `x3`
until the failure path reads it. The upstream integer macros are written with
that convention in mind and normally avoid using `x3` as a test destination.
However, if a custom test writes `x3`, or if a CPU bug accidentally writes the
wrong destination register and corrupts `x3`, the decoded failing test number
may be misleading. In that case, an impossible or suspicious test number should
be treated as evidence that `TESTNUM` itself may have been clobbered.

## Build Flow

The ISA-lite flow is:

```text
upstream rv32ui/*.S
  + local riscv_lite/riscv_test.h
  + upstream scalar macros
  -> riscv64-elf-gcc / assembler / linker
  -> ELF file
  -> riscv64-elf-objdump
  -> awk extracts instruction words
  -> sim/build/riscv_lite/hex/*.hex
  -> $readmemh initializes instr_mem
  -> pipeline executes program
  -> x31 reports pass or fail
```

The current `.hex` files initialize instruction memory only. Data sections in
the ELF are not loaded into data memory by this flow. That is the main reason
load/store-heavy upstream tests are not part of the default ISA-lite set yet.

## Tests Included By Default

The default ISA-lite list should only include cases that satisfy all of these
conditions:

- The test builds with the local `riscv_lite` environment.
- The generated instruction image fits in the current 256-word instruction
  memory.
- The test does not require initialized data memory, CSR behavior, `ecall`,
  traps, or privileged execution.
- The test has been run and observed passing on the current pipeline.

The current safe category is integer ALU, ALU-immediate, branches, jumps, `lui`,
and `auipc`. Load/store official tests should wait until the test flow can load
data memory from ELF sections or an explicit data-memory image. Misaligned
access tests should wait until architectural exception handling exists.
`fence_i` should wait until instruction-cache coherence is meaningful.

## Instruction Memory Limit

`rtl/core/instr_mem.sv` currently holds 256 instruction words. If an upstream
test expands to more than 256 instructions, the current flow should reject it
instead of silently truncating it.

This is a testbench capacity issue, not an ISA correctness issue. Truncating a
program would remove part of the control flow, including possible pass/fail
paths, later test cases, or branch targets. A truncated program could pass for
the wrong reason, fail in a misleading way, or jump into uninitialized memory.

The right fixes are either to intentionally increase instruction-memory
capacity or to write a smaller local program that covers the same behavior.

## Debugging An ISA-lite Failure

If a command such as this fails:

```bash
bash sim/run_isa_lite.sh ori
```

do not assume immediately that the failing module is the ORI decode or the ALU.
An integrated ISA test can fail because of decode, immediate generation, ALU
operation, forwarding, branch behavior, writeback, instruction memory setup, or
the lightweight test environment.

Use this order:

1. Read the failure code from `x31`. If it is an odd value greater than 1,
   compute the failing test number with `(x31 - 1) / 2`.
2. Open the generated dump under `sim/build/riscv_lite/` and the upstream source
   under `tools/riscv-tests/isa/rv32ui/`.
3. Find the small source macro or instruction sequence that corresponds to the
   failing test number.
4. Reduce that sequence into the smallest local smoke program that still
   fails.
5. Decide which layer should own the failure:
   - If a single isolated `ori` computes the wrong value with stable operands,
     check `control_unit`, `imm_ext`, `alu_op`, and writeback selection.
   - If the operation only fails when its source register was written by the
     previous one or two instructions, suspect forwarding or load-use stall
     behavior.
   - If the expected failure path is controlled by `bne` or another branch,
     check branch comparison, branch target generation, and redirect flushing.
   - If `x31` never changes and the test times out, check program loading,
     reset/PC behavior, jump loops, and whether the generated program exceeded
     instruction-memory capacity.
   - If the decoded test number is impossible, unexpected, or points to the
     wrong source block, check whether `x3`/`TESTNUM` was overwritten by the
     program or by a writeback destination bug.
   - If the official source expects data memory, traps, CSR behavior, or
     `ecall`, classify it as a test-environment mismatch rather than a core
     execution bug.
6. After fixing the issue, run both the focused test and the full regression.

The important point is that the dump identifies the failing instruction stream,
not the root cause by itself. The root cause comes from reducing the failing
sequence and then matching the symptom to the smallest module or integration
boundary that can explain it.

## Issues Encountered During Integration

The upstream environment could not be used directly because it assumes CSR,
trap, `ecall`, and `tohost` support. A lightweight environment was needed so
the current Phase 3 core can report pass/fail using only normal RV32I
instructions.

The `rv32ui` tests are often wrappers around shared `rv64ui` bodies. This is
normal upstream structure, not a sign that the wrong tests were cloned. The
macros select RV32 behavior when assembled with `-march=rv32i -mabi=ilp32`.

The project currently extracts only executable instruction words from the ELF
dump. This is enough for ALU, branch, and jump tests, but it is not enough for
official tests that depend on initialized `.data` contents.

Some otherwise useful tests are too large for the current 256-word instruction
memory. Those should be skipped until the memory capacity or test program is
changed intentionally.

## Phase 3 Status

Phase 3 can be considered complete as a baseline verification milestone when
the directed regression and the selected ISA-lite tests both pass, and when the
remaining skipped upstream tests have clear reasons for being skipped.

This should be described as a focused Phase 3 verification baseline, not as
full ISA compliance. The honest claim is that the project now has module-level
tests, program-level pipeline smoke tests, and a lightweight path for running a
selected subset of upstream RV32UI tests on the current core.

## Next Verification Work

The next useful improvements are:

- Add a data-memory image flow so official load/store tests can run without
  hand-written setup code.
- Increase instruction-memory capacity intentionally or make it configurable
  per testbench.
- Add smaller local R-type ALU programs for upstream cases that are currently
  too large.
- Keep module tests focused and readable when a program-level failure exposes a
  new local bug.
- Introduce Cocotb only when the verification problem starts to need randomized
  memory latency, broad test matrices, reference models, or cache-specific
  golden-memory checking.
