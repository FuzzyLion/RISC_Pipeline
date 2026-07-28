# Agent Context

This repository is a learning-first SystemVerilog RISC-V CPU project. The
current RTL implements an RV32I-oriented five-stage pipeline core with internal
instruction and data memories, machine-mode CSR and synchronous-trap support,
Verilator smoke tests, a selected `riscv-tests`/`rv32ui` ISA-lite flow, and
planning documents for interrupts, SoC, FPGA, cache, FPU, and RTOS work. The
Phase 3 baseline is established, and Phase 4 now has a working basic CSR/trap
slice, but the design is still intentionally short of full ISA and privileged
architecture compliance.

The code is not a complete RV32I processor yet. The active decode now covers
the full R-type integer ALU group, the RV32I ALU-immediate group, all six base
branch conditions, `lui`, `auipc`, `lb`, `lh`, `lw`, `lbu`, `lhu`, `sb`,
`sh`, `sw`, `jal`, and `jalr`. Decode also covers `ecall`, `ebreak`, `mret`,
`csrrw`, `csrrs`, `csrrc`, `csrrwi`, `csrrsi`, and `csrrci`. Basic synchronous
exceptions and machine CSR state are integrated. A first machine-timer
interrupt path is also wired end to end. Its directed processor smoke proves
one-shot delivery, handler acknowledgement, and return behavior.

## Compact Directory Tree

```text
.
├── AGENTS.md
├── agent_context.md
├── requirements.md
├── docs/
│   ├── data-memory-addressing.md
│   ├── verification.md
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
│   ├── smoke_hazard.hex
│   ├── smoke_csr_trap.s
│   ├── smoke_csr_trap.hex
│   ├── smoke_illegal_trap.s
│   ├── smoke_instr_misaligned_trap.s
│   ├── smoke_load_misaligned_trap.s
│   ├── smoke_store_misaligned_trap.s
│   ├── smoke_timer_interrupt.s
│   └── smoke_timer_interrupt.hex
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
│       ├── soc_addr_map_pkg.sv
│       ├── mmio_decoder.sv
│       ├── machine_timer.sv
│       ├── data_mem.sv
│       ├── load_data.sv
│       ├── WB_result_mux.sv
│       ├── csr_file.sv
│       └── trap_ctrl.sv
├── software/
│   ├── linker/core.ld
│   ├── runtime/trap_handler.s
│   ├── scripts/build_riscv_lite_test.sh
│   └── tests/riscv_lite/
├── sim/
│   ├── build_hex.sh
│   ├── run_isa_lite.sh
│   ├── run_isa_lite_addi.sh
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
│   ├── run_smoke_hazard.sh
│   ├── run_smoke_csr_trap.sh
│   ├── run_smoke_illegal_trap.sh
│   ├── run_smoke_instr_misaligned_trap.sh
│   ├── run_smoke_load_misaligned_trap.sh
│   ├── run_smoke_store_misaligned_trap.sh
│   └── run_smoke_timer_interrupt.sh
└── tb/
    ├── alu_op_tb.sv
    ├── control_unit_tb.sv
    ├── core_basic_smoke_tb.sv
    ├── core_isa_lite_tb.sv
    ├── core_smoke_alu_tb.sv
    ├── core_smoke_branch_tb.sv
    ├── core_smoke_csr_trap_tb.sv
    ├── core_smoke_hazard_tb.sv
    ├── core_smoke_illegal_trap_tb.sv
    ├── core_smoke_instr_misaligned_trap_tb.sv
    ├── core_smoke_load_misaligned_trap_tb.sv
    ├── core_smoke_store_misaligned_trap_tb.sv
    ├── core_smoke_timer_interrupt_tb.sv
    ├── data_mem_tb.sv
    ├── hazard_unit_tb.sv
    ├── imm_ext_tb.sv
    ├── pc_target_gen_tb.sv
    └── reg_file_tb.sv
```

Generated simulation output under `sim/build` is intentionally excluded. The
upstream `tools/riscv-tests/` checkout is also excluded from version control;
keep it as an external reference tree rather than editing it directly.

## Important Files and Modules

`rtl/core/core_types_pkg.sv` defines shared constants, opcode/funct enums, ALU control enums, mux-select enums, packed control bundles, packed pipeline-register data structs, and hazard control structs. This package is the main type contract between pipeline stages.

`rtl/core/top.sv` is a thin wrapper around `core`. Its comment marks it as a future board/SoC wrapper point for clock, reset, memory, and peripherals.

`rtl/core/core.sv` is the main pipeline integration module. It wires control,
PC logic, instruction memory, register file, immediate generation, forwarding
muxes, ALU, branch target generation, pipeline registers, store/load data
alignment, data memory, writeback, hazard control, `csr_file`, `trap_ctrl`, and
the first MMIO machine-timer interrupt path.

`rtl/core/control_unit.sv` decodes the instruction in the Decode stage into
`control_bundle_t` and `imm_src_e`. Implemented active cases include the R-type
ALU instructions, `addi`, `slti`, `sltiu`, `xori`, `ori`, `andi`, `slli`,
`srli`, `srai`, `lb`, `lh`, `lw`, `lbu`, `lhu`, `sb`, `sh`, `sw`, `lui`,
`auipc`, `beq`, `bne`, `blt`, `bge`, `bltu`, `bgeu`, `jal`, and `jalr`.
It also decodes the six supported Zicsr forms plus `ecall`, `ebreak`, and
`mret`, and emits an illegal-instruction event for unsupported encodings.

`rtl/core/hazard_unit.sv` generates forwarding selects plus stall/flush
controls. It forwards MEM ALU or CSR results and WB results into EX operands,
stalls on load-use hazards where an EX-stage load feeds a Decode-stage source,
and flushes Decode/Execute on taken branch/jump, `mret`, or trap redirects.

`rtl/core/IF_ID.sv`, `rtl/core/ID_EX.sv`, `rtl/core/EX_MEM.sv`, and `rtl/core/MEM_WB.sv` are the four pipeline-register modules. They use packed structs from the package, synchronous reset, valid bits, and side-effect control gating so bubbles do not write registers, write memory, branch, or jump.

`rtl/core/pc_reg.sv`, `rtl/core/pc_plus4_adder.sv`, and `rtl/core/pc_mux.sv`
implement the Fetch-stage PC path. The PC register can stall, reset goes to
zero, and the adder computes `PC + 4`. The mux chooses sequential execution,
an EX-stage branch/jump target, `mepc` for `mret`, or `mtvec` for trap entry;
trap entry has priority over the ordinary redirect selector.

`rtl/core/pc_target_gen.sv` computes branch/jump targets and `pc_src_E`.
PC-relative targets use `pc_E + imm_E`; `jalr` uses `alu_src_AE + imm_E` and
clears target bit 0 as required by the ISA. The module cannot determine whether `alu_src_AE` came from
the original operand or a forwarding path; that behavior belongs to the
upstream forwarding mux and integration tests. `alu_op.sv` evaluates all six
RV32I branch conditions and presents the taken/not-taken result through
`zero_E`, which `pc_target_gen` combines with `branch_E`. Because the core does
not implement the compressed-instruction extension, the final taken target
must be 4-byte aligned. A target with bit 1 set emits an
instruction-address-misaligned event; an untaken branch does not.

`rtl/core/instr_mem.sv` is a simple word-array instruction memory initialized with `$readmemh`. It indexes memory using `pc_F[MEM_ADDR_WIDTH+1:2]`, so the core presents byte addresses while the model stores 32-bit instruction words.

`rtl/core/instr_field.sv` extracts `rs1`, `rs2`, and `rd` fields from the Decode-stage instruction.

`rtl/core/imm_ext.sv` sign-extends or forms I, S, B, J, and U immediates. It is combinational and selected by the control unit.

`rtl/core/reg_file.sv` implements 32 RV32 architectural registers with synchronous writeback, combinational reads, x0 hardwired to zero on reads/writes, reset clearing all registers, and same-cycle WB-to-ID read bypassing.

`rtl/core/alu_op.sv` implements add, sub, and, or, xor, pass-B, signed/unsigned
set-less-than, logical shifts, arithmetic right shift, and the AUIPC
`pc_E + U-immediate` operation. It also evaluates BEQ, BNE, BLT, BGE, BLTU, and
BGEU when branch control is active. For an active load or store, it also
classifies halfword/word address misalignment and emits the corresponding trap
event.

`rtl/core/EX_forward_muxAE.sv` selects the EX-stage ALU A operand from the
ID/EX `rs1` value, WB result, MEM ALU result, or MEM CSR read result.

`rtl/core/EX_forward_rd_muxBE.sv` selects the forwarded EX-stage `rs2` value
from the original operand, WB result, MEM ALU result, or MEM CSR read result.
The selected value is used both as store data and as the pre-immediate ALU B
source.

`rtl/core/EX_muxBE.sv` chooses the ALU B operand between forwarded `rs2` data and the EX-stage immediate.

`rtl/core/store_data.sv` prepares store data before the data memory. It uses
the MEM-stage store type and address low bits to shift `rs2` data into the
correct byte lanes and generate a 4-bit write strobe for `sb`, `sh`, and `sw`.
Misaligned `sh` and `sw` produce no write strobe in this formatting block; the
EX-stage alignment event is expected to trap and suppress the faulting
instruction before any architectural store occurs.

`rtl/core/soc_addr_map_pkg.sv` defines the hardware-side MMIO address contract
for the low and high 32-bit halves of `mtimecmp`. Assembly source must define
matching platform addresses separately because the assembler cannot import a
SystemVerilog package.

`rtl/core/mmio_decoder.sv` recognizes aligned full-word stores to the two
`mtimecmp` addresses. It produces the timer write data and low/high write
enables, and prevents timer MMIO writes from aliasing into the internal data
RAM. Timer MMIO reads and partial timer-register writes are not implemented.

`rtl/core/machine_timer.sv` owns internal 64-bit `mtime` and `mtimecmp` state.
`mtime` increments once per core clock, `mtimecmp` resets to its maximum value,
and the level-sensitive `timer_irq` request is asserted while
`mtime >= mtimecmp`. Software must move `mtimecmp` into the future to clear the
request after servicing an interrupt.

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
writeback. Alignment classification belongs to `alu_op` in EX; this module is
only responsible for extracting data for a valid aligned load.

`rtl/core/WB_result_mux.sv` selects the writeback value from ALU result,
post-processed load result, `PC + 4`, or CSR read data.

`rtl/core/csr_file.sv` owns the current machine CSR state: `mstatus`, `mie`,
`mtvec`, `mscratch`, `mepc`, `mcause`, `mtval`, and `mip`. It implements the
project's CSR read/modify/write behavior, rejects unsupported CSR addresses,
records trap metadata and machine-status state on trap entry, and restores the
relevant `mstatus` fields on `mret`. It currently permits software to write
only `mie.MTIE`; `mip.MTIP` is a read-only architectural view of `timer_irq`.
`mtvec` is forced to word alignment, so the implemented path is effectively
Direct mode only.

`rtl/core/trap_ctrl.sv` arbitrates the current trap events. Its
priority is illegal instruction/CSR access, `ecall`, `ebreak`, instruction
address misalignment, load address misalignment, then store address
misalignment. All implemented synchronous exceptions take priority over a
pending and enabled machine-timer interrupt. A taken timer interrupt records
interrupt cause 7. The module produces `mcause`, `mtval`, and `mepc`, requests
the trap PC redirect, and generates pipeline flush controls. This policy layer
does not own CSR storage.

`rtl/core/filelist.f` lists the core RTL files for Verilator builds.

`tb/alu_op_tb.sv`, `tb/reg_file_tb.sv`, `tb/control_unit_tb.sv`,
`tb/imm_ext_tb.sv`, `tb/data_mem_tb.sv`, `tb/pc_target_gen_tb.sv`, and
`tb/hazard_unit_tb.sv` provide focused module-level tests. The ALU and control
testbenches keep one instruction or behavior per task. Test tasks explicitly
apply defaults, assign direct inputs, wait `#1`, and call reusable check tasks.
Coverage includes arithmetic wraparound, signed versus unsigned comparison,
shift behavior, all branch conditions, AUIPC calculation and decode, load/store
decode variants, `zero_E`, CSR/system decode, `mret`, CSR-result forwarding,
trap flushing, and instruction/load/store alignment events.

`tb/data_mem_tb.sv` covers initial zero contents, combinational reads,
synchronous writes, write-disable behavior, byte-lane write strobes, ignored low
address bits for word indexing, and independence of adjacent words.

`tb/pc_target_gen_tb.sv` covers positive and negative PC-relative offsets,
32-bit address wraparound, JALR target calculation and bit-0 clearing, use of
`alu_src_AE` rather than `pc_E`, jump/branch/`mret` redirect decisions, and
taken-versus-untaken instruction-address-misaligned behavior. It intentionally
does not claim to verify where `alu_src_AE` originated.

The ten processor smoke testbenches instantiate `top`,
load one program each, enforce a timeout, and inspect architectural state
hierarchically. The ALU smoke covers ALU-immediate results plus taken and
not-taken cases for the six branch conditions. The CSR/trap smoke covers the
six supported CSR forms, zero-source pure reads, two `ebreak` sites and one
`ecall` site,
handler return and register preservation, and final `mcause`, `mtval`,
`mstatus`, and `mepc` state. Four precise-trap smokes cover illegal instruction,
instruction-address misalignment, load-address misalignment, and store-address
misalignment. Each checks CSR metadata, younger-instruction flushing, and a
cause-specific suppressed side effect: JAL link-register writeback, load
destination writeback, or store memory modification. These are directed smoke
tests, not complete ISA or privileged-architecture verification. The timer
smoke additionally proves MMIO programming of `mtimecmp`, pending interrupt
gating, cause 7 metadata, D/E/M flushing, one-shot acknowledgement, register
preservation under the teaching handler contract, and `mret` recovery.

`sim/run_alu_op.sh`, `sim/run_reg_file.sh`, `sim/run_control_unit.sh`,
`sim/run_imm_ext.sh`, `sim/run_data_mem.sh`, `sim/run_pc_target_gen.sh`, and
`sim/run_hazard_unit.sh` run module-level Verilator tests.
`sim/run_basic_smoke.sh`, `sim/run_smoke_branch.sh`,
`sim/run_smoke_hazard.sh`, `sim/run_smoke_alu.sh`,
`sim/run_smoke_csr_trap.sh`, and the four precise-trap scripts rebuild their
assembly programs and run processor-level smoke tests.
`sim/run_smoke_timer_interrupt.sh` does the same for the timer path.
`sim/run_regression.sh` is the unified entry point and runs seventeen tests:
seven module tests and ten processor smoke tests.
`sim/build_hex.sh` assembles one or more `.s` files into `.hex` using
`riscv64-elf-gcc` with `-march=rv32i_zicsr`, `-mabi=ilp32`, no standard
runtime, and `software/linker/core.ld`. The linker places `.text` at zero and
the optional `.trap` section at the next aligned instruction address.

`programs/smoke_csr_trap.s`, `software/runtime/trap_handler.s`, and
`tb/core_smoke_csr_trap_tb.sv` form the current integrated synchronous-trap
closure. The program initializes `mtvec` from the linked handler symbol and
uses a stable data-memory scratch area required by the minimal handler. This
runtime is a teaching smoke handler, not a general ABI-safe or nested-trap-safe
runtime.

`software/tests/riscv_lite/env/riscv_test.h`,
`software/scripts/build_riscv_lite_test.sh`, `tb/core_isa_lite_tb.sv`, and
`sim/run_isa_lite.sh` form the lightweight selected `riscv-tests` integration.
The local environment replaces the official privileged pass/fail mechanism with
an `x31` completion code. `x31 = 1` means pass; odd values greater than 1 encode
the failing upstream test number as `(x31 - 1) / 2`. This depends on
`TESTNUM = gp = x3` remaining intact until failure handling runs, so a
suspicious or impossible decoded test number may indicate that `x3` was
clobbered by a test or by a writeback destination bug.

`docs/data-memory-addressing.md` explains the current byte-addressed ISA view versus word-array Verilog memory model. It is useful background before changing load/store behavior.

`docs/verification.md` records the Phase 3 verification baseline, including the
ISA-lite build flow, skipped upstream test categories, debugging workflow, and
current limitations.

`docs/plans/` contains roadmap documents for phases beyond the current core, including hazard control, verification, CSR/exceptions/interrupts, SoC/FPGA, cache, FPU, and RTOS integration.

## Architecture Summary

The implemented datapath is organized as a classic five-stage pipeline: IF, ID, EX, MEM, and WB. IF holds and updates the PC, fetches a 32-bit instruction from `instr_mem`, and computes `PC + 4`. ID decodes the instruction, reads the register file, extracts register fields, and generates immediates. EX applies forwarding, selects ALU operands, computes ALU results, computes branch/jump targets, and decides redirects. MEM prepares subword stores, accesses the simple internal data memory, and post-processes load data. WB selects the final result and writes the register file.

Control is generated in Decode as a packed `control_bundle_t`, then carried through later stages with narrower packed control bundles where possible. Pipeline registers carry explicit `valid` bits, and side-effecting controls are gated by validity as they enter later stages.

Branches and jumps are resolved in EX. `pc_target_gen` chooses between
PC-relative targets and `jalr` register-relative targets. JALR clears bit 0 by
ISA definition, after which the current RV32I-only core requires the final
target to be 4-byte aligned. A real redirect flushes Decode and Execute so
wrong-path instructions become bubbles; a misaligned redirect instead enters
the trap path.

AUIPC is also completed in EX. Decode selects `CTRL_PASS_B4PC` and the U-type
immediate; the ALU receives the instruction's pipelined `pc_E` and computes
`pc_E + imm_E`. This uses the AUIPC instruction address, not `PC + 4`.

Forwarding is handled for EX-stage operands. Both register operands can receive
the original value, a WB result, a MEM ALU result, or a MEM CSR read result;
the B-side immediate mux runs after register forwarding. MEM-stage forwarding
excludes load results because load data is not available early enough for the
next EX-stage consumer.

Load-use hazards are detected when a valid EX-stage load writes a nonzero `rd`
that matches either source of a valid Decode-stage instruction. Fetch and
Decode stall while Execute is flushed to insert a bubble. Trap flushes and
redirects have priority over load-use stalls in the current hazard unit.

Synchronous trap sources are classified in Decode or EX, then arbitrated by
`trap_ctrl`. On trap entry, `csr_file` records `mepc`, `mcause`, and `mtval`
and updates `mstatus`; `pc_mux` redirects to `mtvec`. `mret` restores the
implemented machine-status fields and redirects through `mepc`. This is a
basic machine-mode path, not a full privileged implementation.

For the first timer path, an M-stage aligned word store is decoded away from
data RAM and programs one half of `mtimecmp`. Timer expiry drives the read-only
`mip.MTIP` view in `csr_file`; `trap_ctrl` combines it with `mie.MTIE` and
`mstatus.MIE`, taking the interrupt only when no synchronous exception wins.
The one-shot timer smoke proves this path through handler acknowledgement and
`mret`; periodic deadline calculation from the current `mtime` value is not
implemented. External memory handshakes, broader SoC integration, cache, FPU,
and RTOS support remain planning goals in `docs/plans`.

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
   conditions; `jal`; `jalr`; all six project-supported Zicsr forms; `ecall`;
   `ebreak`; and `mret`.
6. EX-stage branch/jump/`mret` redirect handling and trap redirect priority.
7. EX operand forwarding from MEM ALU results, MEM CSR results, and WB results.
8. Load-use stall insertion plus redirect and trap flushing.
9. Machine CSR state for `mstatus`, `mie`, `mtvec`, `mscratch`, `mepc`,
   `mcause`, `mtval`, and `mip`, including basic trap-entry and `mret` updates.
10. Synchronous trap classification for illegal instruction/CSR access,
    `ecall`, `ebreak`, instruction-address misalignment, load-address
    misalignment, and store-address misalignment.
11. Module-level Verilator tests for ALU, register file, immediate extension,
    control decode, data memory, PC target generation, and hazard control,
    including CSR/system and alignment-event cases.
12. Ten processor smoke tests for basic execution, branch flushing, hazards,
    ALU/branches, repeated mixed CSR/ECALL/EBREAK handling, illegal instruction,
    the three implemented address-misalignment trap classes, and one-shot
    machine-timer interrupt delivery.
13. A unified directed regression containing seven module tests and ten
    processor smoke tests.
14. A lightweight selected `riscv-tests`/`rv32ui` flow for current Phase 3-safe
    integer ALU, branch, jump, `lui`, and `auipc` cases.
15. A documented decision to retain Verilator/SystemVerilog now and defer
    Cocotb until randomized, parameterized, latency-driven, Cache
    reference-model, or differential testing justifies it.
16. A first machine-timer interrupt RTL path with MMIO-programmable 64-bit
    `mtimecmp`, an internal 64-bit `mtime`, read-only `mip.MTIP`, software-
    writable `mie.MTIE`, global `mstatus.MIE` gating, and synchronous-exception
    priority over timer delivery. The timer smoke proves MMIO programming,
    interrupt gating, cause 7 metadata, precise flushing, one-shot handler
    acknowledgement, and `mret` recovery; the seventeen-test regression is
    green.

Partially implemented or uncertain:

1. Full architectural RV32I and privileged compliance remains incomplete.
   The current CSR/trap path is a deliberately small machine-mode teaching
   implementation, not a complete privileged architecture.
2. Byte and halfword loads/stores are implemented in the internal memory
   path, but they are still covered only by directed unit tests rather than
   broad program-level ISA tests.
3. Directed program-level tests prove selected alignment traps suppress the
   faulting JAL/load/store side effect, flush a younger register write, and
   preserve an older register write. They do not cover every possible older
   in-flight register or memory side effect or every alignment variant.
4. Illegal-instruction handling has one integrated precise-exception test.
   Unsupported-CSR detection still lacks equivalent program-level coverage.
5. The minimal trap handler is sufficient for the current smoke contract but
   is not a general ABI-safe, reentrant, or nested-trap-safe runtime.
6. Memory bounds behavior is unclear from the repository.
7. The selected `riscv-tests` integration is intentionally lightweight. It does
   not initialize data memory from ELF sections and does not support upstream
   tests that require full CSR/trap/privileged behavior, misaligned
   exception handling, or instruction-cache coherence.
8. The current regression is a focused Phase 3 plus basic-Phase-4 baseline,
   not broad ISA or privileged compliance proof.
9. The timer handler uses a fixed one-shot acknowledgement deadline and clears
   `mie.MTIE`; it does not yet read the current `mtime`, calculate a periodic
   next deadline, or prove repeated timer ticks.

Not implemented as visible RTL:

1. External and software interrupt sources and their delivery paths.
2. Nested trap handling and a production-quality context-save runtime.
3. External bus or handshake memory interface.
4. SoC wrapper, peripherals, FPGA board integration, cache, FPU, and RTOS
   support.

## Suggested Next Steps

1. Keep `sim/run_regression.sh` green before and after RTL changes.
2. Add program-level precise synchronous-exception coverage for unsupported
   CSR access and additional older in-flight side-effect combinations.
3. Keep proving the faulting instruction has no side effect, younger
   instructions are flushed, and older instructions retire exactly once.
4. Extend the one-shot timer path only when needed with readable `mtime` MMIO,
   periodic next-deadline calculation, and repeated-tick verification.
5. Preserve synchronous-exception priority while extending the design later
   with software or external interrupt sources.
6. Preserve the Phase 3 regression, current CSR/trap smoke, and selected
   ISA-lite tests throughout Phase 4.
7. Introduce a clearer memory interface boundary before Cache work, since the
   current memories are internal single-model arrays.
