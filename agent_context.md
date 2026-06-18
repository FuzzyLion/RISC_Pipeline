# Agent Context

This repository is a learning-first SystemVerilog RISC-V CPU project. The current RTL implements a small RV32I-oriented five-stage pipeline core with internal instruction and data memories, Verilator smoke tests, and planning documents for later CSR, exception, interrupt, SoC, FPGA, cache, FPU, and RTOS work. The design goal visible in the repository is to make the basic pipelined core and hazard behavior understandable and verifiable before adding larger system features.

The code is not a complete RV32I processor yet. The active decode now covers
the full R-type integer ALU group, the RV32I ALU-immediate group, all six base
branch conditions, `lui`, `auipc`, `lb`, `lh`, `lw`, `lbu`, `lhu`, `sb`,
`sh`, `sw`, `jal`, and `jalr`. System instructions, CSR behavior, exceptions,
and interrupts are still outside the implemented subset.

## Compact Directory Tree

```text
.
├── AGENTS.md
├── agent_context.md
├── requirements.md
├── docs/
│   ├── data-memory-addressing.md
│   ├── Pipeline_Datapath.heic
│   └── plans/
│       ├── README.md
│       ├── foundation/
│       ├── core/
│       ├── system/
│       └── extensions/
├── programs/
│   ├── smoke_basic.hex
│   ├── smoke_basic.s
│   ├── smoke_alu.hex
│   ├── smoke_alu.s
│   ├── smoke_branch.s
│   ├── smoke_branch.hex
│   ├── smoke_hazard.s
│   └── smoke_hazard.hex
├── rtl/
│   └── core/
│       ├── filelist.f
│       ├── core_types_pkg.sv
│       ├── top.sv
│       ├── core.sv
│       ├── control_unit.sv
│       ├── hazard_unit.sv
│       ├── IF_ID.sv
│       ├── ID_EX.sv
│       ├── EX_MEM.sv
│       ├── MEM_WB.sv
│       ├── pc_reg.sv
│       ├── pc_plus4_adder.sv
│       ├── pc_mux.sv
│       ├── pc_target_gen.sv
│       ├── instr_mem.sv
│       ├── instr_field.sv
│       ├── imm_ext.sv
│       ├── reg_file.sv
│       ├── alu_op.sv
│       ├── EX_forward_muxAE.sv
│       ├── EX_forward_rd_muxBE.sv
│       ├── EX_muxBE.sv
│       ├── store_data.sv
│       ├── data_mem.sv
│       ├── load_data.sv
│       └── WB_result_mux.sv
├── sim/
│   ├── build_hex.sh
│   ├── run_alu_op.sh
│   ├── run_basic_smoke.sh
│   ├── run_control_unit.sh
│   ├── run_data_mem.sh
│   ├── run_hazard_unit.sh
│   ├── run_imm_ext.sh
│   ├── run_pc_target_gen.sh
│   ├── run_reg_file.sh
│   ├── run_regression.sh
│   ├── run_smoke_alu.sh
│   ├── run_smoke_branch.sh
│   └── run_smoke_hazard.sh
└── tb/
    ├── alu_op_tb.sv
    ├── control_unit_tb.sv
    ├── core_basic_smoke_tb.sv
    ├── core_smoke_alu_tb.sv
    ├── core_smoke_branch_tb.sv
    ├── core_smoke_hazard_tb.sv
    ├── data_mem_tb.sv
    ├── hazard_unit_tb.sv
    ├── imm_ext_tb.sv
    ├── pc_target_gen_tb.sv
    └── reg_file_tb.sv
```

Empty or currently fileless directories such as `rtl/soc`, `fpga`, `software`, and `tools` exist in the working tree but do not contain source files visible to `rg --files` at the time this document was written. Generated simulation output under `sim/build` is intentionally excluded.

## Important Files and Modules

`rtl/core/core_types_pkg.sv` defines shared constants, opcode/funct enums, ALU control enums, mux-select enums, packed control bundles, packed pipeline-register data structs, and hazard control structs. This package is the main type contract between pipeline stages.

`rtl/core/top.sv` is a thin wrapper around `core`. Its comment marks it as a future board/SoC wrapper point for clock, reset, memory, and peripherals.

`rtl/core/core.sv` is the main pipeline integration module. It wires control, PC logic, instruction memory, register file, immediate generation, forwarding muxes, ALU, branch target generation, pipeline registers, store/load data alignment, data memory, writeback mux, and the hazard unit.

`rtl/core/control_unit.sv` decodes the instruction in the Decode stage into
`control_bundle_t` and `imm_src_e`. Implemented active cases include the R-type
ALU instructions, `addi`, `slti`, `sltiu`, `xori`, `ori`, `andi`, `slli`,
`srli`, `srai`, `lb`, `lh`, `lw`, `lbu`, `lhu`, `sb`, `sh`, `sw`, `lui`,
`auipc`, `beq`, `bne`, `blt`, `bge`, `bltu`, `bgeu`, `jal`, and `jalr`.
Unsupported funct combinations fall back to the NOP control bundle.

`rtl/core/hazard_unit.sv` generates forwarding selects plus stall/flush controls. It forwards MEM non-load ALU results and WB results into EX operands, stalls on load-use hazards where an EX-stage load feeds a Decode-stage source, and flushes Decode/Execute on taken branch or jump redirects from EX.

`rtl/core/IF_ID.sv`, `rtl/core/ID_EX.sv`, `rtl/core/EX_MEM.sv`, and `rtl/core/MEM_WB.sv` are the four pipeline-register modules. They use packed structs from the package, synchronous reset, valid bits, and side-effect control gating so bubbles do not write registers, write memory, branch, or jump.

`rtl/core/pc_reg.sv`, `rtl/core/pc_plus4_adder.sv`, and `rtl/core/pc_mux.sv` implement the Fetch-stage PC path. The PC register can stall, reset goes to zero, the adder computes `PC + 4`, and the mux chooses either the sequential PC or an EX-stage redirect target.

`rtl/core/pc_target_gen.sv` computes branch/jump targets and `pc_src_E`.
PC-relative targets use `pc_E + imm_E`; `jalr` uses `alu_src_AE + imm_E` and
clears target bit 0. The module cannot determine whether `alu_src_AE` came from
the original operand or a forwarding path; that behavior belongs to the
upstream forwarding mux and integration tests. `alu_op.sv` evaluates all six
RV32I branch conditions and presents the taken/not-taken result through
`zero_E`, which `pc_target_gen` combines with `branch_E`. Because the core does
not implement the compressed-instruction extension, a JALR target with bit 1
set will later need an instruction-address-misaligned exception rather than
further silent alignment.

`rtl/core/instr_mem.sv` is a simple word-array instruction memory initialized with `$readmemh`. It indexes memory using `pc_F[MEM_ADDR_WIDTH+1:2]`, so the core presents byte addresses while the model stores 32-bit instruction words.

`rtl/core/instr_field.sv` extracts `rs1`, `rs2`, and `rd` fields from the Decode-stage instruction.

`rtl/core/imm_ext.sv` sign-extends or forms I, S, B, J, and U immediates. It is combinational and selected by the control unit.

`rtl/core/reg_file.sv` implements 32 RV32 architectural registers with synchronous writeback, combinational reads, x0 hardwired to zero on reads/writes, reset clearing all registers, and same-cycle WB-to-ID read bypassing.

`rtl/core/alu_op.sv` implements add, sub, and, or, xor, pass-B, signed/unsigned
set-less-than, logical shifts, arithmetic right shift, and the AUIPC
`pc_E + U-immediate` operation. It also evaluates BEQ, BNE, BLT, BGE, BLTU, and
BGEU when branch control is active.

`rtl/core/EX_forward_muxAE.sv` selects the EX-stage ALU A operand from the ID/EX `rs1` value, WB result, or MEM ALU result.

`rtl/core/EX_forward_rd_muxBE.sv` selects the forwarded EX-stage `rs2` value used both as store write data and as the pre-immediate ALU B source.

`rtl/core/EX_muxBE.sv` chooses the ALU B operand between forwarded `rs2` data and the EX-stage immediate.

`rtl/core/store_data.sv` prepares store data before the data memory. It uses
the MEM-stage store type and address low bits to shift `rs2` data into the
correct byte lanes and generate a 4-bit write strobe for `sb`, `sh`, and `sw`.
Misaligned `sh` and `sw` currently produce no write strobe; a later exception
path should turn those cases into architectural traps.

`rtl/core/data_mem.sv` is a simple word-array data memory with combinational
read and synchronous byte-lane writes. It treats ALU results as byte addresses
and indexes the internal word array with address bits `[MEM_ADDR_WIDTH+1:2]`.
Subword stores are applied through `store_wstrb_M`, while the selected 32-bit
word is still read as a whole and narrowed by `load_data`. It intentionally has
no CPU reset input. Simulation or FPGA power-up initialization is separate from
CPU reset, and clearing the full array in reset logic could prevent RAM
inference.

`rtl/core/load_data.sv` post-processes the 32-bit data-memory read word for
`lb`, `lh`, `lw`, `lbu`, and `lhu`. It selects the addressed byte or halfword
using `alu_result_M[1:0]`, then sign-extends or zero-extends the value for
writeback. Misaligned `lh`, `lhu`, and `lw` currently produce zero rather than
raising an architectural exception.

`rtl/core/WB_result_mux.sv` selects the writeback value from ALU result, post-processed load result, or `PC + 4`.

`rtl/core/filelist.f` lists the core RTL files for Verilator builds.

`tb/alu_op_tb.sv`, `tb/reg_file_tb.sv`, `tb/control_unit_tb.sv`,
`tb/imm_ext_tb.sv`, `tb/data_mem_tb.sv`, `tb/pc_target_gen_tb.sv`, and
`tb/hazard_unit_tb.sv` provide focused module-level tests. The ALU and control
testbenches keep one instruction or behavior per task. Test tasks explicitly
apply defaults, assign direct inputs, wait `#1`, and call reusable check tasks.
Coverage includes arithmetic wraparound, signed versus unsigned comparison,
shift behavior, all branch conditions, AUIPC calculation and decode, load/store
decode variants, `zero_E`, and invalid control handling.

`tb/data_mem_tb.sv` covers initial zero contents, combinational reads,
synchronous writes, write-disable behavior, byte-lane write strobes, ignored low
address bits for word indexing, and independence of adjacent words.

`tb/pc_target_gen_tb.sv` covers positive and negative PC-relative offsets, 32-bit address wraparound, JALR target calculation, JALR bit-0 clearing, use of `alu_src_AE` rather than `pc_E`, and jump/branch redirect decisions. It intentionally does not claim to verify where `alu_src_AE` originated.

`tb/core_basic_smoke_tb.sv`, `tb/core_smoke_branch_tb.sv`,
`tb/core_smoke_hazard_tb.sv`, and `tb/core_smoke_alu_tb.sv` instantiate `top`,
load one program each, enforce a timeout, and inspect architectural state
hierarchically. The ALU smoke covers ALU-immediate results plus taken and
not-taken cases for the six branch conditions. These are directed smoke tests,
not a complete ISA verification environment.

`sim/run_alu_op.sh`, `sim/run_reg_file.sh`, `sim/run_control_unit.sh`,
`sim/run_imm_ext.sh`, `sim/run_data_mem.sh`, `sim/run_pc_target_gen.sh`, and
`sim/run_hazard_unit.sh` run module-level Verilator tests.
`sim/run_basic_smoke.sh`, `sim/run_smoke_branch.sh`,
`sim/run_smoke_hazard.sh`, and `sim/run_smoke_alu.sh` rebuild their assembly
programs and run processor-level smoke tests. `sim/run_regression.sh` is the
unified entry point and runs eleven tests: seven module tests and four processor
smoke tests. `sim/build_hex.sh` assembles `.s` files into `.hex` using
`riscv64-elf-gcc` with `-march=rv32i`, `-mabi=ilp32`, no runtime, and text base
zero.

`docs/data-memory-addressing.md` explains the current byte-addressed ISA view versus word-array Verilog memory model. It is useful background before changing load/store behavior.

`docs/plans/` contains roadmap documents for phases beyond the current core, including hazard control, verification, CSR/exceptions/interrupts, SoC/FPGA, cache, FPU, and RTOS integration.

## Architecture Summary

The implemented datapath is organized as a classic five-stage pipeline: IF, ID, EX, MEM, and WB. IF holds and updates the PC, fetches a 32-bit instruction from `instr_mem`, and computes `PC + 4`. ID decodes the instruction, reads the register file, extracts register fields, and generates immediates. EX applies forwarding, selects ALU operands, computes ALU results, computes branch/jump targets, and decides redirects. MEM prepares subword stores, accesses the simple internal data memory, and post-processes load data. WB selects the final result and writes the register file.

Control is generated in Decode as a packed `control_bundle_t`, then carried through later stages with narrower packed control bundles where possible. Pipeline registers carry explicit `valid` bits, and side-effecting controls are gated by validity as they enter later stages.

Branches and jumps are resolved in EX. `pc_target_gen` chooses between PC-relative targets and `jalr` register-relative targets. When `pc_src_E` selects the target path, the hazard unit flushes Decode and Execute so wrong-path instructions are converted into bubbles.

AUIPC is also completed in EX. Decode selects `CTRL_PASS_B4PC` and the U-type
immediate; the ALU receives the instruction's pipelined `pc_E` and computes
`pc_E + imm_E`. This uses the AUIPC instruction address, not `PC + 4`.

Forwarding is handled for EX-stage operands. The A operand can come from the original `rs1`, WB result, or MEM ALU result. The B-side register data can come from original `rs2`, WB result, or MEM ALU result, and then a separate mux chooses between that register data and the immediate for the actual ALU B input. MEM-stage forwarding excludes load results because load data is not available early enough for the next EX-stage consumer.

Load-use hazards are detected when a valid EX-stage load writes a nonzero `rd` that matches either source of a valid Decode-stage instruction. In that case Fetch and Decode stall, while Execute is flushed to insert a bubble. Redirects have priority over load-use stalls in the current hazard unit.

CSR, exceptions, interrupts, external memory handshakes, SoC integration, cache, FPU, and RTOS support are not visible as implemented RTL in the current source tree. They appear as planning goals in `docs/plans`.

## Coding Conventions Visible in the Repository

The RTL uses SystemVerilog modules with `logic`, `always_comb`, `always_ff @(posedge clk)`, package imports through `import core_types_pkg::*`, typedef enums for opcodes/control selects, and packed structs for control/data bundles. Most combinational modules use `case` statements with explicit defaults.

Names commonly encode pipeline stage suffixes such as `_F`, `_D`, `_E`, `_M`, and `_W`. Pipeline-register payloads are named around source and destination stage pairs, such as `data_F_ifid`, `data_D_ifid`, `data_D_idex`, and `data_E_idex`.

Reset is synchronous in the visible sequential RTL. Reset generally clears state to zero or a local `CTRL_NOP`. Flush behavior is implemented by writing zeroed data and NOP control into affected pipeline registers.

The data memory is an exception to the general reset pattern: CPU reset does not erase main memory. Future Cache reset should normally invalidate Cache lines by clearing metadata such as valid bits rather than clearing the SRAM data array. A write-back Cache will also require an explicit policy for dirty lines across reset or flush.

The design favors small single-purpose modules and explicit wiring in `core.sv` rather than hiding datapath behavior behind large abstractions. Comments are a mix of English and Chinese, often teaching-oriented and focused on explaining hardware meaning.

Testbench failure paths use `$fatal(1, ...)` so failed checks return a nonzero process status. Successful completion uses `$finish`.

The current verification tool decision is to keep Verilator plus SystemVerilog directed tests as the default flow. Cocotb is intentionally deferred until Python-driven generation or modeling provides concrete value. Likely triggers include Cache verification with a golden-memory model, randomized memory latency, large parameter combinations, randomized instruction streams, or differential comparison against an ISA reference model. Existing directed SystemVerilog tests should remain as the fast baseline after Cocotb is introduced.

## Current Status and Known Limitations

Implemented or visibly present:

1. Five-stage pipeline skeleton with IF/ID, ID/EX, EX/MEM, and MEM/WB registers.
2. Internal instruction memory and data memory models.
3. Register file with x0 behavior and same-cycle WB read bypass.
4. ALU support for common arithmetic, logical, compare, and shift operations.
5. Decode support for R-type ALU instructions; `addi`, `slti`, `sltiu`,
   `xori`, `ori`, `andi`, `slli`, `srli`, and `srai`; `lb`, `lh`, `lw`, `lbu`,
   `lhu`, `sb`, `sh`, and `sw`; `lui`, `auipc`; all six base branch
   conditions; `jal`; and `jalr`.
6. EX-stage branch/jump redirect handling.
7. EX operand forwarding from MEM ALU results and WB results.
8. Load-use stall insertion.
9. Verilator smoke tests for basic execution, branch flushing, hazards, and
   ALU-immediate plus branch-condition behavior.
10. Module-level Verilator tests for ALU, register file, immediate extension, control decode, data memory, PC target generation, and hazard control.
11. A unified regression script covering seven module tests and four processor
    smoke tests.
12. Assembly source and generated hex images for all four smoke programs, with
    explicit completion markers.
13. A documented verification-tool decision to retain Verilator/SystemVerilog now and defer Cocotb until randomized, parameterized, latency-driven, Cache reference-model, or differential testing justifies it.

Partially implemented or uncertain:

1. Full RV32I support is incomplete. Many opcodes/funct values are declared, but several decode paths are commented out or default to NOP-like behavior.
2. Byte and halfword loads/stores are implemented in the current internal memory
   path, but they are still covered only by directed unit tests rather than
   broad program-level ISA tests.
3. Misaligned instruction and data accesses are not architecturally handled
   yet. The data-memory word index uses address bits `[MEM_ADDR_WIDTH+1:2]`,
   while `load_data` and `store_data` use `[1:0]` for subword lane selection.
   Misaligned halfword and word data accesses currently produce zero/no-write
   behavior rather than traps, and JALR clears only target bit 0. Phase 4 must
   detect unsupported alignment and raise the appropriate exception instead of
   silently correcting or masking the access.
4. Memory bounds behavior is unclear from the repository.
5. `riscv-tests` integration and a failure-tracking record are still missing
   from Phase 3.
6. The current regression is useful but remains a small hand-written baseline
   rather than broad ISA verification.

Not implemented as visible RTL:

1. CSR file and CSR instruction handling.
2. Exceptions and interrupts.
3. External bus or handshake memory interface.
4. SoC wrapper, peripherals, FPGA board integration, cache, FPU, and RTOS support.

## Suggested Next Steps

1. Keep `sim/run_regression.sh` green before and after RTL changes.
2. Add a small compatible subset of `riscv-tests` and record unsupported tests separately from genuine failures.
3. Create a lightweight verification-status or defect-tracking document that classifies failures by module, pipeline stage, or program-level behavior.
4. Expand decode in small, test-backed steps for the remaining RV32I instructions.
5. Document the intended priority order between redirect, load-use stall, memory wait, and future exception flush before adding memory handshakes or CSR traps.
6. Introduce a clearer memory interface boundary before Cache work, since the current memories are internal single-model arrays.
