# Phase 0: First-Version Architecture Boundary

## Time Limit

Recommended: 3 to 5 days
Hard limit: 1 week

## Goal

Before writing a large amount of RTL, freeze the first version's feature scope, module boundaries, key control policies, and interface semantics. This should prevent broad rework later when Hazard control, CSR, Cache, and FPU are added.

## Implementation Status

This document records the original architecture target. The current baseline
through the minimum Phase 4 milestone uses internal instruction and data
memories. The request/response ports and variable-latency holds described below
are deferred to Phase 5. Read the
[current architecture](../../core-architecture.md) for implemented behavior.

## Principles for Freezing the Design

1. Keep the architecture target separate from the Phase 1 bring-up subset.
2. Freeze only the decisions that could cause major rework later. Detailed RTL belongs in later phases.
3. Assume every memory access may have variable latency. Do not design the interface around an “always returns in one cycle” assumption.
4. The first core is a single-issue, in-order, five-stage pipeline that retires instructions in program order.

## Decisions Frozen in This Phase

1. The first architecture target is a five-stage `RV32I` pipeline, while the Phase 1 bring-up subset may be smaller than full `RV32I`.
2. Final `branch` and `jump` decisions are made in `EX`.
3. The Phase 5 target is a minimal request/response interface for both instruction and data ports, with at most one outstanding request per port. The current baseline still uses internal memories.
4. The first version does not implement `M`, `F`, Cache, FPU, branch prediction, out-of-order execution, or register renaming.
5. The first version only needs to support a minimal Machine Mode loop later. This phase freezes the interfaces and control boundaries without implementing the full CSR path early.
6. The target board is the NEXYS Artix-7. Board clocking, reset, constraints,
   and peripherals stay outside the CPU core boundary.

## 1. ISA and Feature Boundary

### 1.1 Architecture Target

The main target for the first CPU is full `RV32I`. This does not mean every instruction must be implemented in Phase 1. It gives the control paths, pipeline-register fields, and verification plan one stable boundary from the start.

### 1.2 Recommended Phase 1 Bring-up Subset

The first working instruction subset should include at least:

1. Arithmetic and logic: `add`, `sub`, `addi`, `or`
2. Memory access: `lw`, `sw`
3. Control flow: `beq`, `jal`, `jalr`
4. Constant construction: add `lui` early; add `auipc` as soon as the software needs it

This split works well because:

1. `addi` is essential for small test programs and constant construction. Relying only on `add/sub/or` makes even simple programs awkward.
2. `lui` and `auipc` are not difficult, but they directly affect address construction and software usability.
3. `beq + jal/jalr` is enough to close the first control-flow loop. The remaining comparison branches can follow later.

### 1.3 Explicitly Deferred from the First Version

1. Extensions such as `M`, `F`, `A`, and `C`
2. Branch prediction
3. Out-of-order execution
4. Register renaming
5. Byte and halfword loads and stores in the first phase
6. Misaligned-access support

### 1.4 A Note on `lb/lh/lbu/lhu`

These instructions are not simply “the same as `lw`, only with a different `ImmExt` width.”

They add real work:

1. Selecting the byte or halfword within a word from the low address bits
2. Sign-extending or zero-extending returned data
3. Generating finer-grained `wstrb` values
4. Deciding whether to support misaligned accesses or raise an exception

Phase 1 can reasonably support only `lw/sw`, but the documentation must describe `lb/lh` and the other byte and halfword accesses as intentionally deferred, not as something that appears automatically once `lw` works.

## 2. Microarchitecture Boundary and Module Split

### 2.1 CPU Shape

The first core uses:

1. Five stages: IF, ID, EX, MEM, and WB
2. Single issue
3. In-order execution
4. In-order retirement
5. A stable integer pipeline first, followed by exceptions and interrupts, Cache, and FPU in later phases

### 2.2 Stages and Pipeline Registers Are Different Things

`if_stage/id_stage/ex_stage/...` are the functional logic of each stage. They are not the pipeline registers themselves.

Model the pipeline registers separately:

1. `if_id`
2. `id_ex`
3. `ex_mem`
4. `mem_wb`

This separation gives us:

1. A clearer boundary between combinational stage logic and cross-stage sequential state
2. Cleaner stall and flush behavior
3. More readable waveforms and a design that is easier to explain in an interview

### 2.3 Recommended Top-Level Module Responsibilities

1. `pc`
   Stores the current PC, selects the next PC, and handles hold and update control.
2. `if_stage`
   Sends instruction requests, tracks an outstanding request, accepts instruction responses, and discards stale responses after a redirect.
3. `id_stage`
   Decodes instructions, reads the register file, generates immediates, and produces the basic control signals.
4. `ex_stage`
   Performs ALU operations and branch comparisons, calculates jump targets, and produces the final redirect.
5. `mem_stage`
   Generates load/store requests, handles returned data, and controls memory waits.
6. `wb_stage`
   Selects the final writeback value and writes the register file.
7. `regfile`
   Provides the integer register-file read and write ports.
8. `alu`
   Provides the basic arithmetic used by integer operations and comparisons.
9. `controller`
   Turns decoded instructions into a control bundle that moves across stages.
10. `hazard_unit`
    Coordinates forwarding, stalls, flushes, and redirects.

### 2.4 What It Means to Leave Room for Future Interfaces

This phase should reserve architecture boundaries, not fill the RTL with empty placeholder modules.

The recommended approach is:

1. Freeze the future integration points and control relationships for CSR, Cache, and FPU in the documentation.
2. Do not instantiate empty `csr`, `cache`, or `fpu` modules in early RTL just to reserve space.
3. If the signal semantics that will affect future interfaces are clear, Phase 0 has done its job.

## 3. Pipeline Registers and Key Control Paths

### 3.1 Required Fields in Each Pipeline Register

`IF/ID`:

1. `valid`
2. `pc`
3. `instr`

`ID/EX`:

1. `valid`
2. `pc`
3. `rs1_data`
4. `rs2_data`
5. `rs1_idx`
6. `rs2_idx`
7. `rd_idx`
8. `imm`
9. `ctrl_bundle`
10. Optionally keep `instr` as a debug field

`EX/MEM`:

1. `valid`
2. `pc`
3. `alu_result`
4. `store_data`
5. `rd_idx`
6. `ctrl_bundle`

`MEM/WB`:

1. `valid`
2. `pc`
3. `alu_result`
4. `load_data`
5. `rd_idx`
6. `ctrl_bundle`

### 3.2 Recommended `ctrl_bundle` Contents

Include at least:

1. `reg_write`
2. `result_sel`
3. `alu_op`
4. `alu_src`
5. `mem_read`
6. `mem_write`
7. `branch`
8. `jump`
9. `mem_size`, reserved for later extension
10. `load_unsigned`, reserved for later extension

Even if Phase 1 only supports `lw/sw`, adding `mem_size/load_unsigned` to the control definition now reduces later rework when `lb/lh` are added.

### 3.3 Derived Fields

Treat the following as derived values rather than fields that must be stored in every pipeline register:

1. `pc_plus4`
2. Branch-comparison results such as `zero/lt/ltu`
3. The branch target address
4. The `jalr` target after its low bit has been cleared

The rule is simple: if a stage can derive a value reliably from information it already carries, do not add another pipeline-register field just for convenience.

### 3.4 Recommended Control Priority

Do not collapse every wait condition into one vague `memory_wait` signal. At minimum, distinguish:

1. `dmem_wait`
   Comes from an older instruction in `MEM` and usually freezes younger stages.
2. `imem_wait`
   Comes from an instruction-fetch wait in `IF` and mainly affects the front end.

Recommended priority:

1. `reset`
2. `trap_redirect` / `mret_redirect`
3. `dmem_wait`
4. `ex_redirect`
5. `load_use_stall`
6. `imem_wait`
7. Normal progress

The reasoning is:

1. A trap or interrupt is a higher-priority control-flow redirect and must eventually outrank an ordinary branch.
2. `dmem_wait` belongs to an older in-flight instruction, so in-order execution semantics come first.
3. `ex_redirect` should outrank `load_use_stall`, because a wrong-path hazard must not block a real redirect.
4. `imem_wait` only means that a fetch has not returned yet. It must not override a valid redirect already produced in `EX`.

### 3.5 Flush Rules

With branches resolved in `EX`:

1. An ordinary branch or jump redirect must clear at least the younger wrong-path instructions in `IF/ID` and `ID/EX`.
2. Older instructions in `EX/MEM` and `MEM/WB` must not be cleared by an ordinary branch.
3. A future trap or interrupt is also a redirect, but it must do more than update the PC: it must preserve precise-exception behavior and consistent CSR state.

## 4. Frozen Memory Interface

### 4.1 Minimum Required Signals

Keep the current minimal project-wide contract:

1. `req_valid`
2. `req_ready`
3. `req_addr`
4. `req_wdata`
5. `req_wstrb`
6. `resp_valid`
7. `resp_rdata`

### 4.2 Recommended Additional Signals

Consider these in the interface definition from the start:

1. `req_size`
2. `resp_err`

They are not required for the first bring-up, but they reduce rework later when adding `lb/lh`, misalignment exceptions, or peripheral-error handling.

### 4.3 Interface Semantics

1. A request is accepted only when `req_valid && req_ready` is true.
2. Each port allows at most one outstanding request.
3. Responses return in request order; out-of-order responses are not allowed.
4. `req_wstrb == 0` means a read. A nonzero value means a write.
5. For the data port, use `resp_valid` as the shared completion signal for both reads and writes.
6. The first version handles aligned word accesses. Byte and halfword behavior comes later.

### 4.4 Why the Handshake Matters Later

This interface is not about whether today's memory happens to respond in one cycle. It prepares for:

1. Slow peripherals that cannot complete an access in one cycle
2. SoC slaves with different latencies
3. Cache misses that hold the pipeline during refill
4. Variable latency on both instruction and data paths

### 4.5 Special Requirements for IF

Because branches are resolved in `EX`, an instruction request may already be in flight when a redirect occurs. The `if_stage` therefore needs to:

1. Track whether an instruction request is still outstanding
2. Recognize and discard a stale response for the old PC after a redirect

If this behavior is not clear up front, control-flow bugs will become very difficult to see as soon as memory latency is no longer fixed at one cycle.

## 5. Clear Integration Points for Later Extensions

### 5.1 CSR and Trap

Freeze these relationships now:

1. A trap is another kind of redirect.
2. A trap has higher priority than an ordinary branch or jump.
3. A trap must drive the PC redirect, pipeline flush, and CSR-state update together.

This phase only needs to document these relationships. It does not need the full RTL yet.

### 5.2 Cache

The Cache integration points are:

1. I-Cache between `if_stage` and downstream memory
2. D-Cache between `mem_stage` and downstream memory

The requirements are:

1. The CPU-facing interface semantics do not change.
2. The Cache changes only the timing of `req_ready/resp_valid`, not the interface contract.

### 5.3 FPU

The FPU integration points are:

1. Classify instructions in `ID`.
2. Start or enter the floating-point execution path in `EX`.
3. Participate in writeback arbitration in `WB`.
4. Report busy/ready state to the `hazard_unit`.

### 5.4 `M` Extension

If the project adds the `M` extension later, treat it as a multi-cycle integer execution unit near `EX` instead of inventing a separate special-purpose interface during Phase 0.

## 6. Deliverables

1. An ISA description that clearly separates the architecture target from the bring-up subset
2. Module-responsibility notes
3. A field table for every pipeline register
4. Control-priority and flush rules
5. Minimal handshake-interface definition and semantics
6. Reserved integration points for CSR, Cache, and FPU

## 7. Risks and Notes

1. Do not describe the minimum Phase 1 instruction subset as the final ISA boundary for the whole project.
2. Do not use one datapath drawing as a substitute for a real signal table and control description.
3. Do not treat flush as a branch-only mechanism. Traps and interrupts will use the same control path later.
4. Do not leave `memory_wait` vague. At least distinguish front-end waits from data-side waits.
5. Do not add complex abstractions just because they might be useful later. Clear boundaries matter more than empty placeholder modules.

## 8. Exit Conditions

1. The feature boundary for the first version is clear.
2. Module responsibilities and interface semantics are clear.
3. Pipeline-register fields and control priorities are clear.
4. Phase 1 RTL work can begin without reopening the main architecture direction.

## Understanding Check

Use these questions during phase review, grounded in the actual implementation
and verification evidence. Select the most relevant gaps; do not repeat answers
already demonstrated in the conversation.

1. Why did you choose the current instruction subset for the first version?
2. Why is `branch` resolved in `EX` instead of `ID`?
3. What exact problem does the handshake memory interface solve for later phases?
4. Which pipeline register fields are essential, and which are derived?
5. Where do you expect Cache and FPU to hook into the design later?
