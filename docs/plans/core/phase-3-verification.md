# Phase 3: Structured Verification Environment

## Time Limit

Recommended: 1 to 2 weeks
Hard limit: 2 weeks

## Goal

Move from “we can debug it until it works” to repeatable regression, so every change can reveal problems quickly.

## Detailed Tasks

### Task 1: Establish Module-Level Verification

1. Write module-level testbenches for the ALU, register file, controller, and Hazard Unit.

### Task 2: Establish Processor-Level Verification

1. Build a program-level test framework for the CPU top level.
2. Standardize the program build, image conversion, simulation, and result-checking flow.

### Task 3: Build Batch Regression

1. Add the `riscv-tests` cases that fit the current implementation.
2. Create a failure log and a clear way to classify defects.
3. Add one script as the unified regression entry point.

### Task 4: Evaluate Additional Verification Tools

1. Decide whether Cocotb is worth introducing.
2. Decide how Icarus Verilog and Verilator should divide responsibilities.

## Deliverables

1. Module-level test suite
2. Top-level program test suite
3. Regression scripts
4. `riscv-tests` integration notes
5. Defect tracker
6. Verification-tool decision

## Verification Requirements

1. The basic regression can run with one command.
2. A failure can be narrowed down quickly to a module or phase.
3. New features do not make the verification flow noticeably less efficient.

## Risks and Notes

1. Do not chase test count alone. Failures must still be easy to localize.
2. The regression framework needs to be solid before Cache and FPU work begins.
3. If Cocotb is added later, keep the directory layout and regression entry point stable.

## Exit Conditions

1. The basic regression runs with one command.
2. Failures can be localized quickly.
3. The project is ready for CSR, system-level work, and later extensions.

## Understanding Check

Use these questions during phase review, grounded in the actual implementation
and verification evidence. Select the most relevant gaps; do not repeat answers
already demonstrated in the conversation.

1. How do you know your tests are checking behavior rather than just reproducing implementation details?
2. Which bugs are easiest to catch with module tests, and which need program-level tests?
3. How are `riscv-tests` integrated into your flow?
4. If a regression appears, how do you localize it quickly?
5. What would make you introduce Cocotb, and what would you use it for first?
