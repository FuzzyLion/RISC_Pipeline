# Phase 6: System-Level Validation and Software Baseline

## Time Limit

Recommended: 1 to 1.5 weeks
Hard limit: 2 weeks

## Goal

Once the CPU, CSR path, and minimal SoC are stable, establish a system-level software baseline. This gives us one known-good version before Cache and FPU integration begins.

## Detailed Tasks

### Task 1: Expand Standard-Test Coverage

1. Expand `riscv-tests` coverage.
2. Track the pass rate and classify the reasons for failure.

### Task 2: Establish a Software Baseline

1. Freeze a set of stable C and assembly programs.
2. Freeze the compiler flags, linker scripts, and image-conversion flow.

### Task 3: Establish a System-Level Regression Entry Point

1. Bring reproducible simulation and board tests into one regression flow.
2. Record differences between board and simulation behavior.

## Deliverables

1. Standard-test pass-rate report
2. List of system-level baseline programs
3. Frozen build and run scripts
4. Failure-classification table

## Verification Requirements

1. The `riscv-tests` pass rate is traceable.
2. Baseline programs run repeatably in both simulation and on the board.
3. Cache and FPU integration can be compared directly against this regression baseline.

## Risks and Notes

1. If the baseline is unstable, later Cache and FPU failures will be much harder to localize.
2. This phase is about freezing the baseline, not continuing to add features freely.

## Exit Conditions

1. The current system capabilities form a stable baseline.
2. A reusable system-level regression entry point exists.
3. The project is ready for the Cache phase.

## Understanding Check

Use these questions during phase review, grounded in the actual implementation
and verification evidence. Select the most relevant gaps; do not repeat answers
already demonstrated in the conversation.

1. Which tests form your "known good" system baseline?
2. Why is that baseline strong enough before introducing Cache and FPU?
3. Which remaining failures are acceptable, and which are blocking?
4. How do you compare simulation behavior with board behavior?
5. What metrics tell you the project is stable enough for major extensions?
