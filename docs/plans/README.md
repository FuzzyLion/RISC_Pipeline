# Phased Implementation Plan

This directory contains the detailed plan for each phase of the project. It is both the phase index and the main entry point for project planning.

## What This Project Needs to Become Before It Is Internship-Ready

The real value of this project is not simply being able to say, “I built a CPU.” What matters is whether you can explain the design clearly, show how you verified it, and defend the tradeoffs you made.

If you want to use this as your main internship project, aim for the standard below.

### Non-Negotiable Requirements

1. You can explain the full architecture clearly in 3 to 5 minutes: `RV32I`, the five-stage pipeline, `branch` resolution in `EX`, the current internal-memory timing, and the main Hazard Unit strategy. Explain the planned Phase 5 request/response interface separately from implemented behavior.
2. You can use your own implementation to explain how one instruction moves from `IF` to `WB`.
3. You can explain what forwarding, stall, and flush each solve.
4. You have a structured verification flow, not just waveforms that “look about right.”
5. You can walk through at least 2 real bugs that you found and debugged yourself.
6. You can explain why the first version focuses on a solid in-order pipeline instead of adding out-of-order execution, register renaming, or a predictor.

### Features That Would Make the Project Stand Out

1. Passing a meaningful set of basic `riscv-tests`
2. Closing a minimal CSR, exception, and interrupt loop
3. Completing a minimal SoC integration
4. Running the design on a NEXYS Artix-7 board
5. Successfully adding a Cache later
6. Successfully adding an FPU later

### Things That Look Impressive but Add Little Real Value

1. Using lots of advanced terms without being able to explain the control logic or timing
2. Having code without tests or regression
3. Running a few cases without understanding why they work
4. Adding a predictor, register renaming, or a complex bus too early and losing the main thread of the project

## Recommended Project Path

1. First, make `phase 1` through `phase 3` solid.
2. Then close the system loop through `phase 4` to `phase 6`.
3. Finally, move on to Cache, FPU, and RTOS work.

In other words, the real foundation of the project is:

1. The five-stage pipeline itself
2. The Hazard Unit and control priorities
3. A complete verification loop

These three areas are what give the project its real technical weight.

## Phase List

Status labels describe the current repository, not the final ambition of each
phase. A completed minimum milestone may still have follow-up work documented
inside its phase file.

### Foundation

1. [Phase 0: First-Version Architecture Boundary](foundation/phase-0-architecture-boundary.md) — completed baseline
2. [Phase 1 Preparation Sheet](foundation/phase-1-preparation-sheet.md) — completed baseline

The longer Phase 0 learning review now lives in
[`docs/notes/phase-0-review.md`](../notes/phase-0-review.md). It is useful
history, but it is not an implementation plan.

### Core Bring-up

1. [Phase 1: Five-Stage Pipeline Core](core/phase-1-pipeline-core.md) — completed baseline
2. [Phase 2: Hazard Unit and Control Closure](core/phase-2-hazard-control.md) — completed baseline
3. [Phase 3: Structured Verification Environment](core/phase-3-verification.md) — completed baseline

### System Bring-up

1. [Phase 4: CSR, Exceptions, and Interrupts](system/phase-4-csr-exception-interrupt.md) — minimum milestone complete
2. [Phase 5: SoC Integration and FPGA Bring-up](system/phase-5-soc-fpga.md) — next main phase
3. [Phase 6: System-Level Validation and Software Baseline](system/phase-6-system-validation.md) — planned

### Extensions

1. [Phase 7: Cache Design and Integration](extensions/phase-7-cache.md) — planned
2. [Phase 8: FPU Design and Integration](extensions/phase-8-fpu.md) — planned
3. [Phase 9: RTOS and Final System Integration](extensions/phase-9-rtos-final-integration.md) — planned

## Current Project-Wide Principles

1. The first version is limited to `RV32I`.
2. In the first version, branches are resolved in `EX`.
3. Phase 5 must replace the current fixed-latency internal-memory assumption
   with a minimal request/response interface before SoC and Cache integration.
4. `riscv-tests` should be introduced during Phases 2 and 3.
5. Cache and FPU are required milestones, but they should be added in phases after the main pipeline is stable.
6. Verification and implementation must move forward together.

## Standard Deliverables for Every Phase

1. Phase goal
2. Time limit
3. Implemented modules or completed design work
4. Tests that were run
5. Open issues or risks
6. Entry conditions for the next phase

## Project Completion Standard

The project reaches its intended complete baseline when:

1. The five-stage RV32I core, Hazard Unit, and control priorities are stable
   under repeatable regression.
2. CSR access, precise traps, return, and at least one interrupt source form a
   tested Machine Mode loop.
3. A minimal SoC with UART and Timer runs in simulation and on the NEXYS
   Artix-7 board.
4. A known-good system software and verification baseline exists before major
   extensions are added.
5. Cache and FPU integration preserve the established integer and system
   regression.
6. The final hardware and runtime provide a clear, tested path to lightweight
   RTOS bring-up.

## Suggested Documentation Roles

The planning documents in this project roughly divide responsibilities as follows:

1. [`README.md`](../../README.md)
   This is the public project entry point. It owns the short project summary,
   current milestone, quick-start commands, and top-level documentation links.
2. [`core-architecture.md`](../core-architecture.md)
   This is the reader-facing overview of the implemented core.
3. [`docs/plans/README.md`](README.md)
   This is the planning homepage. It owns the overview, phase entry points, project-wide principles, and project goals.
4. [`phase-0-architecture-boundary.md`](foundation/phase-0-architecture-boundary.md)
   This document freezes the architecture boundary for the first version.
5. [`phase-1-preparation-sheet.md`](foundation/phase-1-preparation-sheet.md)
   This document turns the minimum Phase 1 instruction subset, decode table, pipeline-register fields, and control-action semantics into an executable starting draft.
6. The individual phase documents
   These own the execution plan, deliverables, verification points, exit conditions, and understanding checks for each phase.
