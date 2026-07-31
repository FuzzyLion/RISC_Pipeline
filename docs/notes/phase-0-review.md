# Phase 0 Review and Recommendations

This is not the final specification. It organizes and reviews your current answers. The architecture boundary that actually gets frozen lives in [phase-0-architecture-boundary.md](../plans/foundation/phase-0-architecture-boundary.md).

## Overall Assessment

Your main direction is already sound:

1. Keep the first version focused instead of trying to build everything at once.
2. Resolve `branch` instructions in `EX` first so the implementation stays manageable.
3. Do not let Cache, CSR, or FPU work disrupt the main path too early.
4. Get the five-stage pipeline, hazard handling, and verification solid before adding broader system features.

The main gaps are not about missing the basic ideas. They are about making three boundaries more explicit:

1. Separate the architecture target from the minimum bring-up subset.
2. Turn the datapath drawing into a real signal table and a set of control rules.
3. Treat flush, redirect, exception, and memory wait as one connected control problem.

## Task 1: ISA and First-Version Boundary

### 1.1 Which Instructions Belong in the First Version?

Your current list—`add/sub/or/lw/sw/beq/jalr/jal`—is understandable as a minimum bring-up subset. I would add two things:

1. Put `addi` in the first group.
2. Add `lui` early, and add `auipc` as soon as the software needs it.

The reason is straightforward:

1. Without `addi`, even simple test programs become awkward.
2. Without `lui/auipc`, building constants and addresses is unnecessarily difficult.
3. These instructions are not hard to implement, but they remove a lot of friction from software and testing.

A cleaner way to describe the scope is:

1. Phase 0 fixes `RV32I` as the architecture target.
2. Phase 1 starts with a minimum runnable bring-up subset.
3. The rest of `RV32I` is added gradually between Phases 1 and 3.

### 1.2 Are the Smaller Load/Store Instructions Basically the Same as `lw`?

No.

Compared with `lw/sw`, `lb/lh/lbu/lhu/sb/sh` add real complexity:

1. The low address bits select the byte lane.
2. Returned data needs sign extension or zero extension.
3. Write requests need different `wstrb` values.
4. Misaligned access and exception semantics appear later.

The right mental model is:

1. `lw/sw` can be brought up on their own first.
2. Byte and halfword accesses are a separate feature set, not something that comes for free.

### 1.3 What About CSR?

Your decision not to implement CSR yet, while still understanding where it will fit later, is reasonable.

Phase 0 does not require you to finish the privileged specification. For now, you only need to know:

1. The full CSR path does not need to be implemented before Phase 4.
2. Phase 0 should freeze the boundary between trap/redirect behavior and CSR state.
3. Before Phase 4 begins, read the relevant privileged-specification sections in a focused pass.

In other words, the issue is not that you “do not understand CSR.” You simply have not reached the CSR implementation phase yet.

## Task 2: Module Boundaries

### 2.1 Are `if_stage/id_stage/ex_stage/...` Pipeline Registers?

No.

The more precise distinction is:

1. `if_stage/id_stage/ex_stage/mem_stage/wb_stage` are the functional logic in each stage.
2. `if_id/id_ex/ex_mem/mem_wb` are the pipeline registers between those stages.

This boundary matters. If stages and pipeline registers get mixed together, stall and flush behavior becomes difficult to explain and implement cleanly.

### 2.2 How Should We Leave Room for Future Interfaces?

The direction is right, but reserve boundaries, not empty RTL shells.

A better approach is:

1. Document where CSR, Cache, and FPU will connect later.
2. Identify the control signals that will eventually be required.
3. Do not force a collection of empty placeholder modules into the early RTL.

This keeps the design extensible without making the first pipeline skeleton messy.

### 2.3 Where Will Cache and FPU Connect?

The current recommendation is clear:

1. Cache connects to the external memory interfaces of `if_stage` and `mem_stage`.
2. FPU connects near `EX`, with decode in `ID` and writeback arbitration in `WB`.

Remembering these two integration points is enough for now. It will keep the main RTL interfaces from being boxed in.

## Task 3: Pipeline Registers and Control Paths

### 3.1 and 3.2 Why Is “Same as the Diagram Above” Not Enough?

Your datapath drawing is useful, but a drawing cannot replace the architecture decisions.

Phase 0 needs a written record of:

1. The required fields in `IF/ID`
2. The required fields in `ID/EX`
3. The required fields in `EX/MEM`
4. The required fields in `MEM/WB`
5. Which values are essential and which are derived

Without that list, Phase 1 tends to turn into “the signals almost seem sufficient, but something still feels missing.”

### 3.3 Priority Between Stall, Flush, Redirect, and Memory Wait

Start with this mental model:

1. A trap or interrupt is also a redirect, but with higher priority.
2. A branch redirect should outrank a load-use stall.
3. A `dmem_wait` from an older instruction should outrank an ordinary redirect from a younger stage.
4. `imem_wait` and `dmem_wait` should not be hidden behind one vague signal.

The current recommended priority is:

1. `reset`
2. `trap_redirect` / `mret_redirect`
3. `dmem_wait`
4. `ex_redirect`
5. `load_use_stall`
6. `imem_wait`
7. Normal progress

You will refine this again in Phase 2, but Phase 0 should still settle the basic rule.

## Task 4: Memory Interface

### 4.1 The Minimal Interface You Asked Me to Complete

The current minimum recommendation is:

1. `req_valid`
2. `req_ready`
3. `req_addr`
4. `req_wdata`
5. `req_wstrb`
6. `resp_valid`
7. `resp_rdata`

It is also worth reserving two optional extensions in the documentation:

1. `req_size`
2. `resp_err`

The interface semantics need to be explicit:

1. A request is accepted only when `req_valid && req_ready` is true.
2. Each port allows at most one outstanding request.
3. Responses remain in order.
4. `req_wstrb == 0` means a read; a nonzero value means a write.
5. On the data side, use `resp_valid` to confirm completion for both reads and writes.

### 4.2 Which Phase Should Include a Branch Predictor or Register Renaming?

My recommendation is direct:

1. A branch predictor is not required for the current main path.
2. If you add one later, treat it as an optional performance branch after Phase 6.
3. Do not include register renaming in the current project plan.

The reasons are:

1. A branch predictor is a performance optimization, not a requirement for closing first-version correctness.
2. Register renaming belongs to out-of-order or otherwise more aggressive execution models. It does not fit the current goal of a clear, verifiable, in-order five-stage pipeline.

If the goal is a project you can explain, run on a board, and extend with Cache and FPU, a predictor can stay optional. Register renaming can stay out of scope.

### 4.3 How Does This Support Slow Peripherals and a Future Cache?

The whole idea fits in one sentence:

The CPU-facing interface keeps the same semantics, while `ready/valid` absorbs changes in downstream latency.

That means:

1. For a slow peripheral, `req_ready` or `resp_valid` simply arrives later.
2. For a Cache miss, the response is also delayed.
3. If Phase 0 defines the handshake semantics clearly, Phases 5 and 7 will not need to replace the CPU-facing interface.

## Task 5: Key Architecture Policies

### 5.1 Your Understanding of Branch Handling in `EX`

Your main idea is right, but the full explanation should be more precise:

1. Decode the branch or jump type in `ID`.
2. Use the ALU or comparison logic in `EX` to evaluate the condition and calculate the target address.
3. `PCSrcE` comes from both the instruction type and whether the branch condition is true.
4. `jal` is an unconditional redirect, while `jalr` must also clear the low bit of the target address.

`ZeroE` is one input used for conditions such as `beq`. It is not a universal explanation for every redirect.

### 5.2 Why Flush Is Not Only for Branches

This is the most useful concept to strengthen now.

A flush is not a branch-only feature. Its real purpose is:

1. A control-flow redirect or precise-state correction occurs.
2. Younger instructions already traveling down the wrong path must be removed.

Ordinary branches and jumps cause a flush. Future exceptions and interrupts will also cause one.

The difference is:

1. A branch redirect mainly corrects the PC and removes the wrong path.
2. A trap redirect also updates CSR state and must preserve precise-exception semantics.

So the clean mental model is:

1. A branch flush is the flush for an ordinary redirect.
2. A trap flush is the flush for a higher-priority redirect with architectural state updates.

### 5.3 Why the Diagram Still Needs a Written Explanation

The diagram helps, but you still need to explain the following without relying on it:

1. Which stage produces a redirect
2. Which stages are flushed
3. Which stage's wait condition can freeze the full pipeline
4. Which control signals move across stages

Once you can explain those points clearly in words, you will not need to point at the diagram throughout an interview.

## Summary of My Phase 0 Recommendations

1. Do not rush into flashy features. First separate the full `RV32I` target from the minimum bring-up subset.
2. The most important Phase 0 additions are the signal table, interface semantics, and control priorities—not more repetition of theory.
3. Leave the branch predictor for much later, and remove register renaming from the main plan.
4. You are ready to begin Phase 1 once the phase-boundary document is solid. Do not start by guessing control rules while writing RTL.

---

## The Questions I Still Have

1. What exactly is a field? I do not see signals such as `valid` in my datapath drawing. Does “field” just mean the wire or register names we use when writing a module?
2. I have not started the implementation yet, but is there a standard `case` structure for the Control Unit to decode the minimum instruction subset?
3. I understand that the large `PipelineReg` block in the diagram represents several registers grouped together for readability. In RTL, should we implement it as one whole block or as several separate registers?
4. Since I do not know how to implement CSR or Cache yet, should I read more first or start with the basic microarchitecture?

## Direct Answers to These Four Questions

### Question 1: What Is a “Field”?

A field is not a mysterious new concept. Think of it as:

1. One piece of information that a pipeline register needs to store
2. One item inside the data packet carried by that pipeline register

For example, if the `IF/ID` pipeline register has three fields:

1. `valid`
2. `pc`
3. `instr`

then `IF/ID` stores all three together at the clock edge.

The relationship between fields and signals is:

1. In an architecture document, a field is a conceptual requirement: the information this stage boundary must carry.
2. In RTL, that field becomes a concrete `reg`, `logic`, or `wire` name.

For example, the RTL might use:

1. `if_id_valid`
2. `if_id_pc`
3. `if_id_instr`

These three signals are the concrete RTL form of the three `IF/ID` fields.

### Why `valid` Is Often Missing from a Datapath Diagram

Textbook datapath drawings usually show an idealized main path. They focus on:

1. How instructions move
2. What the ALU computes
3. How registers and memory connect

They often omit control information that matters in a real implementation but would make the drawing crowded:

1. `valid`
2. `stall`
3. `flush`
4. `ready/valid` handshakes
5. Wrong-path response discard logic

Something missing from the drawing is not necessarily missing from the implementation.

### Why `valid` Matters

`valid` tells us whether a stage currently contains:

1. A real instruction
2. A bubble

That distinction matters when:

1. A branch flush inserts bubbles.
2. A load-use stall holds some stages while inserting a bubble into another.
3. A future trap or interrupt removes wrong-path instructions.

Without `valid`, it becomes difficult to distinguish a bubble from a real instruction.

### Question 2: Is There a Standard Control-Unit `case` Statement?

There is a common pattern, but not one official answer:

1. There is no official `case` template that everyone copies exactly.
2. There is a common and sensible way to organize the decode logic.

The most common organization uses two layers:

1. Main Decoder
   Looks mainly at `opcode` and produces the broad control direction, such as `reg_write`, `mem_read`, `mem_write`, `branch`, `jump`, `alu_src`, and `result_sel`.
2. ALU Decoder
   Combines `opcode`, `funct3`, and `funct7` to choose the exact `alu_op`.

The mental model is:

1. First decide whether the instruction is R-type, load, store, branch, `jal`, `jalr`, `lui`, or `addi`.
2. Then decide which control signals that instruction needs.
3. Finally decide whether the ALU performs `add/sub/or/...`.

The best Phase 1 starting point is not searching for a standard answer. It is writing your own decode table first.

At minimum, you should be able to describe:

1. `add`
   `reg_write=1`, `alu_src=reg`, `result_sel=alu`, `alu_op=add`
2. `lw`
   `reg_write=1`, `mem_read=1`, `alu_src=imm`, `result_sel=mem`, `alu_op=add`
3. `sw`
   `mem_write=1`, `alu_src=imm`, `alu_op=add`
4. `beq`
   `branch=1`, `alu_src=reg`, comparison logic enabled
5. `jal`
   `jump=1`, `reg_write=1`, `result_sel=pc_plus4`

Once you can write that table clearly, the `case` statement is simply its RTL form.

### One Important Warning

Do not start by matching each complete 32-bit instruction word in a giant `case` statement. Decode the RISC-V instruction fields:

1. `opcode`
2. `funct3`
3. `funct7`

That structure will scale naturally as the design grows toward full `RV32I`.

### Question 3: How Should `PipelineReg` Be Written in RTL?

The recommended approach is:

1. Organize the RTL around each inter-stage register.
2. Store several concrete fields inside each one.

Avoid:

1. Scattering many unrelated small registers across the top level.
2. Immediately packing everything into one unreadable bit vector.

In practice, write:

1. `if_id_reg`
2. `id_ex_reg`
3. `ex_mem_reg`
4. `mem_wb_reg`

Each module can use one sequential block to update all of its fields together.

The right mental model is:

1. Architecturally, it is one inter-stage register.
2. In RTL, it contains several individual fields.

In short: model the boundary as a whole, but store the fields separately.

### Why Not Split Everything Apart?

Stall and flush semantics apply to the whole stage boundary.

For example:

1. `flush id_ex`
   Does not clear only one signal. It turns the entire `ID/EX` entry for that cycle into a bubble.
2. `hold if_id`
   Means the complete `IF/ID` state stays unchanged.

Grouping registers by stage boundary is therefore the most natural control model.

### Practical RTL Mental Model

For the current phase:

1. Give each inter-stage register module one `always_ff` block.
2. Store several fields inside it, such as `valid/pc/instr/...`.
3. Handle `reset`, `flush`, and `enable` consistently inside that module.

With SystemVerilog, you may later use a `struct packed`. Plain Verilog is also fine; just write the individual register fields clearly.

### Question 4: Read First, or Start the Basic Microarchitecture?

My recommendation is:

1. Start the basic microarchitecture now.
2. For CSR and Cache, understand only where they will connect and which control boundaries they will affect.
3. Do not disappear into CSR or Cache implementation details before Phase 1.

The reason is simple:

1. The most valuable work now is making the Phase 1 datapath and Phase 2 control path solid.
2. Studying CSR and Cache in depth now would add a lot of complexity before you can use it.
3. The Phase 0 documents already reserve their integration boundaries, which is enough to begin Phase 1.

### This Does Not Mean Ignoring Them Completely

A more accurate study plan is:

1. Start the microarchitecture now.
2. For CSR, know that a trap is essentially a higher-priority redirect.
3. For Cache, know that a miss appears as a memory wait or delayed `ready/valid` response.
4. Study each topic in depth when its phase begins.

That order fits the current stage of the project best.

You do not need to learn every future feature before starting. You need to:

1. Make the current phase solid.
2. Avoid locking future interfaces into the wrong shape.

## What to Finish Before Starting Phase 1

You could simply start writing RTL now. But if you want Phase 1 to go much more smoothly, finish these small pieces first.

### Required 1: Freeze the Minimum Instruction Subset

Do not leave it at “roughly these instructions.” Write one final list before implementation starts.

My recommended first group is:

1. `add`
2. `sub`
3. `addi`
4. `or`
5. `lw`
6. `sw`
7. `beq`
8. `jal`
9. `jalr`
10. `lui`

That keeps the Control Unit boundary stable while you implement it.

### Required 2: Write the Decode Control Table First

Before writing RTL, make a table with:

1. Instruction name
2. `reg_write`
3. `mem_read`
4. `mem_write`
5. `branch`
6. `jump`
7. `alu_src`
8. `result_sel`
9. `alu_op`

This table will directly shape the controller.

### Required 3: Write the Pipeline-Register Field Table

Define all four stage boundaries:

1. `IF/ID`
2. `ID/EX`
3. `EX/MEM`
4. `MEM/WB`

The first version does not have to be perfect, but it needs to exist.

### Required 4: Define Flush and Stall Actions

At minimum, answer:

1. When `hold if_id` is active, which fields stay unchanged?
2. When `flush id_ex` is active, do all fields clear, or only `valid` and the control fields?
3. What exactly is a bubble?
4. When `valid=0`, is the downstream logic guaranteed to produce no side effects?

Once these answers are clear, the RTL becomes much easier to write.

### Required 5: Prepare Four to Six Minimal Test Programs

Think through the first tests before Phase 1 begins. Otherwise, it is easy to finish the RTL without knowing what to verify first.

Prepare at least:

1. A basic `addi/add/sub/or` arithmetic program
2. A basic `lw/sw` memory program
3. A `beq` taken/not-taken program
4. A `jal` jump-and-link program
5. A `jalr` return program
6. An `x0` write-protection test

## Conclusion

If the only question is whether Phase 1 can begin, the answer is yes.

The safest start is not to dive straight into RTL. First finish these three sheets:

1. The minimum instruction list
2. The decode control table
3. The four pipeline-register field tables

Once those are clear, Phase 1 becomes much easier. More importantly, you will understand what you are building instead of guessing as you go.
