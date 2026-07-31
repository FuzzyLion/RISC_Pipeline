# Agent Context

This repository is a learning-first SystemVerilog RISC-V CPU project. The user
is building it to understand processor architecture deeply and to explain the
design honestly in interviews. Prefer clear ownership, small milestones, and
focused verification over hidden abstractions or feature accumulation.

Read this file as orientation, not as a substitute for the RTL. When it
conflicts with source code or the registered regression, trust the code and
update the documentation.

## Current Milestone

The core is an RV32I-oriented five-stage pipeline with internal instruction and
data memories. The Phase 3 verification baseline is established. The minimum
Phase 4 milestone is also complete: the core has a working Machine Mode CSR and
precise-trap loop plus one one-shot machine-timer interrupt path.

This does not mean the core is a complete RV32I or privileged-architecture
implementation. Software and external interrupts, periodic timer scheduling,
nested traps, a general ABI-safe runtime, external memory handshakes, SoC/FPGA
integration, Cache, FPU, and RTOS support remain outside the current RTL.

Phase 5 is the next main phase. Its first architecture task is to freeze the
CPU-to-SoC request/response contract before adding peripherals or platform
files.

## Repository Map

| Path | Responsibility |
| --- | --- |
| `rtl/core/` | Pipeline datapath, control, hazards, CSR/trap logic, internal memories, and timer MMIO |
| `tb/` | Directed module and processor testbenches |
| `programs/` | Local assembly smoke programs and instruction images |
| `sim/` | Build and test runners; `run_regression.sh` is the directed baseline entry point |
| `software/` | Linker script, minimal trap runtime, ISA-lite environment, and build scripts |
| `docs/` | Reader-facing architecture, verification, design rationale, tool notes, and backlog |
| `docs/plans/` | Phase roadmap, deliverables, and exit criteria |
| `tools/` | External reference checkouts; do not edit upstream sources as project code |

Generated output under `sim/build/` is disposable and should remain ignored.

## Core Architecture

The pipeline stages are `IF`, `ID`, `EX`, `MEM`, and `WB`, separated by four
explicit pipeline registers. Packed types and control bundles live in
`rtl/core/core_types_pkg.sv`. `rtl/core/core.sv` owns integration;
`rtl/core/top.sv` is a thin wrapper and future SoC/board handoff point.

Important stage responsibilities:

- `IF`: hold the PC, fetch the instruction, and compute `PC + 4`
- `ID`: decode, read registers, extract fields, and generate the immediate
- `EX`: apply forwarding, execute the ALU, resolve control flow, execute CSR
  operations, classify alignment events, and arbitrate traps
- `MEM`: format stores, decode timer MMIO, access data memory, and format loads
- `WB`: select and commit the architectural register result

Pipeline registers carry `valid` bits. Bubbles and flushes must suppress all
architectural side effects.

See `docs/core-architecture.md` for the reader-facing overview.

## Control and Hazard Invariants

`control_unit.sv` decodes the instruction in ID. Active decode covers the base
integer ALU groups, all six base branches, `lui`, `auipc`, byte/halfword/word
loads and stores, `jal`, `jalr`, the six project-supported Zicsr forms,
`ecall`, `ebreak`, and `mret`. Unsupported encodings report an illegal
instruction event.

Branches, jumps, and `mret` redirect in EX. JALR clears target bit 0 by ISA
definition. Because the core does not implement the C extension, the final
taken target must still be 4-byte aligned.

Both EX operands can forward from MEM ALU results, MEM CSR results, or WB.
MEM-stage load data is not available soon enough for direct forwarding to the
next EX consumer, so a valid load-use dependency stalls Fetch and Decode and
inserts an Execute bubble.

The control priority is:

```text
accepted trap
  -> taken branch, jump, or mret
  -> load-use stall
  -> normal flow
```

Do not change this priority casually. A focused test must accompany any change
to the ownership or ordering of stalls, flushes, redirects, or memory waits.

## CSR and Trap Ownership

Keep the current responsibility split:

| Block | Owns |
| --- | --- |
| `control_unit.sv` | CSR/system decode and illegal-encoding detection |
| `pc_target_gen.sv` | Branch/jump target calculation and instruction-target misalignment detection |
| `alu_op.sv` | Integer execution, effective addresses, and load/store misalignment detection |
| `trap_ctrl.sv` | Trap priority, metadata, acceptance, and trap flush requests |
| `csr_file.sv` | Persistent CSR state, CSR semantics, trap-entry updates, and `mret` updates |
| `pc_mux.sv` | Sequential, normal redirect, `mret`, and trap-entry PC selection |
| `hazard_unit.sv` and pipeline registers | Turning redirect/trap decisions into stalls, flushes, and bubbles |

The implemented CSR state is `mstatus`, `mie`, `mtvec`, `mscratch`, `mepc`,
`mcause`, `mtval`, and `mip`. `mip.MTIP` is a read-only view of the hardware
timer request. `mtvec` is effectively Direct mode only.

The synchronous trap priority is illegal instruction or unsupported CSR,
Machine Mode `ecall`, `ebreak`, instruction-address misalignment,
load-address misalignment, then store-address misalignment. Every implemented
synchronous exception wins over the machine-timer interrupt.

The precise boundary is the current EX instruction. Older work in MEM may
complete once; the current EX instruction is prevented from entering MEM; and
younger instructions are flushed. A timer interrupt saves the squashed EX
instruction's PC so `mret` can re-execute it.

See `docs/csr-trap-design.md` for the detailed rationale.

## Memory and Reset Semantics

The internal instruction and data memories are word arrays with byte-addressed
CPU inputs. `data_mem.sv` has combinational reads and synchronous byte-lane
writes. `store_data.sv` prepares write data and strobes; `load_data.sv`
extracts and extends subword loads.

CPU reset must not clear the main data-memory array. Memory initialization,
CPU architectural reset, and future Cache invalidation are separate concepts.
A future Cache should normally reset metadata such as valid bits rather than
clear every data-array bit. Write-back dirty behavior must be defined before a
Cache reset or flush policy is implemented.

The current MMIO decoder reserves two aligned full-word stores for the low and
high halves of `mtimecmp` and prevents those writes from aliasing into data RAM.
Timer MMIO reads and partial writes are not implemented.

## Verification Baseline

Use Verilator with directed SystemVerilog testbenches as the default flow.
Run:

```bash
bash sim/run_regression.sh
```

The runner currently registers seventeen tests: seven module tests and ten
processor smokes. The processor tests include the mixed CSR/trap path, four
directed precise-exception cases, and the one-shot timer interrupt.

Selected upstream RV32UI tests use the lightweight local environment and the
`x31` completion contract:

- `x31 = 1`: pass
- `x31 = 2`: failure without a numbered case
- odd `x31 > 1`: failure number `(x31 - 1) / 2`

`TESTNUM` is `gp`/`x3`. A suspicious decoded test number may mean the program
or a CPU writeback bug clobbered `x3`.

Keep module-test claims inside the tested module boundary. Use `$fatal(1, ...)`
for failures and `$finish` only for success. Directed test tasks should show
their stimulus and checks plainly.

Do not introduce Cocotb just because the phase number changes. It becomes
useful when randomized latency, broad parameter matrices, differential testing,
or a Cache golden-memory model creates a real advantage.

See `docs/verification.md` for test evidence, ISA-lite limits, and debugging
workflow. `sim/README.md` owns only the commands and generated-file layout.

## Known Gaps

- Full RV32I and privileged compliance are not proven.
- Byte and halfword memory behavior has focused unit coverage but limited
  program-level coverage.
- Unsupported CSR access still lacks matching processor-level proof.
- Precise-exception tests cover selected cases, not every older in-flight side
  effect.
- The trap handler is a teaching runtime, not ABI-safe, reentrant, or nested.
- ISA-lite does not initialize data memory from ELF sections.
- Instruction memory is currently limited to 256 words.
- The timer handler acknowledges one fixed deadline; it does not schedule
  repeated ticks.
- The core has no external request/response memory interface yet.

## Next Work

1. Freeze instruction and data request/response semantics, including stale
   fetch-response handling.
2. Preserve the zero-wait behavior with a compatibility adapter while changing
   the interface boundary.
3. Keep the seventeen-test regression green through Phase 5 refactoring.
4. Add SoC peripherals and platform files only after the CPU boundary is clear.
5. Add unsupported-CSR and broader precise-side-effect tests when returning to
   Phase 4 coverage work.

## Documentation Ownership

- `README.md`: public project entry point and current high-level status
- `docs/core-architecture.md`: reader-facing whole-core architecture
- `docs/csr-trap-design.md`: CSR, exception, and interrupt rationale
- `docs/verification.md`: verification strategy, evidence, and gaps
- `sim/README.md`: operational test commands
- `docs/tool-chain-notes/`: tool-specific explanations
- `docs/plans/README.md`: project goals, completion standard, roadmap, and phase status
- `docs/backlog.md`: deferred ideas outside the active scope
