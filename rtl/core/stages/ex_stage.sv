// EX: forwarding, ALU/targets, CSR/trap handling, and outgoing EX/MEM register.

module ex_stage
    import core_types_pkg::*;
(
    input logic clk,
    input logic reset,
    input hazard_forward_t hazard_forward_ctrl,
    input control_bundle_t ctrl_E,
    input id_ex_data_t data_E_idex,
    input trap_event_e trap_event_illegal_instr_E,
    input logic [WORD_WIDTH - 1:0] result_W_out,
    input logic timer_irq,
    output pc_src_e pc_src_E,
    output pc_src_with_trap_e pc_src_with_trap_E,
    output logic [WORD_WIDTH - 1:0] pc_target_in,
    output logic [WORD_WIDTH - 1:0] mtvec_reg,
    output logic [WORD_WIDTH - 1:0] mepc_reg,
    output logic trap_flush_D,
    output logic trap_flush_E,
    output ex_mem_control_t ctrl_M,
    output ex_mem_data_t data_M_exmem
);

    // Internal stage signals.
    logic trap_flush_M;
    ex_mem_control_t ctrl_next_E;
    logic [WORD_WIDTH - 1:0] alu_src_AE_out;
    logic [WORD_WIDTH - 1:0] write_data_E_out;
    logic [WORD_WIDTH - 1:0] alu_src_BE_in;
    trap_event_e trap_event_branch_jump_E;
    logic zero_E_out;
    logic [WORD_WIDTH - 1:0] alu_result_E_out;
    trap_event_e trap_event_load_store_E;
    logic trap_entry_E;
    logic csr_en_E;
    logic [WORD_WIDTH - 1:0] trap_mcause_E;
    logic [WORD_WIDTH - 1:0] trap_mtval_E;
    logic [WORD_WIDTH - 1:0] trap_mepc_E;
    logic [WORD_WIDTH - 1:0] csr_rdata_E;
    logic [WORD_WIDTH - 1:0] mstatus_reg;
    logic [WORD_WIDTH - 1:0] mip_reg;
    logic [WORD_WIDTH - 1:0] mie_reg;
    logic illegal_csr_access_E;
    ex_mem_data_t data_E_exmem;

    assign ctrl_next_E = '{
        rf_write: ctrl_E.rf_write,
        result_src: ctrl_E.result_src,
        mem_write: ctrl_E.mem_write,
        load_type: ctrl_E.load_type,
        store_type: ctrl_E.store_type
    };

    assign csr_en_E = ctrl_E.csr_en;

    assign data_E_exmem = '{
        valid: data_E_idex.valid,
        alu_result: alu_result_E_out,
        write_data: write_data_E_out,
        rd_idx: data_E_idex.rd_idx,
        pc_plus4: data_E_idex.pc_plus4,
        csr_rdata: csr_rdata_E
    };

    // EX Source AE MUX for Forwarding & ALU
    EX_forward_muxAE EX_forward_muxAE1 (
        .forward_AE(hazard_forward_ctrl.forward_AE),
        .rs1_val_E(data_E_idex.rs1_val),
        .result_W(result_W_out),
        .alu_result_M(data_M_exmem.alu_result),
        .csr_rdata_M(data_M_exmem.csr_rdata),
        .alu_src_AE(alu_src_AE_out)
    );

    // EX Source BE MUX for Forwarding
    EX_forward_rd_muxBE EX_forward_rd_muxBE1 (
        .forward_rd_BE(hazard_forward_ctrl.forward_BE),
        .rs2_val_E(data_E_idex.rs2_val),
        .result_W(result_W_out),
        .alu_result_M(data_M_exmem.alu_result),
        .csr_rdata_M(data_M_exmem.csr_rdata),
        .write_data_E(write_data_E_out)
    );

    // EX Source MUX for ALU
    EX_muxBE EX_muxBE1 (
        .alu_src_E(ctrl_E.alu_src),
        .write_data_E(write_data_E_out),
        .imm_E(data_E_idex.imm),
        .alu_src_BE(alu_src_BE_in)
    );

    // Target PC Generator
    pc_target_gen pc_target_gen1 (
        .pc_target_src_E(ctrl_E.pc_target_src),
        .jump_E(ctrl_E.jump),
        .branch_E(ctrl_E.branch),
        .zero_E(zero_E_out),
        .mret_en_E(ctrl_E.mret_en),
        .pc_E(data_E_idex.pc),
        .alu_src_AE(alu_src_AE_out),
        .imm_E(data_E_idex.imm),
        .trap_event_branch_jump_E(trap_event_branch_jump_E),
        .pc_target_E(pc_target_in),
        .pc_src_E(pc_src_E)
    );

    // ALU
    alu_op alu_op1 (
        .alu_control_E(ctrl_E.alu_ctrl),
        .mem_write_E(ctrl_E.mem_write),
        .btype_E(ctrl_E.btype),
        .load_type_E(ctrl_E.load_type),
        .store_type_E(ctrl_E.store_type),
        .result_src_E(ctrl_E.result_src),
        .branch_E(ctrl_E.branch),
        .alu_src_AE(alu_src_AE_out),
        .alu_src_BE(alu_src_BE_in),
        .pc_E(data_E_idex.pc),
        .trap_event_load_store_E(trap_event_load_store_E),
        .zero_E(zero_E_out),
        .alu_result_E(alu_result_E_out)
    );

    // Trap Control
    trap_ctrl trap_ctrl1 (
        .valid_E(data_E_idex.valid),
        .instr_E(data_E_idex.instr),
        .pc_E(data_E_idex.pc),
        .pc_target_E(pc_target_in),
        .alu_result_E(alu_result_E_out),
        .trap_event_illegal_instr_E(trap_event_illegal_instr_E),
        .trap_event_branch_jump_E(trap_event_branch_jump_E),
        .trap_event_load_store_E(trap_event_load_store_E),
        .illegal_csr_access_E(illegal_csr_access_E),
        .mstatus_reg(mstatus_reg),
        .mip_reg(mip_reg),
        .mie_reg(mie_reg),
        .pc_src_with_trap_E(pc_src_with_trap_E),
        .trap_mcause_E(trap_mcause_E),
        .trap_mtval_E(trap_mtval_E),
        .trap_mepc_E(trap_mepc_E),
        .trap_flush_D(trap_flush_D),
        .trap_flush_E(trap_flush_E),
        .trap_flush_M(trap_flush_M),
        .trap_entry_E(trap_entry_E)
    );

    // CSR File
    csr_file csr_file1 (
        .clk(clk),
        .reset(reset),
        .valid_E(data_E_idex.valid),
        .csr_en_E(csr_en_E),
        .mret_en_E(ctrl_E.mret_en),
        .timer_irq(timer_irq),
        .instr_E(data_E_idex.instr),
        .rs1_val_E(alu_src_AE_out),
        .rs1_idx_E(data_E_idex.rs1_idx),
        .imm_E(data_E_idex.imm),
        .csrtype_E(ctrl_E.csrtype),
        .trap_entry_E(trap_entry_E),
        .trap_mcause_E(trap_mcause_E),
        .trap_mtval_E(trap_mtval_E),
        .trap_mepc_E(trap_mepc_E),
        .csr_rdata_E(csr_rdata_E),
        .mstatus_reg(mstatus_reg),
        .mtvec_reg(mtvec_reg),
        .mepc_reg(mepc_reg),
        .mip_reg(mip_reg),
        .mie_reg(mie_reg),
        .illegal_csr_access_E(illegal_csr_access_E)
    );

    // EX_MEM Pipeline Register
    EX_MEM EX_MEM1 (
        .clk(clk),
        .reset(reset),
        .ctrl_next_E(ctrl_next_E),
        .data_E(data_E_exmem),
        .trap_flush_M(trap_flush_M),
        .ctrl_M(ctrl_M),
        .data_M(data_M_exmem)
    );

endmodule
