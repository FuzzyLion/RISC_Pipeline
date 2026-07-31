# Phase 9: RTOS and Final System Integration

## Time Limit

Recommended: 1.5 to 3 weeks
Hard limit: 4 weeks

## Goal

Once the main pipeline, Cache, and FPU are integrated, complete the final system bring-up and verify that the processor can support higher-level software.

## Detailed Tasks

### Task 1: Prepare the RTOS Runtime Requirements

1. Freeze the memory layout required by the RTOS.
2. Confirm that the Timer, UART, interrupt entry, and context-switch paths work.

### Task 2: Complete the Minimum RTOS Bring-up

1. Run a basic tick interrupt.
2. Run a minimal task-scheduling example.
3. Verify serial output and the exception-handling path.

### Task 3: Complete Full-System Regression

1. Regress integer programs, system-level programs, Cache-related programs, and floating-point programs.
2. Compare simulation and board behavior.
3. Record the final known limitations and open issues.

## Deliverables

1. RTOS bring-up notes
2. Full-system regression report
3. Final issue list and recommended next steps

## Verification Requirements

1. The minimum RTOS example runs reliably.
2. System-level regression remains repeatable after Cache and FPU integration.
3. Board and simulation results have no major unexplained differences.

## Risks and Notes

1. This phase will expose unresolved boundary problems from every earlier phase.
2. If the RTOS does not boot, localize the problem by layer: interrupts, memory, Cache, FPU, or context switching.
3. Do not assume one module is responsible for an RTOS failure without evidence.

## Exit Conditions

1. Final integration of the project's main capabilities is complete.
2. The RTOS bring-up result is clear.
3. Cache and FPU have both been verified through the complete system path.
