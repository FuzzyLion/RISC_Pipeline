module hazard_unit 
    import core_types_pkg::*;
(
    input logic valid_D,
    input logic valid_E,

    input logic [ADDR_WIDTH - 1:0] rs1_idx_D,
    input logic [ADDR_WIDTH - 1:0] rs2_idx_D,

    input logic [ADDR_WIDTH - 1:0] rs1_idx_E,
    input logic [ADDR_WIDTH - 1:0] rs2_idx_E,

    input logic [ADDR_WIDTH - 1:0] rd_idx_E,
    input logic [ADDR_WIDTH - 1:0] rd_idx_M,
    input logic [ADDR_WIDTH - 1:0] rd_idx_W,

    input control_bundle_t ctrl_E,
    input ex_mem_control_t ctrl_M,
    input mem_wb_control_t ctrl_W,
    
    input pc_src_e pc_src_E,

    output hazard_bundle_t hazard_ctrl
); 

    logic m_can_forward;
    logic w_can_forward;
    logic lwstall;
    logic redirect;

    localparam hazard_bundle_t HAZARD_CTRL_NOP = '{
        stall_F: 1'b0,
        stall_D: 1'b0,
        flush_D: 1'b0,
        flush_E: 1'b0,
        forward_AE: AE_RS1_VAL,
        forward_BE: BE_RDATA_RS2_VAL
    };

    always_comb begin
        hazard_ctrl = HAZARD_CTRL_NOP;

        // Case 1: Forward
        // Gerneral patterns
        m_can_forward = ctrl_M.rf_write && (ctrl_M.result_src != RSLT_RDATA) && (rd_idx_M != '0);
        w_can_forward = ctrl_W.rf_write && (rd_idx_W != '0);

        // RAW from MEM ALU result
        if (m_can_forward && (rs1_idx_E == rd_idx_M)) begin
            hazard_ctrl.forward_AE = AE_ALU_RESULT_M;
        end
        else if (w_can_forward && (rs1_idx_E == rd_idx_W)) begin
            hazard_ctrl.forward_AE = AE_RESULT_W;
        end 

        // RAW from WB result
        if (m_can_forward && (rs2_idx_E == rd_idx_M)) begin
            hazard_ctrl.forward_BE = BE_RDATA_ALU_RESULT_M;
        end
        else if (w_can_forward && (rs2_idx_E == rd_idx_W)) begin
            hazard_ctrl.forward_BE = BE_RDATA_RESULT_W;
        end

        // Case 2 & 3: Load use & Branch
        lwstall =   valid_D &&
                    valid_E &&
                    (rs1_idx_D != '0) &&
                    (ctrl_E.result_src == RSLT_RDATA) &&
                    ((rs1_idx_D == rd_idx_E) || (rs2_idx_D == rd_idx_E));

        redirect = (pc_src_E == PC_TARGET);

        // Load-use: E load feeds D
        if (lwstall) begin
            hazard_ctrl.stall_F = 1'b1;
            hazard_ctrl.stall_D = 1'b1;
            hazard_ctrl.flush_E = 1'b1;
        end
        // Taken branch or jump in EX
        else if (redirect) begin
            hazard_ctrl.flush_D = 1'b1;
            hazard_ctrl.flush_E = 1'b1; 
        end
    end
    
endmodule
