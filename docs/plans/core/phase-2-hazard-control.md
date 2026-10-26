# Phase 2: Hazard Unit and Control Closure

## Time Limit

Recommended: 1 to 1.5 weeks
Hard limit: 2 weeks

## Goal

Make the pipeline behave correctly under common data and control hazards, with one stable set of control-priority rules.

## Key Decisions

1. Branches are resolved in `EX`, so the flush range follows that choice.
2. The completed baseline uses internal memories with fixed timing. Variable-latency memory waits and pipeline holds are deferred to Phase 5.
3. The first load-use implementation follows the textbook approach: hold Fetch and Decode, clear the Execute pipeline register, and insert one bubble into EX.

## Detailed Tasks

### Task 1: Handle Data Hazards

1. Implement the forwarding paths.
2. Implement the load-use stall.

### Task 2: Handle Control Hazards

1. Implement flushes caused by branches and jumps.
2. Align the flush rules with redirect behavior in `EX`.

### Task 3: Handle Stalls from Handshake-Based Memory Access (Deferred to Phase 5)

1. Add pipeline hold control for memory waits.
2. Keep a data-hazard stall distinct from a memory-wait stall.

### Task 4: Unify the Priority Rules

1. Define current trap, redirect, and load-use priorities. Add `memory_wait` ordering when Phase 5 introduces request/response memory.
2. Keep hazard control in a dedicated module or another clearly defined control unit.

## Current Control Semantics

This section records the conventions already used by the current datapath drawing and pipeline-register RTL.

The current priority is accepted trap, then branch/jump or `mret` redirect,
then load-use stall, then normal flow. Memory-wait priority remains Phase 5 work.

### Load-Use Hazard

The current RTL stalls only for a real source-register dependency:

```systemverilog
lwstall = valid_D && valid_E && ctrl_E.rf_write &&
          (rd_idx_E != '0) && (ctrl_E.result_src == RSLT_RDATA) &&
          (((rs1_idx_D == rd_idx_E) && uses_rs1_D) ||
           ((rs2_idx_D == rd_idx_E) && uses_rs2_D));
```

Decode supplies `uses_rs1_D` and `uses_rs2_D`; immediate and CSR address fields
must not create false register dependencies.

When `lwstall=1`, the control actions are:

1. `stall_F = 1`
   Hold the PC and do not fetch a new instruction.
2. `stall_D = 1`
   Hold `IF/ID`, keeping the dependent instruction in Decode.
3. `flush_E = 1`
   Clear `ID/EX`, so Execute sees a bubble on the next cycle.

This does not remove the load that is already in EX. The load continues into MEM. The instruction being cleared is the dependent instruction that would otherwise move from Decode into Execute.

### Branch and Jump Redirects

Branches and jumps currently decide redirects in EX. `pc_src_E` is an enum,
and the Hazard Unit recognizes both normal target and `mret` redirects:

```systemverilog
redirect = (pc_src_E == PC_TARGET) || (pc_src_E == PC_MRET);
```

When `redirect=1`, flush the wrong-path instructions that are younger than the instruction in EX. In the current five-stage design, this normally means at least:

1. `flush_D = 1`
   Clear the wrong-path instruction in `IF/ID`.
2. `flush_E = 1`
   Clear the wrong-path instruction in `ID/EX`.

Do not flush the branch or jump itself from `EX/MEM` in this phase. It is the older instruction that already made the redirect decision.

### Forwarding Order and Store Data

Forwarding should produce the real `rs1` and `rs2` operands used in EX. Keep two selects:

1. `forward_AE`
   Select `rs1_val_E`, `alu_result_M`, `csr_rdata_M`, or `result_W`.
2. `forward_BE`
   Select `rs2_val_E`, `alu_result_M`, `csr_rdata_M`, or `result_W`.

The ALU B path should first forward the real `rs2` value, then let `alu_src_E` choose between that forwarded value and `imm_E`. Store data, `write_data_E`, must come from the forwarded `rs2`, not from `src_B_E`. Otherwise, an `sw` with `alu_src_E=1` would incorrectly use the immediate as store data.

### Valid Gating

The Hazard Unit can use register indices and control fields to generate stall and flush signals, but every architectural side effect must still be gated by the stage's `valid` bit:

```systemverilog
mem_write_real_M = valid_M && mem_write_M;
rf_write_real_W  = valid_W && rf_write_W;
```

The shared meaning of a bubble is `valid=0`. A bubble must never write a register, write data memory, commit a redirect, or cause a future trap side effect.

### Future Memory Waits

For now, follow the textbook path and implement the basic load-use and branch/jump hazards first. `EX/MEM` and `MEM/WB` can temporarily remain unstalled. Once the design adds a data-memory handshake, a Cache miss, or a slow peripheral, a memory wait cannot freeze only Fetch and Decode. Deeper pipeline registers may also need to hold so MEM and WB do not move out of step.

When that extension arrives, redefine:

1. Which pipeline registers hold during a memory wait
2. Whether a memory wait or branch redirect has priority
3. Who inserts the bubble when a memory wait and load-use stall happen together
4. How a held store or load avoids committing twice or losing its response

## Tests to Add Early

1. Focused, hand-written tests for RAW hazards, load-use hazards, and branches
2. Basic `RV32I` cases from `riscv-tests`
3. Branch cases that prove wrong-path instructions are flushed

## Deliverables

1. Hazard Unit RTL
2. Hazard-control rule table
3. Focused test suite
4. Basic `riscv-tests` integration notes
5. Control-priority timing notes

## Verification Requirements

1. Forwarding selections are correct.
2. Bubble insertion and stall behavior are correct.
3. Wrong-path instructions are flushed correctly.
4. Deferred to Phase 5: prove pipeline holds and exactly-once memory side effects under request/response waits.

## Risks and Notes

1. Many bugs come from priority conflicts, not forwarding itself.
2. If `memory_wait` semantics are unclear now, Cache integration will expose the same problems again.
3. Start replacing some hand-written examples with `riscv-tests` during this phase.

## Exit Conditions

1. Common hazard scenarios have a stable, complete control path.
2. The CPU passes a useful set of basic programs and selected `riscv-tests`.
3. The project is ready for structured verification.

--

### Attachment

Situation                         stall_F  stall_D  flush_D  flush_E  forward_AE / forward_BE

No hazard                         0        0        0        0        normal
RAW from MEM ALU result           0        0        0        0        select MEM when rs matches
RAW from WB result                0        0        0        0        select WB when rs matches
Load-use: E load feeds D          1        1        0        1        normal this cycle
Taken branch or jump in EX        0        0        1        1        computed normally

## Understanding Check

Use these questions during phase review, grounded in the actual implementation
and verification evidence. Select the most relevant gaps; do not repeat answers
already demonstrated in the conversation.

1. What is the priority order between stall, flush, redirect, and memory wait in your design?
2. Why is that priority order correct?
3. How do you distinguish load-use hazard from a normal RAW hazard?
4. What forwarding paths exist in your implementation, and why are they sufficient?
5. What failure would appear if one forwarding path were missing?
