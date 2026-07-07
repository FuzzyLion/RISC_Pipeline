module hazard_unit 
    import core_types_pkg::*;
(
    input logic valid_D,
    input logic valid_E,
    input logic valid_M,
    input logic valid_W,

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

    input logic trap_flush_D,
    input logic trap_flush_E,

    output hazard_forward_t hazard_forward_ctrl,
    output hazard_stallflush_t hazard_stallflush_ctrl
); 

    logic m_can_forward;
    logic w_can_forward;
    logic lwstall;
    logic redirect;

    localparam hazard_forward_t HAZARD_FORWARD_NOP = '{
        forward_AE: AE_RS1_VAL,
        forward_BE: BE_RDATA_RS2_VAL
    };
    localparam hazard_stallflush_t HAZARD_STALLFLUSH_NOP = '{
        stall_F: '0,
        stall_D: '0,
        flush_D: '0,
        flush_E: '0
    };

    always_comb begin
        hazard_forward_ctrl = HAZARD_FORWARD_NOP;
        hazard_stallflush_ctrl = HAZARD_STALLFLUSH_NOP;

        // Case 1: Forward
        // Gerneral patterns
        m_can_forward = valid_E &&
                        valid_M &&
                        ctrl_M.rf_write && 
                        (ctrl_M.result_src != RSLT_RDATA) && 
                        (rd_idx_M != '0);
        w_can_forward = valid_E &&
                        valid_W &&
                        ctrl_W.rf_write && 
                        (rd_idx_W != '0);

        // RAW from MEM ALU result
        if (m_can_forward && (rs1_idx_E == rd_idx_M)) begin
            hazard_forward_ctrl.forward_AE = AE_ALU_RESULT_M;
        end
        else if (w_can_forward && (rs1_idx_E == rd_idx_W)) begin
            hazard_forward_ctrl.forward_AE = AE_RESULT_W;
        end 

        // RAW from WB result
        if (m_can_forward && (rs2_idx_E == rd_idx_M)) begin
            hazard_forward_ctrl.forward_BE = BE_RDATA_ALU_RESULT_M;
        end
        else if (w_can_forward && (rs2_idx_E == rd_idx_W)) begin
            hazard_forward_ctrl.forward_BE = BE_RDATA_RESULT_W;
        end

        // Case 2 & 3: Load use & Branch
        lwstall =   valid_D && // Prove the dependent instruction is real consumer in Decode stage
                    valid_E && // Prove the load in Execute stage is the real producer
                    ctrl_E.rf_write &&
                    (rd_idx_E != '0) && // Make sure no architectual effect is existing (x0)
                    (ctrl_E.result_src == RSLT_RDATA) &&
                    ((rs1_idx_D == rd_idx_E) || (rs2_idx_D == rd_idx_E));

        redirect = (pc_src_E == PC_TARGET);

        if (trap_flush_D) begin
            hazard_stallflush_ctrl.flush_D = 1'b1;
        end
        else if (trap_flush_E) begin
            hazard_stallflush_ctrl.flush_E = 1'b1;
        end
        // Taken branch or jump in EX
        else if (redirect) begin
            // Jump & Branch have the higher priority than lwstall!!
            hazard_stallflush_ctrl.flush_D = 1'b1;
            hazard_stallflush_ctrl.flush_E = 1'b1; 
        end
        // Load-use: E load feeds D
        else if (lwstall) begin
            hazard_stallflush_ctrl.stall_F = 1'b1;
            hazard_stallflush_ctrl.stall_D = 1'b1; // No flush_D indeed
            hazard_stallflush_ctrl.flush_E = 1'b1;
        end
    end
    
endmodule
