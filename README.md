# RISC Pipeline

This repository is a learning-first RV32I processor project. The goal is not
to collect features as quickly as possible. It is to build a five-stage CPU
whose datapath, control rules, verification evidence, and design trade-offs
are clear enough to explain and defend.

The current RTL implements a five-stage `IF`/`ID`/`EX`/`MEM`/`WB` pipeline with
forwarding, load-use stalls, EX-stage redirects, a basic Machine Mode CSR and
precise-trap path, and one machine-timer interrupt source. The Phase 3
verification baseline and the project's minimum Phase 4 milestone are in
place. Phase 5, SoC integration and FPGA bring-up, is the next main step.

This is still a focused teaching core, not a complete RV32I or privileged
architecture implementation.

## What Works Today

- A five-stage in-order pipeline with four explicit pipeline registers
- Integer ALU and ALU-immediate operations
- All six base branch conditions, `jal`, `jalr`, `lui`, and `auipc`
- Byte, halfword, and word loads and stores in the internal memory model
- MEM/WB-to-EX forwarding, CSR-result forwarding, and load-use stalls
- Branch, jump, `mret`, and trap redirects with pipeline flushing
- The six base Zicsr read/modify/write forms used by this project
- `ecall`, `ebreak`, `mret`, and selected precise synchronous exceptions
- A one-shot machine-timer interrupt through MMIO-programmable `mtimecmp`
- Seven module tests and ten processor smoke tests in one directed regression
- A lightweight path for selected upstream `rv32ui` tests

The exact CSR, trap, and timer boundary is documented in
[`docs/csr-trap-design.md`](docs/csr-trap-design.md). Known limitations are
listed in [Architecture](docs/core-architecture.md#7-current-boundary-and-known-limitations).

## Quick Start

Run the complete directed regression:

```bash
bash sim/run_regression.sh
```

Run the selected upstream ISA-lite tests:

```bash
bash sim/run_isa_lite.sh
```

Run one ISA-lite test:

```bash
bash sim/run_isa_lite.sh ori
```

The scripts expect Verilator and a RISC-V GNU toolchain with the
`riscv64-elf-*` prefix. See [`sim/README.md`](sim/README.md) for the operational
entry point and [`docs/verification.md`](docs/verification.md) for what the
tests do and do not prove.

## Repository Map

| Path | Purpose |
| --- | --- |
| `rtl/core/` | CPU core, pipeline registers, hazard logic, CSR/trap logic, internal memories, and timer path |
| `tb/` | Directed SystemVerilog module and processor testbenches |
| `programs/` | Hand-written assembly smoke programs and instruction images |
| `sim/` | Build and test runners |
| `software/` | Linker script, minimal runtime, ISA-lite environment, and build helpers |
| `docs/` | Architecture, design rationale, verification notes, tool notes, and backlog |
| `docs/plans/` | Phase-by-phase roadmap and exit criteria |
| `tools/` | External tool or test-suite checkouts that are not owned by this repository |

## Documentation

- [Core architecture](docs/core-architecture.md)
- [Verification strategy and evidence](docs/verification.md)
- [CSR, exceptions, and machine-timer design](docs/csr-trap-design.md)
- [Data-memory addressing notes](docs/data-memory-addressing.md)
- [Phased implementation plan](docs/plans/README.md)
- [Deferred ideas](docs/backlog.md)
- [Tool-chain notes](docs/tool-chain-notes/)

`agent_context.md` and `AGENTS.md` are collaboration files for Codex and other
agents. They summarize the current working boundary, but the RTL and the
registered regression remain authoritative when documentation drifts.

## Project Direction

The next dependency-ordered path is:

1. Freeze the CPU-to-SoC request/response contract.
2. Integrate the minimal SoC and bring it up on the NEXYS Artix-7 board.
3. Establish a system-level software and verification baseline.
4. Add Cache, FPU, and RTOS support only after that baseline is stable.

Future ideas that are worth keeping but are not active work belong in
[`docs/backlog.md`](docs/backlog.md).
