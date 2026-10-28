// ID: decode, register reads, immediate generation, and outgoing ID/EX register.

module id_stage
    import core_types_pkg::*;
(
    input logic clk,
    input logic reset,
    input logic flush_E,
    input if_id_data_t data_D_ifid,
    input logic rf_write_W,
    input logic [ADDR_WIDTH - 1:0] rd_idx_W,
    input logic [WORD_WIDTH - 1:0] result_W_out,
    output logic uses_rs1_D,
    output logic uses_rs2_D,
    output id_ex_data_t data_D_idex,
    output id_ex_data_t data_E_idex,
    output control_bundle_t ctrl_E,
    output trap_event_e trap_event_illegal_instr_E
);

    // Internal stage signals.
    control_bundle_t ctrl_D;
    imm_src_e imm_src_D;
    trap_event_e trap_event_illegal_instr_D;
    logic [WORD_WIDTH - 1:0] rs1_val_D_out;
    logic [WORD_WIDTH - 1:0] rs2_val_D_out;
    logic [WORD_WIDTH - 1:0] imm_D_out;
    logic [ADDR_WIDTH - 1:0] rs1_idx_D_out;
    logic [ADDR_WIDTH - 1:0] rs2_idx_D_out;
    logic [ADDR_WIDTH - 1:0] rd_idx_D_out;

    assign data_D_idex = '{
        valid: data_D_ifid.valid,
        pc: data_D_ifid.pc,
        instr: data_D_ifid.instr,
        pc_plus4: data_D_ifid.pc_plus4,
        rs1_idx: rs1_idx_D_out,
        rs2_idx: rs2_idx_D_out,
        rd_idx: rd_idx_D_out,
        rs1_val: rs1_val_D_out,
        rs2_val: rs2_val_D_out,
        imm: imm_D_out
    };

    // Control Unit
    control_unit control_unit1 (
        .instr_D(data_D_ifid.instr),
        .uses_rs1_D(uses_rs1_D),
        .uses_rs2_D(uses_rs2_D),
        .imm_src_D(imm_src_D),
        .trap_event_illegal_instr_D(trap_event_illegal_instr_D),
        .ctrl_D(ctrl_D)
    );

    // Register File
    reg_file reg_file1 (
        .clk(clk),
        .reset(reset),
        .rf_write_W(rf_write_W),
        .rs1_idx_rf(rs1_idx_D_out),
        .rs2_idx_rf(rs2_idx_D_out),
        .rd_idx_W(rd_idx_W),
        .WB_mux_result(result_W_out),
        .rs1_val_D(rs1_val_D_out),
        .rs2_val_D(rs2_val_D_out)
    );

    // Immediate Extension
    imm_ext imm_ext1 (
        .imm_src_D(imm_src_D),
        .instr_D(data_D_ifid.instr),
        .imm_D(imm_D_out)
    );

    // Instruction Decode Field
    instr_field instr_field1 (
        .instr_D(data_D_ifid.instr),
        .rs1_idx_D(rs1_idx_D_out),
        .rs2_idx_D(rs2_idx_D_out),
        .rd_idx_D(rd_idx_D_out)
    );

    // ID_EX Pipeline Register
    ID_EX ID_EX1 (
        .clk(clk),
        .reset(reset),
        .flush_E(flush_E),
        .ctrl_D(ctrl_D),
        .ctrl_E(ctrl_E),
        .data_D(data_D_idex),
        .trap_event_illegal_instr_D(trap_event_illegal_instr_D),
        .data_E(data_E_idex),
        .trap_event_illegal_instr_E(trap_event_illegal_instr_E)
    );

endmodule
