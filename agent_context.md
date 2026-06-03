# Agent Context

This repository is a learning-first SystemVerilog RISC-V CPU project. The current RTL implements a small RV32I-oriented five-stage pipeline core with internal instruction and data memories, Verilator smoke tests, and planning documents for later CSR, exception, interrupt, SoC, FPGA, cache, FPU, and RTOS work. The design goal visible in the repository is to make the basic pipelined core and hazard behavior understandable and verifiable before adding larger system features.

The code is not a complete RV32I processor yet. The package lists many RV32I encodings, but the active decode currently covers a smaller subset used by the smoke programs.

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
│       ├── data_mem.sv
│       └── WB_result_mux.sv
├── sim/
│   ├── build_hex.sh
│   ├── run_smoke.sh
│   ├── run_smoke_branch.sh
│   └── run_smoke_hazard.sh
└── tb/
    ├── core_smoke_tb.sv
    ├── core_smoke_branch_tb.sv
    └── core_smoke_hazard_tb.sv
```

Empty or currently fileless directories such as `rtl/soc`, `fpga`, `software`, and `tools` exist in the working tree but do not contain source files visible to `rg --files` at the time this document was written. Generated simulation output under `sim/build` is intentionally excluded.

## Important Files and Modules

`rtl/core/core_types_pkg.sv` defines shared constants, opcode/funct enums, ALU control enums, mux-select enums, packed control bundles, packed pipeline-register data structs, and hazard control structs. This package is the main type contract between pipeline stages.

`rtl/core/top.sv` is a thin wrapper around `core`. Its comment marks it as a future board/SoC wrapper point for clock, reset, memory, and peripherals.

`rtl/core/core.sv` is the main pipeline integration module. It wires control, PC logic, instruction memory, register file, immediate generation, forwarding muxes, ALU, branch target generation, pipeline registers, data memory, writeback mux, and the hazard unit.

`rtl/core/control_unit.sv` decodes the instruction in the Decode stage into `control_bundle_t` and `imm_src_e`. Implemented active cases include R-type ALU operations, `lw`, `addi`, `lui`, `sw`, `beq`, `jal`, and `jalr`; several other RV32I forms are present as enums or comments but are not active decode paths.

`rtl/core/hazard_unit.sv` generates forwarding selects plus stall/flush controls. It forwards MEM non-load ALU results and WB results into EX operands, stalls on load-use hazards where an EX-stage load feeds a Decode-stage source, and flushes Decode/Execute on taken branch or jump redirects from EX.

`rtl/core/IF_ID.sv`, `rtl/core/ID_EX.sv`, `rtl/core/EX_MEM.sv`, and `rtl/core/MEM_WB.sv` are the four pipeline-register modules. They use packed structs from the package, synchronous reset, valid bits, and side-effect control gating so bubbles do not write registers, write memory, branch, or jump.

`rtl/core/pc_reg.sv`, `rtl/core/pc_plus4_adder.sv`, and `rtl/core/pc_mux.sv` implement the Fetch-stage PC path. The PC register can stall, reset goes to zero, the adder computes `PC + 4`, and the mux chooses either the sequential PC or an EX-stage redirect target.

`rtl/core/pc_target_gen.sv` computes branch/jump targets and `pc_src_E`. PC-relative targets use `pc_E + imm_E`; `jalr` uses forwarded `rs1` data plus immediate and clears bit 0. Branch decision currently uses `branch_E && zero_E`, so implemented branch behavior is centered on `beq`.

`rtl/core/instr_mem.sv` is a simple word-array instruction memory initialized with `$readmemh`. It indexes memory using `pc_F[MEM_ADDR_WIDTH+1:2]`, so the core presents byte addresses while the model stores 32-bit instruction words.

`rtl/core/instr_field.sv` extracts `rs1`, `rs2`, and `rd` fields from the Decode-stage instruction.

`rtl/core/imm_ext.sv` sign-extends or forms I, S, B, J, and U immediates. It is combinational and selected by the control unit.

`rtl/core/reg_file.sv` implements 32 RV32 architectural registers with synchronous writeback, combinational reads, x0 hardwired to zero on reads/writes, reset clearing all registers, and same-cycle WB-to-ID read bypassing.

`rtl/core/alu_op.sv` implements the ALU operations currently represented by `alu_ctrl_e`: add, sub, and, or, xor, pass-B, signed/unsigned set-less-than, logical shifts, and arithmetic right shift. It also produces `zero_E` from the final ALU result.

`rtl/core/EX_forward_muxAE.sv` selects the EX-stage ALU A operand from the ID/EX `rs1` value, WB result, or MEM ALU result.

`rtl/core/EX_forward_rd_muxBE.sv` selects the forwarded EX-stage `rs2` value used both as store write data and as the pre-immediate ALU B source.

`rtl/core/EX_muxBE.sv` chooses the ALU B operand between forwarded `rs2` data and the EX-stage immediate.

`rtl/core/data_mem.sv` is a simple word-array data memory with combinational read and synchronous write. It treats ALU results as byte addresses and indexes the internal word array with address bits `[MEM_ADDR_WIDTH+1:2]`; only word-level behavior is modeled.

`rtl/core/WB_result_mux.sv` selects the writeback value from ALU result, memory read data, or `PC + 4`.

`rtl/core/filelist.f` lists the core RTL files for Verilator builds.

`tb/core_smoke_tb.sv`, `tb/core_smoke_branch_tb.sv`, and `tb/core_smoke_hazard_tb.sv` instantiate `top`, load one hex program each, run for a fixed cycle count, and inspect internal register file/data memory state hierarchically. These are smoke tests, not a complete ISA verification environment.

`sim/run_smoke.sh`, `sim/run_smoke_branch.sh`, and `sim/run_smoke_hazard.sh` build and run the corresponding Verilator testbenches with tracing enabled. `sim/build_hex.sh` assembles `.s` files into `.hex` using `riscv64-elf-gcc` with `-march=rv32i`, `-mabi=ilp32`, no runtime, and text base zero.

`docs/data-memory-addressing.md` explains the current byte-addressed ISA view versus word-array Verilog memory model. It is useful background before changing load/store behavior.

`docs/plans/` contains roadmap documents for phases beyond the current core, including hazard control, verification, CSR/exceptions/interrupts, SoC/FPGA, cache, FPU, and RTOS integration.

## Architecture Summary

The implemented datapath is organized as a classic five-stage pipeline: IF, ID, EX, MEM, and WB. IF holds and updates the PC, fetches a 32-bit instruction from `instr_mem`, and computes `PC + 4`. ID decodes the instruction, reads the register file, extracts register fields, and generates immediates. EX applies forwarding, selects ALU operands, computes ALU results, computes branch/jump targets, and decides redirects. MEM accesses the simple internal data memory. WB selects the final result and writes the register file.

Control is generated in Decode as a packed `control_bundle_t`, then carried through later stages with narrower packed control bundles where possible. Pipeline registers carry explicit `valid` bits, and side-effecting controls are gated by validity as they enter later stages.

Branches and jumps are resolved in EX. `pc_target_gen` chooses between PC-relative targets and `jalr` register-relative targets. When `pc_src_E` selects the target path, the hazard unit flushes Decode and Execute so wrong-path instructions are converted into bubbles.

Forwarding is handled for EX-stage operands. The A operand can come from the original `rs1`, WB result, or MEM ALU result. The B-side register data can come from original `rs2`, WB result, or MEM ALU result, and then a separate mux chooses between that register data and the immediate for the actual ALU B input. MEM-stage forwarding excludes load results because load data is not available early enough for the next EX-stage consumer.

Load-use hazards are detected when a valid EX-stage load writes a nonzero `rd` that matches either source of a valid Decode-stage instruction. In that case Fetch and Decode stall, while Execute is flushed to insert a bubble. Redirects have priority over load-use stalls in the current hazard unit.

CSR, exceptions, interrupts, external memory handshakes, SoC integration, cache, FPU, and RTOS support are not visible as implemented RTL in the current source tree. They appear as planning goals in `docs/plans`.

## Coding Conventions Visible in the Repository

The RTL uses SystemVerilog modules with `logic`, `always_comb`, `always_ff @(posedge clk)`, package imports through `import core_types_pkg::*`, typedef enums for opcodes/control selects, and packed structs for control/data bundles. Most combinational modules use `case` statements with explicit defaults.

Names commonly encode pipeline stage suffixes such as `_F`, `_D`, `_E`, `_M`, and `_W`. Pipeline-register payloads are named around source and destination stage pairs, such as `data_F_ifid`, `data_D_ifid`, `data_D_idex`, and `data_E_idex`.

Reset is synchronous in the visible sequential RTL. Reset generally clears state to zero or a local `CTRL_NOP`. Flush behavior is implemented by writing zeroed data and NOP control into affected pipeline registers.

The design favors small single-purpose modules and explicit wiring in `core.sv` rather than hiding datapath behavior behind large abstractions. Comments are a mix of English and Chinese, often teaching-oriented and focused on explaining hardware meaning.

## Current Status and Known Limitations

Implemented or visibly present:

1. Five-stage pipeline skeleton with IF/ID, ID/EX, EX/MEM, and MEM/WB registers.
2. Internal instruction memory and data memory models.
3. Register file with x0 behavior and same-cycle WB read bypass.
4. ALU support for common arithmetic, logical, compare, and shift operations.
5. Decode support for the smoke-test subset: R-type ALU operations, `addi`, `lw`, `sw`, `lui`, `beq`, `jal`, and `jalr`.
6. EX-stage branch/jump redirect handling.
7. EX operand forwarding from MEM ALU results and WB results.
8. Load-use stall insertion.
9. Verilator smoke tests for basic execution, branch flushing, and hazards.

Partially implemented or uncertain:

1. Full RV32I support is incomplete. Many opcodes/funct values are declared, but several decode paths are commented out or default to NOP-like behavior.
2. Only `lw` and `sw` are visibly active for memory operations. Byte and halfword loads/stores are not implemented in the current control/data memory path.
3. Branch support appears limited to `beq`; other branch funct3 cases are not active.
4. Misaligned instruction or data access behavior is unclear from repository.
5. Memory bounds behavior is unclear from repository.
6. Formal tests, riscv-tests integration, and broader regression infrastructure are not visible in the current files.

Not implemented as visible RTL:

1. CSR file and CSR instruction handling.
2. Exceptions and interrupts.
3. External bus or handshake memory interface.
4. SoC wrapper, peripherals, FPGA board integration, cache, FPU, and RTOS support.

## Suggested Next Steps

1. Run and keep the three smoke tests green before changing pipeline control: `sim/run_smoke.sh`, `sim/run_smoke_branch.sh`, and `sim/run_smoke_hazard.sh`.
2. Expand decode in small, test-backed steps for the remaining RV32I instructions, starting with the commented I-type, branch, load, and store cases.
3. Add focused tests for each hazard class: MEM-to-EX forwarding, WB-to-EX forwarding, WB-to-ID register-file bypass, load-use stall, taken branch flush, `jal`, and `jalr`.
4. Document the intended priority order between redirect, load-use stall, memory wait, and future exception flush before adding memory handshakes or CSR traps.
5. Introduce a clearer memory interface boundary before cache work, since the current memories are internal single-model arrays.
6. Add riscv-tests or another ISA-level regression flow once the implemented instruction subset is broad enough to make those tests meaningful.
7. Document module interfaces for `core`, `hazard_unit`, `control_unit`, and the pipeline registers so future changes remain interview-defensible.
