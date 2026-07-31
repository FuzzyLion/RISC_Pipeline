# Phase 4: CSR, Exceptions, and Interrupts

## Time Limit

Recommended: 1 to 1.5 weeks
Hard limit: 2 weeks

## Goal

Close the minimum Machine Mode loop and lay the groundwork for system software and later RTOS support.

## Detailed Tasks

### Task 1: Freeze the Minimum CSR Set

1. Finalize the minimum CSR list for the first version.

### Task 2: Implement the Trap Flow

1. Implement trap entry for exceptions.
2. Implement the exception-return path.
3. Handle at least instruction-address misalignment and address misalignment for the currently supported load/store range. Detection should raise a shared trap request and trigger pipeline flush and redirect. The memory array must not silently repair the address.

### Task 3: Implement the Key CSRs

1. Implement the required CSRs, including `mstatus`, `mtvec`, `mepc`, and `mcause`.

### Task 4: Add an Interrupt Source

1. Add at least one interrupt source, preferably a timer interrupt first.

### Task 5: Integrate Traps with Pipeline Control

1. Flush and redirect the pipeline correctly on exceptions and interrupts.
2. Define the priority between exceptions, interrupts, and ordinary redirects.

## Design Questions

1. How should exception and interrupt priorities be defined?
2. Which pipeline stages need to be flushed when a trap occurs?
3. How should CSR writes, PC redirects, and hazard control work together?

## Deliverables

1. CSR module
2. Trap and return design notes
3. Exception and interrupt test programs
4. Key waveform and behavior records
5. Priority table

## Verification Requirements

1. CSR state is written correctly on exception entry.
2. Interrupt entry and return behave correctly.
3. Pipeline state remains consistent and explainable when an exception or interrupt occurs.

## Risks and Notes

1. The most likely failure in this phase is getting the state update right while leaving part of the pipeline unflushed.
2. Be especially careful when an interrupt and a memory wait happen together.
3. Later RTOS bring-up depends heavily on the quality of this phase.

## Exit Conditions

1. The minimum privileged-mode loop is complete.
2. Key prerequisites such as timer interrupts are available.
3. The project is ready for SoC integration.
