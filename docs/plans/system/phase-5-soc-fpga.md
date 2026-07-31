# Phase 5: SoC Integration and FPGA Bring-up

## Time Limit

Recommended: 1.5 to 2.5 weeks
Hard limit: 3 weeks

## Goal

Move the CPU from “a core that works in simulation” to “a minimal system that can run a program on the board.”

## Detailed Tasks

### Task 1: Build the SoC Top Level

1. Design the minimum SoC top level.
2. Define one shared address map.

### Task 2: Add the Basic Peripherals

1. Integrate ROM, RAM, UART, and Timer.
2. Connect the CPU's handshake interfaces to SoC memory and peripherals.

### Task 3: Prepare the Board-Level Project

1. Prepare the Vivado project, constraints, and board-level clock and reset handling.
2. Add a minimal observable debug path, such as serial output or LED status.

### Task 4: Complete the First Bring-up

1. Run a minimal program on the board.
2. Record the board behavior, serial output, and known issues.

## Design Questions

1. How does a slow peripheral feed a stall back to the CPU?
2. How do peripheral and main-memory addresses fit into one address map?
3. During board bring-up, how do we quickly tell whether a problem belongs to the CPU, SoC integration, or a peripheral?

## Deliverables

1. SoC top-level RTL
2. Address-map document
3. FPGA project and constraints
4. Board bring-up notes
5. Peripheral-handshake integration notes

## Verification Requirements

1. A SoC-level program runs successfully in simulation.
2. The FPGA runs a minimal program and produces observable output.
3. Slow peripherals do not break pipeline control.

## Risks and Notes

1. Many problems will appear here for the first time as system-integration issues rather than CPU-internal logic bugs.
2. Slow UART and Timer behavior must fit the handshake-based stall mechanism.
3. Do not fold Cache integration into this phase.

## Exit Conditions

1. The minimal system runs on the board.
2. Key peripherals such as UART and Timer work.
3. The project is ready for system-level testing and the software baseline.
