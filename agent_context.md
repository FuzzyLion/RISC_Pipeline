# Agent Context

This file is a short orientation and routing guide. Collaboration and execution
boundaries are in [AGENTS.md](AGENTS.md). Source code and registered test runners
are authoritative; report discrepancies and update documentation only when the
current authorization includes those edits.

## Current Work Entry Point

Start with [README.md](README.md) for the project overview and
[the datapath diagram](docs/Datapath_v1.4.1.svg) for data and control flow. The
[architecture walkthrough](docs/core-architecture.md#datapath-overview) connects
the drawing to pipeline stages and RTL module responsibilities.

RTL sources are grouped by responsibility, with [rtl/filelist.f](rtl/filelist.f)
as the integrated compilation entry point. `rtl/core/core.sv` connects five
independent modules in `rtl/core/stages/` and the Hazard Unit. Each stage owns
its outgoing pipeline register; internal instruction memory is inside IF, and
data memory, MMIO decode, and the timer are inside MEM. Keep implementation
claims tied to the RTL and verification claims tied to the registered runners
and observed results.

## Architecture Baseline and Next Step

The documented baseline is an RV32I-oriented five-stage core with internal
memories, directed verification, and the minimum machine-mode CSR, precise-trap,
and one-shot timer-interrupt milestone. This is not full ISA or privileged
compliance. See [phase status](docs/plans/README.md#phase-list) and
[verification evidence and gaps](docs/verification.md) for maintained details;
a documented result is not a test run in the current session.

The next architecture task is the Phase 5 CPU-to-SoC request/response contract,
including stale fetch-response handling. Preserve existing behavior through a
compatibility adapter and the existing regression before adding peripherals.
Use the [Phase 5 plan](docs/plans/system/phase-5-soc-fpga.md) for its deliverables
and exit criteria. Cache and FPU remain required later milestones, followed by
lightweight RTOS integration; the target board is NEXYS Artix-7.

## Repository Map

| Path | Responsibility |
| --- | --- |
| `rtl/core/` | Core integration and shared types; `stages/`, `pipeline/`, `datapath/`, `control/`, and `csr/` subdirectories |
| `rtl/memory/` | Internal instruction and data memories |
| `rtl/peripherals/` | Machine timer |
| `rtl/soc/` | Top-level wrapper, MMIO decoder, system address map |
| `rtl/filelist.f` | Integrated RTL compilation list; packages precede their users |
| `tb/` | Directed module and processor testbenches |
| `programs/` | Local assembly sources in `asm/`; instruction images in `hex/` |
| `sim/` | Test and build runners; generated output in ignored `sim/build/` |
| `software/` | Linker script, minimal trap runtime, ISA-lite environment, build scripts |
| `docs/` | Datapath diagram, architecture, verification, rationale, tool notes, backlog |
| `docs/plans/` | Roadmap, phase deliverables, exit criteria, understanding checks |
| `tools/` | External reference checkouts; not project-owned source |

## Choose the Relevant Reference

| Task | Reference |
| --- | --- |
| Public overview and quick start | [README.md](README.md) |
| Pipeline, stage ownership, control and memory behavior | [Datapath diagram](docs/Datapath_v1.4.1.svg); [stage boundaries](docs/core-architecture.md#stage-module-boundaries); inspect `rtl/core/core.sv`, `rtl/core/stages/`, and `rtl/core/core_types_pkg.sv` |
| CSR state, precise traps, timer delivery, redirect ownership | [CSR/trap design](docs/csr-trap-design.md) |
| Test strategy, ISA-lite completion protocol, evidence and gaps | [Verification](docs/verification.md) |
| Running tests and generated-file layout | [Simulation commands](sim/README.md) |
| Goals, phase status and understanding checks | [Plans](docs/plans/README.md) |
| Tool-specific usage | [Tool-chain notes](docs/tool-chain-notes/) |
| Deferred ideas | [Backlog](docs/backlog.md) |

## Important Limits to Check Before Extending the Core

The current design uses internal memories rather than an external memory
handshake. The timer path is one-shot; periodic scheduling, software/external
interrupts, nested traps, and a general ABI-safe handler remain outside the
baseline. ISA-lite has an instruction-memory size limit and does not initialize
data memory from ELF sections. Consult the linked design and verification
documents and actual RTL before relying on these assumptions or claiming wider
exception, instruction, or system coverage.
