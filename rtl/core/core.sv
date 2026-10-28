// Pipeline CPU core: datapath + control + hazard

module core
    import core_types_pkg::*;
#(
    parameter string IMEM_INIT_FILE = ""
)
(
    input logic clk,
    input logic reset
);

    // Cross-stage data, control, redirect, and feedback signals.
    hazard_forward_t hazard_forward_ctrl;
    hazard_stallflush_t hazard_stallflush_ctrl;
    logic trap_flush_D;
    logic trap_flush_E;
    logic uses_rs1_D;
    logic uses_rs2_D;
    control_bundle_t ctrl_E;
    ex_mem_control_t ctrl_M;
    mem_wb_control_t ctrl_W;
    pc_src_e pc_src_E;
    pc_src_with_trap_e pc_src_with_trap_E;
    logic [WORD_WIDTH - 1:0] pc_target_in;
    if_id_data_t data_D_ifid;
    id_ex_data_t data_D_idex;
    id_ex_data_t data_E_idex;
    trap_event_e trap_event_illegal_instr_E;
    logic [WORD_WIDTH - 1:0] result_W_out;
    logic [WORD_WIDTH - 1:0] mtvec_reg;
    logic [WORD_WIDTH - 1:0] mepc_reg;
    ex_mem_data_t data_M_exmem;
    logic timer_irq;
    mem_wb_data_t data_W_memwb;

    // Stage modules own their combinational logic and outgoing pipeline register.
    if_stage #(
        .IMEM_INIT_FILE(IMEM_INIT_FILE)
    ) if_stage1 (
        .clk(clk),
        .reset(reset),
        .stall_F(hazard_stallflush_ctrl.stall_F),
        .stall_D(hazard_stallflush_ctrl.stall_D),
        .flush_D(hazard_stallflush_ctrl.flush_D),
        .pc_src_E(pc_src_E),
        .pc_src_with_trap_E(pc_src_with_trap_E),
        .pc_target_in(pc_target_in),
        .mtvec_reg(mtvec_reg),
        .mepc_reg(mepc_reg),
        .data_D_ifid(data_D_ifid)
    );

    id_stage id_stage1 (
        .clk(clk),
        .reset(reset),
        .flush_E(hazard_stallflush_ctrl.flush_E),
        .data_D_ifid(data_D_ifid),
        .rf_write_W(ctrl_W.rf_write),
        .rd_idx_W(data_W_memwb.rd_idx),
        .result_W_out(result_W_out),
        .uses_rs1_D(uses_rs1_D),
        .uses_rs2_D(uses_rs2_D),
        .data_D_idex(data_D_idex),
        .data_E_idex(data_E_idex),
        .ctrl_E(ctrl_E),
        .trap_event_illegal_instr_E(trap_event_illegal_instr_E)
    );

    ex_stage ex_stage1 (
        .clk(clk),
        .reset(reset),
        .hazard_forward_ctrl(hazard_forward_ctrl),
        .ctrl_E(ctrl_E),
        .data_E_idex(data_E_idex),
        .trap_event_illegal_instr_E(trap_event_illegal_instr_E),
        .result_W_out(result_W_out),
        .timer_irq(timer_irq),
        .pc_src_E(pc_src_E),
        .pc_src_with_trap_E(pc_src_with_trap_E),
        .pc_target_in(pc_target_in),
        .mtvec_reg(mtvec_reg),
        .mepc_reg(mepc_reg),
        .trap_flush_D(trap_flush_D),
        .trap_flush_E(trap_flush_E),
        .ctrl_M(ctrl_M),
        .data_M_exmem(data_M_exmem)
    );

    mem_stage mem_stage1 (
        .clk(clk),
        .reset(reset),
        .ctrl_M(ctrl_M),
        .data_M_exmem(data_M_exmem),
        .ctrl_W(ctrl_W),
        .data_W_memwb(data_W_memwb),
        .timer_irq(timer_irq)
    );

    wb_stage wb_stage1 (
        .data_W_memwb(data_W_memwb),
        .result_src_W(ctrl_W.result_src),
        .result_W_out(result_W_out)
    );

    // Hazard control spans Decode, Execute, Memory, and Writeback.
    // Hazard Unit
    hazard_unit hazard_unit1 (
        .valid_D(data_D_idex.valid),
        .valid_E(data_E_idex.valid),
        .valid_M(data_M_exmem.valid),
        .valid_W(data_W_memwb.valid),
        .rs1_idx_D(data_D_idex.rs1_idx),
        .rs2_idx_D(data_D_idex.rs2_idx),
        .rs1_idx_E(data_E_idex.rs1_idx),
        .rs2_idx_E(data_E_idex.rs2_idx),
        .rd_idx_E(data_E_idex.rd_idx),
        .rd_idx_M(data_M_exmem.rd_idx),
        .rd_idx_W(data_W_memwb.rd_idx),
        .ctrl_E(ctrl_E),
        .ctrl_M(ctrl_M),
        .ctrl_W(ctrl_W),
        .uses_rs1_D(uses_rs1_D),
        .uses_rs2_D(uses_rs2_D),
        .pc_src_E(pc_src_E),
        .trap_flush_D(trap_flush_D),
        .trap_flush_E(trap_flush_E),
        .hazard_forward_ctrl(hazard_forward_ctrl),
        .hazard_stallflush_ctrl(hazard_stallflush_ctrl)
    );

endmodule
