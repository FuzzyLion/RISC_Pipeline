# Phase 8: FPU Design and Integration

## Time Limit

Recommended: 2 to 4 weeks
Hard limit: 5 weeks

## Goal

Complete the project's required FPU milestone and integrate the floating-point execution path cleanly into the existing processor architecture.

## Recommended Scope

The first version should aim to be implementable and verifiable instead of trying to cover too many floating-point features at once.

Decide early:

1. Which floating-point instructions the first version supports
2. Whether the FPU is single-cycle, multi-cycle, or internally pipelined
3. How it shares the Execute and Writeback stages with the integer pipeline

## Detailed Tasks

### Task 1: Freeze the FPU Specification

1. Choose the floating-point instruction subset for the first version.
2. Define the supported rounding modes, exception flags, and CSR interactions.
3. Choose the FPU latency model.

### Task 2: Define the FPU Integration Model

1. Decide whether the FPU is an EX-stage coprocessor or a separate pipeline.
2. Define how floating-point results are written back.
3. Define how FPU busy state stalls the main pipeline.

### Task 3: Implement the Floating-Point Datapath and Control

1. Implement the required floating-point registers or a shared-register strategy.
2. Implement the floating-point execution core.
3. Implement decode and result-selection paths.
4. Implement exception, flag, or status-register updates.

### Task 4: Integrate with the Main Pipeline

1. Handle stalls from multi-cycle FPU operations.
2. Handle conflicts between floating-point and integer writeback.
3. Define how exceptions, flushes, and redirects affect in-flight FPU operations.

### Task 5: Complete Focused Verification

1. Write focused floating-point instruction tests.
2. Add regression cases where integer and floating-point paths are both active.
3. Check that adding the FPU does not change existing system behavior.

## Deliverables

1. FPU specification
2. FPU RTL
3. Floating-point control and writeback notes
4. Focused FPU test suite
5. Post-integration regression report

## Verification Requirements

1. Supported floating-point instructions produce correct results.
2. FPU busy and stall behavior is correct.
3. Floating-point writeback does not break the integer path.
4. The existing integer baseline programs still pass after FPU integration.

## Risks and Notes

1. The hard part of an FPU is often not the arithmetic itself, but its coupling to the main pipeline.
2. A multi-cycle or pipelined FPU increases control complexity quickly.
3. If the relationship between exceptions, flushes, and FPU busy state is unclear, later debugging will be painful.

## Exit Conditions

1. The FPU is designed, integrated, and covered by focused verification.
2. The integer and floating-point paths run together reliably.
3. The project is ready for RTOS and final system integration.
