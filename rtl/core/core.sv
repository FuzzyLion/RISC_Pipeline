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

    // Hazard Unit
    hazard_forward_t hazard_forward_ctrl;
    hazard_stallflush_t hazard_stallflush_ctrl;
    logic trap_flush_D;
    logic trap_flush_E;
    logic trap_flush_M;

    // Control Unit
    control_bundle_t ctrl_D;
    imm_src_e imm_src_D;
    trap_event_e trap_event_illegal_instr_D;

    // Uniform Control Signal - inner signal
    control_bundle_t ctrl_E;
    ex_mem_control_t ctrl_next_E;
    ex_mem_control_t ctrl_M;
    mem_wb_control_t ctrl_next_M;
    mem_wb_control_t ctrl_W;

    // pc_mux
    pc_src_e pc_src_E;
    pc_src_with_trap_e pc_src_with_trap_E;
    logic [WORD_WIDTH - 1:0] pc_target_in;
    logic [WORD_WIDTH - 1:0] pc_pre_out;

    // pc_reg
    logic [WORD_WIDTH - 1:0] pc_F_out;

    // pc_plus4_adder
    logic [WORD_WIDTH - 1:0] pc_plus4_F_out;

    // instr_mem
    logic [WORD_WIDTH - 1:0] instr_F_out;

    // IF_ID
    if_id_data_t data_F_ifid;
    if_id_data_t data_D_ifid;

    // reg_file
    logic [WORD_WIDTH - 1:0] rs1_val_D_out;
    logic [WORD_WIDTH - 1:0] rs2_val_D_out;

    // imm_ext
    logic [WORD_WIDTH - 1:0] imm_D_out;

    //instr_field
    logic [ADDR_WIDTH - 1:0] rs1_idx_D_out;
    logic [ADDR_WIDTH - 1:0] rs2_idx_D_out;
    logic [ADDR_WIDTH - 1:0] rd_idx_D_out;

    // ID_EX
    id_ex_data_t data_D_idex;
    id_ex_data_t data_E_idex;
    trap_event_e trap_event_illegal_instr_E;

    // EX_forward_muxAE
    logic [WORD_WIDTH - 1:0] result_W_out;
    logic [WORD_WIDTH - 1:0] alu_src_AE_out;

    // EX_forward_rd_muxBE
    logic [WORD_WIDTH - 1:0] write_data_E_out;

    // EX_muxBE
    logic [WORD_WIDTH - 1:0] alu_src_BE_in;

    // pc_target_gen
    trap_event_e trap_event_branch_jump_E;

    // alu_op
    logic zero_E_out;
    logic [WORD_WIDTH - 1:0] alu_result_E_out;
    trap_event_e trap_event_load_store_E;

    // trap_ctrl
    logic trap_entry_E;

    // csr_file
    logic csr_en_E;
    logic [WORD_WIDTH - 1:0] trap_mcause_E;
    logic [WORD_WIDTH - 1:0] trap_mtval_E;
    logic [WORD_WIDTH - 1:0] trap_mepc_E;
    logic [WORD_WIDTH - 1:0] csr_rdata_E;
    logic [WORD_WIDTH - 1:0] mtvec_reg;
    logic [WORD_WIDTH - 1:0] mepc_reg;
    logic illegal_csr_access_E;

    // EX_MEM
    ex_mem_data_t data_E_exmem;
    ex_mem_data_t data_M_exmem;

    // store_data
    logic [3:0] store_wstrb_M_en;
    logic [WORD_WIDTH - 1:0] store_wdata_M_out;

    // data_mem
    logic [WORD_WIDTH - 1:0] mem_rdata_M_out;

    // load_data
    logic [WORD_WIDTH - 1:0] load_result_M_out;

    // MEM_WB
    mem_wb_data_t data_M_memwb;
    mem_wb_data_t data_W_memwb;

    // WB_result_mux

    // ------------------------ PORTS ASSIGNMENTS ------------------------
    // Control Next Signals
    assign ctrl_next_E = '{
        rf_write: ctrl_E.rf_write,
        result_src: ctrl_E.result_src,
        mem_write: ctrl_E.mem_write,
        load_type: ctrl_E.load_type,
        store_type: ctrl_E.store_type
    };

    assign ctrl_next_M = '{
        rf_write: ctrl_M.rf_write,
        result_src: ctrl_M.result_src
    };

    assign csr_en_E = ctrl_E.csr_en;

    // IF_ID
    assign data_F_ifid = '{
        valid: 1'b1,
        pc: pc_F_out,
        instr: instr_F_out,
        pc_plus4: pc_plus4_F_out
    };

    // ID_EX
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

    // EX_MEM
    assign data_E_exmem = '{
        valid: data_E_idex.valid,
        alu_result: alu_result_E_out,
        write_data: write_data_E_out,
        rd_idx: data_E_idex.rd_idx,
        pc_plus4: data_E_idex.pc_plus4,
        csr_rdata: csr_rdata_E
    };

    // MEM_WB
    assign data_M_memwb = '{
        valid: data_M_exmem.valid,
        alu_result: data_M_exmem.alu_result,
        load_result: load_result_M_out,
        rd_idx: data_M_exmem.rd_idx,
        pc_plus4: data_M_exmem.pc_plus4,
        csr_rdata: data_M_exmem.csr_rdata
    };

    // ---------------------- MODULE INSTANTIATIONS ----------------------
    // Control Unit
    control_unit control_unit1 (
        .instr_D(data_D_ifid.instr),
        .imm_src_D(imm_src_D),
        .trap_event_illegal_instr_D(trap_event_illegal_instr_D),
        .ctrl_D(ctrl_D)
    );

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
        .pc_src_E(pc_src_E),
        .trap_flush_D(trap_flush_D),
        .trap_flush_E(trap_flush_E),
        .hazard_forward_ctrl(hazard_forward_ctrl),
        .hazard_stallflush_ctrl(hazard_stallflush_ctrl)
    );

    // PC MUX
    pc_mux pc_mux1 (
        .pc_src_E(pc_src_E),
        .pc_src_with_trap_E(pc_src_with_trap_E),
        .pc_target_E(pc_target_in),
        .pc_plus4_F(pc_plus4_F_out),
        .mtvec_reg(mtvec_reg),
        .mepc_reg(mepc_reg),
        .pc_pre_F(pc_pre_out)
    );

    // PC Reg
    pc_reg pc_reg1 (
        .clk(clk),
        .reset(reset),
        .stall_F(hazard_stallflush_ctrl.stall_F),
        .pc_pre_F(pc_pre_out),
        .pc_F(pc_F_out)
    );

    // PC4adder
    pc_plus4_adder pc_plus4_adder1 (
        .pc_F(pc_F_out),
        .pc_plus4_F(pc_plus4_F_out)
    );

    // Instruction Memory
    instr_mem #(
        .INIT_FILE(IMEM_INIT_FILE)
    ) instr_mem1 (
        .pc_F(pc_F_out),
        .instr_F(instr_F_out)
    );

    // IF_ID Pipeline Register
    IF_ID IF_ID1 (
        .clk(clk),
        .reset(reset),
        .stall_D(hazard_stallflush_ctrl.stall_D),
        .flush_D(hazard_stallflush_ctrl.flush_D),
        .data_F(data_F_ifid),
        .data_D(data_D_ifid)
    );

    // Register File
    reg_file reg_file1 (
        .clk(clk),
        .reset(reset),
        .rf_write_W(ctrl_W.rf_write),
        .rs1_idx_rf(rs1_idx_D_out),
        .rs2_idx_rf(rs2_idx_D_out),
        .rd_idx_W(data_W_memwb.rd_idx),
        .WB_mux_result(result_W_out),
        .rs1_val_D(rs1_val_D_out),
        .rs2_val_D(rs2_val_D_out)
    );

    // Immediate Extention
    imm_ext imm_ext1 (
        .imm_src_D(imm_src_D),
        .instr_D(data_D_ifid.instr), // No double assignment
        .imm_D(imm_D_out)
    );

    //Instruction Decode Field
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
        .flush_E(hazard_stallflush_ctrl.flush_E),
        .ctrl_D(ctrl_D),
        .ctrl_E(ctrl_E),
        .data_D(data_D_idex),
        .trap_event_illegal_instr_D(trap_event_illegal_instr_D),
        .data_E(data_E_idex),
        .trap_event_illegal_instr_E(trap_event_illegal_instr_E)
    );

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
        .mtvec_reg(mtvec_reg),
        .mepc_reg(mepc_reg),
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

    // Store Data Instructions Alignment
    store_data store_data1 (
        .store_type_M(ctrl_M.store_type),
        .alu_result_M(data_M_exmem.alu_result),
        .write_data_M(data_M_exmem.write_data),
        .store_wdata_M(store_wdata_M_out),
        .store_wstrb_M(store_wstrb_M_en)
    );

    // Data Memory
    data_mem data_mem1 (
        .clk(clk),
        .mem_write_M(ctrl_M.mem_write),
        .alu_result_M(data_M_exmem.alu_result),
        .store_wdata_M(store_wdata_M_out),
        .store_wstrb_M(store_wstrb_M_en),
        .mem_rdata_M(mem_rdata_M_out)
    );

    // Load Data Instructions Alignment
    load_data load_data1 (
        .load_type_M(ctrl_M.load_type),
        .alu_result_M(data_M_exmem.alu_result),
        .mem_rdata_M(mem_rdata_M_out),
        .load_result_M(load_result_M_out)
    );

    // MEM_WB Pipeline Register
    MEM_WB MEM_WB1 (
        .clk(clk),
        .reset(reset),
        .ctrl_next_M(ctrl_next_M),
        .data_M(data_M_memwb),
        .ctrl_W(ctrl_W),
        .data_W(data_W_memwb)
    );

    // WB Result MUX
    WB_result_mux WB_result_mux1 (
        .alu_result_W(data_W_memwb.alu_result),
        .load_result_W(data_W_memwb.load_result),
        .pc_plus4_W(data_W_memwb.pc_plus4),
        .csr_rdata_W(data_W_memwb.csr_rdata),
        .result_src_W(ctrl_W.result_src),
        .result_W(result_W_out)
    );

endmodule
