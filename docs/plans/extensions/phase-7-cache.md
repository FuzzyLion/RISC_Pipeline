# Phase 7: Cache Design and Integration

## Time Limit

Recommended: 2 to 3 weeks
Hard limit: 4 weeks

## Goal

Complete the project's required Cache milestone and make sure it works cleanly with the existing pipeline, handshake-based memory interface, and SoC access path.

## Recommended Scope

For the first version, prioritize:

1. A data Cache
2. Whichever is easier to verify: direct-mapped or 2-way set-associative
3. One practical write policy, such as write-through or a clearly designed write-back approach

If time and complexity allow, then consider adding an instruction Cache.

## Detailed Tasks

### Task 1: Freeze the Cache Specification

1. Decide whether to start with only a data Cache or build an I-Cache at the same time.
2. Choose the capacity, line size, associativity, and write policy.
3. Define the hit, miss, and refill behavior.

### Task 2: Define the Cache Interfaces to the CPU and SoC

1. Keep the same handshake interface on the CPU-facing side.
2. Define how the Cache accesses main memory or an external-memory controller downstream.
3. Define how a miss stalls the pipeline.

### Task 3: Implement the Cache Datapath and Control

1. Implement the tag, data, valid, dirty, and related arrays.
2. Implement hit detection.
3. Implement the miss-handling state machine.
4. Implement refill, writeback, or write-through control.

### Task 4: Integrate the Cache with the Pipeline and SoC

1. Connect the Cache to the MEM path.
2. Make sure `memory_wait` holds the pipeline correctly on a miss.
3. Make sure bypassing, flushes, and exceptions do not break Cache-state consistency.

### Task 5: Complete Focused Verification

1. Write focused tests for hits, misses, conflicts, replacement, and the selected write policy.
2. Compare system-level regression behavior before and after Cache integration.
3. Verify program stability with the Cache enabled on the board.

## Deliverables

1. Cache specification
2. Cache RTL
3. Miss/refill state-machine notes
4. Focused Cache test suite
5. Post-integration system regression report

## Verification Requirements

1. Hits return the correct result without unnecessary stalls.
2. Misses hold the pipeline correctly and resume after refill.
3. Write behavior matches the documented policy.
4. The existing system-level baseline programs still pass after Cache integration.

## Risks and Notes

1. Cache integration is where a simple pipeline controller can turn into a complex system state machine.
2. If the miss state machine is unclear, bugs will be difficult to see and localize.
3. Use the Phase 6 system baseline for regression comparison throughout this phase.

## Exit Conditions

1. The Cache is functionally complete and stable.
2. The original system regression shows no unexplained regressions.
3. The project is ready for the FPU phase.

## Understanding Check

Use these questions during phase review, grounded in the actual implementation
and verification evidence. Select the most relevant gaps; do not repeat answers
already demonstrated in the conversation.

1. Why did you choose this Cache organization and write policy?
2. How does a miss propagate back into the pipeline control logic?
3. What prevents Cache control from corrupting architectural state during stalls or flushes?
4. What are the hardest cases to verify in your Cache?
5. If performance improves but correctness becomes unclear, how do you prove the Cache is still right?
