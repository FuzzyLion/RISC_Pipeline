# Phase 1 Preparation Sheet

This document turns the current `Phase 1` preparation discussions into a cleaner starting point.

The goal is not to lock every design detail at once. It is to freeze the three things that matter most before implementation begins:

1. The minimum instruction subset
2. The decode-control vocabulary and first control table
3. The field tables for the four pipeline registers

It also separates two ideas that are easy to mix up:

1. Pipeline-register fields
2. Pipeline-register control actions

Keep these in separate tables.

---

## 1. Minimum Bring-up Instruction Subset

The recommended first group is:

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

This selection works because:

1. `add/sub/addi/or` cover the minimum arithmetic and register paths.
2. `lw/sw` close the first data-memory access loop.
3. `beq/jal/jalr` cover the first control-flow redirects.
4. `lui` makes constant and address construction much less awkward.

Leave the following out of the first bring-up group:

1. `lb/lh/lbu/lhu/sb/sh`
2. `auipc`
3. CSR instructions
4. Multiply/divide, FPU, prediction, and register renaming

Do not treat `lb/lh/...` as features that appear automatically. They add:

1. Byte-lane selection
2. Sign extension or zero extension
3. `wstrb` generation

---

## 2. Quick Instruction Semantics

This section records the behavior of the first instruction group so we can check the decode table and datapath against it later.

1. `add`
   `rd <- rs1 + rs2`
2. `sub`
   `rd <- rs1 - rs2`
3. `addi`
   `rd <- rs1 + imm`
4. `or`
   `rd <- rs1 | rs2`
5. `lw`
   `rd <- Mem[rs1 + imm]`
6. `sw`
   `Mem[rs1 + imm] <- rs2`
7. `beq`
   `if (rs1 == rs2) pc <- pc + imm`
8. `jal`
   `rd <- pc + 4, pc <- pc + imm`
9. `jalr`
   `rd <- pc + 4, pc <- (rs1 + imm) & ~1`
10. `lui`
    `rd <- imm << 12`

---

## 3. First Decode-Control Vocabulary

Start with control signals that are clear, sufficient, and not overly broad.

### 3.1 Recommended Main Control Signals

1. `reg_write`
2. `mem_read`
3. `mem_write`
4. `branch`
5. `jump`
6. `jalr`
7. `alu_src`
8. `result_sel`
9. `imm_type`
10. `alu_ctrl`

### 3.2 What Each Signal Means

1. `reg_write`
   Whether the instruction writes the register file at the end.
2. `mem_read`
   Whether the instruction starts a data read.
3. `mem_write`
   Whether the instruction starts a data write.
4. `branch`
   Whether the instruction is a conditional branch.
5. `jump`
   Whether the instruction is an unconditional redirect.
6. `jalr`
   Distinguishes `jalr` target generation from `jal` target generation.
7. `alu_src`
   Selects a register or immediate as the ALU's second operand.
8. `result_sel`
   Selects writeback data from `ALU`, `MEM`, `PC+4`, or `U-imm`.
9. `imm_type`
   Selects the immediate format, such as `I/S/B/U/J`.
10. `alu_ctrl`
    Selects the actual ALU operation: `add/sub/or/...`.

### 3.3 A More Stable Organization

Split the controller into two layers:

1. Main Decoder
   Looks mainly at `opcode` and produces the broad control direction.
2. ALU Decoder
   Combines `opcode/funct3/funct7` to produce `alu_ctrl`.

Do not build one giant `case` statement over complete 32-bit instruction words.

---

## 4. First Decode Control Table

This table is not trying to define the only possible encoding. Its job is to freeze what behavior each instruction should drive.

| Instr | reg_write | mem_read | mem_write | branch | jump | jalr | alu_src | result_sel | imm_type | alu_ctrl |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `add`  | 1 | 0 | 0 | 0 | 0 | 0 | reg | alu   | none | add |
| `sub`  | 1 | 0 | 0 | 0 | 0 | 0 | reg | alu   | none | sub |
| `addi` | 1 | 0 | 0 | 0 | 0 | 0 | imm | alu   | I    | add |
| `or`   | 1 | 0 | 0 | 0 | 0 | 0 | reg | alu   | none | or  |
| `lw`   | 1 | 1 | 0 | 0 | 0 | 0 | imm | mem   | I    | add |
| `sw`   | 0 | 0 | 1 | 0 | 0 | 0 | imm | none  | S    | add |
| `beq`  | 0 | 0 | 0 | 1 | 0 | 0 | reg | none  | B    | sub |
| `jal`  | 1 | 0 | 0 | 0 | 1 | 0 | imm | pc+4  | J    | add |
| `jalr` | 1 | 0 | 0 | 0 | 1 | 1 | imm | pc+4  | I    | add |
| `lui`  | 1 | 0 | 0 | 0 | 0 | 0 | imm | u_imm | U    | pass_b |

Notes:

1. `beq` can use subtraction or dedicated comparison logic. This table uses the subtraction model for now because it is easy to understand consistently.
2. The `jal` target is `pc + imm`.
3. `jalr` uses `rs1 + imm` and then clears the low bit.
4. `alu_ctrl=pass_b` for `lui` simply means that the result comes mainly from the U-type immediate. The final implementation does not have to route it through the ALU.

---

## 5. Pipeline-Register Field Tables

A field is one piece of information that an inter-stage register must store.

Do not put these signals in the field tables:

1. `stallD`
2. `flushD`
3. `stallE`
4. `flushE`

They control how the register updates. They are not information carried through the pipeline with an instruction.

### 5.1 `IF/ID`

The first version should carry at least:

1. `valid`
2. `pc`
3. `instr`

Optional:

1. `pc_plus4`

If `ID` can calculate `pc + 4` locally without difficulty, `IF/ID` does not have to carry it.

### 5.2 `ID/EX`

The first version should carry at least:

1. `valid`
2. `pc`
3. `pc_plus4`
4. `rs1_val`
5. `rs2_val`
6. `imm`
7. `rs1_idx`
8. `rs2_idx`
9. `rd_idx`
10. `control_bundle`

`control_bundle` represents the control information still needed by `EX/MEM/WB`.

### 5.3 `EX/MEM`

The first version should carry at least:

1. `valid`
2. `alu_result`
3. `rs2_val`
4. `rd_idx`
5. `pc_plus4`
6. `control_bundle`

Here:

1. `rs2_val` provides the store data for `sw`.
2. `pc_plus4` provides the final writeback value for `jal/jalr`.

### 5.4 `MEM/WB`

The first version should carry at least:

1. `valid`
2. `alu_result`
3. `mem_rdata`
4. `rd_idx`
5. `pc_plus4`
6. `control_bundle`

---

## 6. Do Not Carry One Full Control Bundle Through Every Stage

The `control_bundle` idea is useful, but every pipeline register does not need to carry the same complete bundle.

A more natural split is:

1. `ID/EX`
   Carries the controls needed by `EX`, `MEM`, and `WB`.
2. `EX/MEM`
   Carries only the controls still needed by `MEM` and `WB`.
3. `MEM/WB`
   Carries only the controls still needed by `WB`.

One possible grouping is:

1. `EX controls`
   `alu_src, alu_ctrl, branch, jump, jalr`
2. `MEM controls`
   `mem_read, mem_write`
3. `WB controls`
   `reg_write, result_sel`

This gives us:

1. Clearer semantics
2. Easier side-effect checks during hazard and flush work
3. No unnecessary controls carried through two or three extra stages

---

## 7. Pipeline-Register Control Semantics

This section sits alongside the field tables. Do not merge them.

### 7.1 `hold`

When a stage boundary is held:

1. Every field in that pipeline register stays unchanged.
2. No new value overwrites the old one.

For example:

1. `hold IF/ID`
   Keeps `valid/pc/instr` unchanged.

### 7.2 `flush`

When a stage boundary is flushed:

1. The pipeline register should contain a bubble on the next cycle.
2. The safest definition is `valid <- 0`.
3. The remaining fields may be cleared or treated as don't-care values, but the implementation should use one consistent style.

### 7.3 `bubble`

Use one shared definition:

1. `valid = 0`
2. Downstream logic guarantees that it produces no architectural side effects.

When `valid=0`, downstream logic must not:

1. Write the register file
2. Write data memory
3. Commit a redirect
4. Commit any future trap-related side effect

---

## 8. Main Sources of Confusion to Avoid

1. Do not treat a stage and a pipeline register as the same thing.
   `if_stage/id_stage/ex_stage/...` are functional stages.
   `if_id/id_ex/ex_mem/mem_wb` are the registers between them.
2. Do not put fields and update controls in the same table.
3. Do not let `control_bundle` turn into a convenient name for an increasingly unclear black box.
4. Do not assume `valid` is unnecessary just because the datapath drawing does not show it.

---

## 9. Final Check Before Phase 1

Phase 1 can begin on solid ground if you can explain each of these points yourself:

1. Why these 10 instructions form the first bring-up group
2. Why each instruction uses its chosen `result_sel`
3. Why `ID/EX` must carry `rs1_val/rs2_val/imm/rd_idx/control`
4. Why `stall/flush` do not belong in the field tables
5. Why `valid=0` is the shared meaning of a bubble

This document can later be extended with:

1. A minimum test-program list
2. A priority table for flush, stall, redirect, and memory wait
3. A concrete module-boundary sketch

---

## 10. Datapath Conventions Using Current RTL Names

This section records the relationship between the hand-drawn datapath and the current RTL field names so new tasks do not reopen the same details.

### 10.1 Where `valid` Comes From and How It Moves

`valid` travels with an instruction through the pipeline and tells us whether a stage contains a real instruction or a bubble. It is not decoded from an instruction bit, and it is not an ordinary control signal produced by the Control Unit.

For the first instruction-memory model, `imem_resp_valid` can remain high after reset. Fetch can then use:

```systemverilog
assign valid_F = imem_resp_valid;
```

If instruction memory later becomes a handshake interface, synchronous ROM, I-Cache, or bus access, `valid_F` must come from the real fetch response. One invariant must always hold: when `valid_F=1`, `pc_F` and `instr_F` belong to the same fetch response.

The current instruction memory is a 32-bit word array. `pc_F` is a byte address, so the fetch index uses `pc_F[MEM_ADDR_WIDTH + 1:2]`. While the core is RV32I-only and does not support compressed instructions, a valid fetch address must satisfy `pc_F[1:0] == 2'b00`. The immediate rules for `jal` and branches, plus the target rule for `jalr`, guarantee only 2-byte alignment. A target ending in `...10` should later raise an instruction-address-misaligned exception instead of letting instruction memory silently discard the low two bits.

Each pipeline register carries `valid` separately along this path:

```text
valid_F -> IF/ID -> valid_D -> ID/EX -> valid_E -> EX/MEM -> valid_M -> MEM/WB -> valid_W
```

### 10.2 How to Draw `reset` and `clk`

`reset` and `clk` are global sequential infrastructure. They are not datapath fields that travel with an instruction. In RTL, `PC`, `IF/ID`, `ID/EX`, `EX/MEM`, and `MEM/WB` should all receive reset. Future CSR logic, Cache FSMs, and SoC control state machines will also need it.

The main datapath drawing does not need reset wires covering the page like ordinary data paths. Put one global note in the corner instead:

```text
Global:
clk   -> all sequential modules
reset -> PC, IF/ID, ID/EX, EX/MEM, MEM/WB, future CSR/cache FSMs
```

This keeps the drawing focused on how instruction and control fields move between stages.

### 10.3 Current Pipeline-Register Field Names

The current RTL uses these names at each stage boundary:

1. `IF/ID`
   `valid_D, pc_D, instr_D, pc_plus4_D`
2. `ID/EX`
   `valid_E, pc_E, pc_plus4_E, rs1_idx_E, rs2_idx_E, rd_idx_E, rs1_val_E, rs2_val_E, imm_E`
   Control fields: `rf_write_E, result_src_E, mem_write_E, jump_E, branch_E, alu_ctrl_E, alu_src_E`
3. `EX/MEM`
   `valid_M, alu_result_M, write_data_M, rd_idx_M, pc_plus4_M`
   Control fields: `rf_write_M, result_src_M, mem_write_M`
4. `MEM/WB`
   `valid_W, alu_result_W, mem_rdata_W, rd_idx_W, pc_plus4_W`
   Control fields: `rf_write_W, result_src_W`

`imm_D/imm_E` is the 32-bit sign-extended immediate already generated in Decode, not the original instruction bitfield. `rs1_val/rs2_val` are 32-bit register values, while `rs1_idx/rs2_idx/rd_idx` are 5-bit register indices.

### 10.4 `valid` Must Gate Every Side Effect

Pipeline registers may carry controls such as `rf_write_*` and `mem_write_*`, but the real register-file or data-memory write must be gated by `valid` at the stage boundary:

```systemverilog
assign rf_write_real_W  = valid_W && rf_write_W;
assign mem_write_real_M = valid_M && mem_write_M;
```

Do not place this combinational logic inside the pipeline-register modules. A pipeline register only stores, clears, or holds fields. The WB stage, MEM stage, or top-level datapath decides how those fields produce architectural side effects.

### 10.5 WB Result-Mux Encoding

`result_src_[D/E/M/W]` remains 2 bits. The first version should use:

1. `2'b00`: `alu_result`
2. `2'b01`: `mem_rdata`
3. `2'b10`: `pc_plus4`
4. `2'b11`: reserved for future CSR read data or another writeback source

The Control Unit and WB mux must use the same encoding. Do not leave this as an unwritten convention.

### 10.6 EX Operands and Store Data

Forwarding must first produce the real register operands. Then `alu_src_E` selects whether the ALU B input uses the forwarded `rs2` or `imm_E`. Store data, `write_data_E`, must come from the forwarded `rs2`, not the ALU's `src_B_E`, because store data must not become an immediate when `alu_src_E` is set.

### 10.7 PC Redirect Convention

In the current drawing, `pc_src_E` means that EX redirects the PC on the next cycle. The recommended semantics are:

```systemverilog
assign pc_src_E = jump_E || (branch_E && branch_taken_E);
```

If the first version supports only `beq`, `branch_taken_E` can come from an equality comparison. Once more branch types are added, do not treat `alu_zero_E` as the universal condition for every branch.
