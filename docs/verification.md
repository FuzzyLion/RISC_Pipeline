# Verification

This document is the long-term home for the project's verification strategy,
evidence, and known gaps. The Phase 3 baseline is established, and the directed
regression now also covers the minimum Phase 4 CSR, precise-trap, and one-shot
machine-timer path. It should continue to grow through Phase 6 and later
extensions.

The goal is not to present a green regression as proof of complete RISC-V
compliance. It is to keep one clear baseline that catches datapath, control,
hazard, trap, and program-level integration bugs as the system grows.

## Current Scope

The current core is a five-stage RV32I-style pipeline with directed support for
integer ALU operations, ALU-immediate operations, branches, jumps, loads,
stores, forwarding, load-use stalls, and EX-stage redirects. It also implements
a focused Machine Mode path with six base CSR forms, `ecall`, `ebreak`, `mret`,
selected precise synchronous exceptions, and one machine-timer interrupt.

This system support is deliberately narrow. The regression does not prove full
RV32I coverage, privileged-architecture compliance, nested traps, a general
ABI-safe runtime, software or external interrupts, or periodic timer behavior.

Verification has two layers:

- Module-level Verilator tests check focused combinational or local sequential behavior: decode control, immediate generation, ALU operations, register-file semantics, data-memory byte lanes, branch-target generation, and hazard control.
- Program-level smoke and ISA-lite tests run real instruction streams through the integrated pipeline and check their architectural effects.

The two layers are intentionally complementary. Module tests are better at localizing a broken control signal or datapath rule. Program-level tests are better at finding integration bugs in forwarding, pipeline-register fields, redirect flushing, writeback selection, and instruction-to-instruction interactions.

## Current Directed Baseline

`sim/run_regression.sh` registers nineteen tests:

- Seven module tests for control decode, immediate generation, ALU behavior,
  PC-target generation, the register file, data memory, and hazard control
- Twelve processor smoke tests for basic execution, branch flushing, hazards,
  ALU/branch behavior, mixed CSR and synchronous traps, four directed precise
  exception cases, unsupported CSR access and synchronous-exception priority,
  and one-shot machine-timer delivery

The four precise-exception smokes cover illegal instruction,
instruction-address misalignment, load-address misalignment, and store-address
misalignment. They check trap metadata, younger-instruction flushing, and a
cause-specific suppressed side effect. The timer smoke checks MMIO programming
of `mtimecmp`, interrupt-enable gating, cause 7 delivery, precise flushing,
handler acknowledgement, and `mret` recovery.

`core_smoke_unsupported_csr_trap_tb.sv` runs a legal `CSRRW` encoding targeting
the unsupported CSR address `0x7c0`, with interrupts enabled and no timer
request. `core_smoke_sync_exception_timer_priority_tb.sv` separately tests the
collision using a real timer deadline of 80, programmed through MMIO. Its
program waits for `mip.MTIP` with global interrupts disabled, enables
`mie.MTIE`, then places the global-MIE enable immediately before the faulting
CSR instruction. In the current EX-stage CSR implementation, MIE becomes 1
as that instruction enters EX. A rising-edge monitor requires an observed
valid unsupported access with MTIP, MTIE, and MIE all set at trap acceptance;
it also records pending-before-enable. Neither test forces internal signals.

Both cases require illegal-instruction cause 2, the faulting PC in `mepc`, the
instruction bits in `mtval`, trap redirect and D/E/M flushing, preserved `rd`,
an older committed marker, a flushed younger marker, and the fatal-handler
signature. The collision case checks selected and latched metadata, proving
that this synchronous exception wins over an enabled pending timer interrupt.
The timer remains pending and its deadline unchanged in the fatal synchronous
handler. This scheduling depends on the current EX-stage CSR update timing;
other CSR forms and other synchronous-exception/timer combinations remain
outside these two cases. The separate timer smoke covers timer-handler
acknowledgement and `mret` recovery.

These are directed proofs of selected behavior. They are not exhaustive tests
of every instruction encoding, CSR access, alignment case, or older in-flight
side effect.

## How to Run the Baseline

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

The ISA-lite runner builds each selected upstream `rv32ui` test through `software/scripts/build_riscv_lite_test.sh`, extracts the instruction words into `sim/build/riscv_lite/hex/`, loads the resulting `.hex` file into instruction memory, and uses `tb/core_isa_lite_tb.sv` to watch `x31` for pass/fail completion.

## Directed Testbench Style

Directed SystemVerilog unit tests should favor readability over compact
parameterization. Keep one instruction or one behavior per task. The preferred
task shape is:

```systemverilog
task automatic test_example_instr();
    apply_instr_defaults();

    instr_D = 32'hXXXXXXXX; // assembly instruction
    #1;

    check_ctrl_bundle("example control bundle", EXPECTED_CTRL);
    check_imm_src("example immediate source", EXPECTED_IMM);
endtask
```

Keep reusable assertion/check tasks at the bottom of the testbench, but avoid
hiding instruction stimulus inside generic parameterized execution helpers.
The test body should show the reset/default step, direct inputs, propagation
delay, and checks explicitly.

## Directory Roles

`programs/` contains the local hand-written processor-level test programs. Files such as `programs/smoke_alu.s` and `programs/smoke_branch.s` capture stable test intent and belong to this project. Their matching `.hex` images are the instruction-memory inputs used by the smoke testbenches.

`sim/build/programs/` contains build output. Scripts such as `sim/build_hex.sh` take files from `programs/` and generate temporary `.elf`, `.dump`, and preprocessed assembly files under `sim/build/programs/`. These files are useful for debugging and disassembly, but they can be deleted and regenerated at any time.

The selected upstream `riscv-tests` flow follows the same rule: the external source lives under the ignored `tools/riscv-tests/` tree, the local adaptation is tracked under `software/tests/riscv_lite/`, and generated `.elf`, `.dump`, and `.hex` files stay under the ignored `sim/build/riscv_lite/` directory.

## riscv-tests Integration

The upstream `riscv-tests` repository lives under `tools/riscv-tests/` and should remain unchanged. This project provides a lightweight local environment in `software/tests/riscv_lite/env/riscv_test.h`.

The official test sources expect environment macros such as
`RVTEST_CODE_BEGIN`, `RVTEST_PASS`, `RVTEST_FAIL`, and `TESTNUM`. The official
environment normally relies on a broader privileged and host-reporting contract,
including CSR setup, trap vectors, `ecall`, and `tohost`. The current core has a
basic CSR/trap path, but it does not implement that complete environment
contract.

The local environment keeps the same macro names but uses a different completion protocol:

- `x31 = 1` means the test passed.
- `x31 = 2` means the test failed before a numbered test case was available.
- Odd values greater than 1 encode the failing test number as `(x31 - 1) / 2`.

This keeps the ISA-lite tests independent of privileged behavior and lets them
focus on the integer pipeline. It also means that this is not a full upstream
`riscv-tests` integration.

`TESTNUM` is an ordinary architectural register, not protected testbench state. In this environment, it is defined as `gp`, or `x3`. Each upstream `TEST_*` macro writes the current test number into `x3` before running its instruction sequence, and the shared failure path encodes the current `x3` value into `x31`.

This convention works only if both the test body and the CPU preserve `x3` until the failure path reads it. The upstream integer macros are written with that rule in mind and normally avoid using `x3` as a test destination. If a custom test writes `x3`, or a CPU bug writes to the wrong destination register and corrupts `x3`, the decoded failure number may be misleading. An impossible or suspicious test number is therefore evidence that `TESTNUM` itself may have been clobbered.

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

The current `.hex` files initialize instruction memory only. This flow does not load ELF data sections into data memory, which is the main reason load/store-heavy upstream tests are not part of the default ISA-lite set yet.

## Tests Included by Default

The default ISA-lite list should include only cases that meet all of these conditions:

- The test builds with the local `riscv_lite` environment.
- The generated instruction image fits in the current 256-word instruction memory.
- The test does not require initialized data memory or depend on the official
  privileged pass/fail environment.
- The test has been run and observed passing on the current pipeline.

The current safe category covers integer ALU and ALU-immediate operations,
branches, jumps, `lui`, and `auipc`. Official load/store tests should wait until
the flow can initialize data memory from ELF sections or an explicit
data-memory image. The core has directed misaligned-access trap tests, but the
official misalignment cases should wait until the ISA-lite environment can
support their complete trap contract. `fence_i` should wait until
instruction-cache coherence becomes meaningful.

## Instruction Memory Limit

`rtl/memory/instr_mem.sv` currently holds 256 instruction words. If an upstream test expands beyond 256 instructions, the flow should reject it instead of silently truncating it.

This is a testbench capacity issue, not an ISA correctness issue. Truncation can remove part of the control flow, including pass/fail paths, later test cases, or branch targets. The program could then pass for the wrong reason, fail in a misleading way, or jump into uninitialized memory.

The right fix is either to increase instruction-memory capacity intentionally or to write a smaller local program that checks the same behavior.

## Debugging an ISA-Lite Failure

If a command such as this fails:

```bash
bash sim/run_isa_lite.sh ori
```

do not immediately assume that ORI decode or the ALU is broken. An integrated ISA test can fail because of decode, immediate generation, ALU operation, forwarding, branch behavior, writeback, instruction-memory setup, or the lightweight test environment.

Use this order:

1. Read the failure code from `x31`. If it is an odd value greater than 1, calculate the failing test number with `(x31 - 1) / 2`.
2. Open the generated dump under `sim/build/riscv_lite/` and the upstream source under `tools/riscv-tests/isa/rv32ui/`.
3. Find the small source macro or instruction sequence that matches the failing test number.
4. Reduce that sequence to the smallest local smoke program that still fails.
5. Decide which layer could own the failure:
   - If an isolated `ori` produces the wrong value with stable operands, check `control_unit`, `imm_ext`, `alu_op`, and writeback selection.
   - If the operation fails only when a source register was written by one of the previous two instructions, suspect forwarding or load-use stall behavior.
   - If `bne` or another branch controls the expected failure path, check branch comparison, branch-target generation, and redirect flushing.
   - If `x31` never changes and the test times out, check program loading, reset/PC behavior, jump loops, and whether the generated program exceeded instruction-memory capacity.
   - If the decoded test number is impossible, unexpected, or points to the wrong source block, check whether the program or a writeback-destination bug overwrote `x3`/`TESTNUM`.
   - If the official source expects data memory, traps, CSR behavior, or `ecall`, classify the result as a test-environment mismatch rather than a core-execution bug.
6. After fixing the issue, run both the focused test and the full regression.

The dump identifies the failing instruction stream, not the root cause by itself. Find the root cause by reducing the sequence and matching the symptom to the smallest module or integration boundary that can explain it.

## Issues Encountered During Integration

The upstream environment could not be used directly because it assumes a
privileged trap and host-reporting contract that this project does not fully
implement. The lightweight environment was introduced during Phase 3 so the
integer pipeline could report pass or fail using ordinary RV32I instructions.

The `rv32ui` tests are often wrappers around shared `rv64ui` bodies. This is normal upstream organization, not evidence that the wrong tests were cloned. The macros select RV32 behavior when assembled with `-march=rv32i -mabi=ilp32`.

The project currently extracts only executable instruction words from the ELF dump. That is enough for ALU, branch, and jump tests, but not for official tests that rely on initialized `.data` contents.

Some otherwise useful tests are too large for the current 256-word instruction memory. Skip them until the memory capacity or test program is changed intentionally.

## Baseline Status

Phase 3 is complete as a focused verification milestone: the project has
module tests, program-level pipeline smokes, a unified directed runner, and a
lightweight path for selected upstream RV32UI tests. The minimum Phase 4
CSR/trap/timer path now extends that same baseline with directed system tests.

A passing run supports those specific claims only. It does not establish full
ISA or privileged compliance, and skipped upstream tests still need an explicit
reason.

## Next Verification Work

The next useful improvements are:

- Add a data-memory image flow so official load/store tests can run without hand-written setup code.
- Increase instruction-memory capacity intentionally or make it configurable per testbench.
- Add smaller local R-type ALU programs for upstream cases that are currently too large.
- Broaden unsupported-CSR coverage beyond CSRRW and extend precise-exception side-effect and synchronous-exception/timer collision coverage.
- Add periodic-timer tests only when readable `mtime` access and next-deadline software exist.
- Keep module tests focused and readable when a program-level failure exposes a new local bug.
- Introduce Cocotb only when verification starts to need randomized memory latency, broad test matrices, reference models, or Cache-specific golden-memory checking.
