`timescale 1ns/1ps

module hazard_unit_tb
    import core_types_pkg::*;
;

    logic valid_D;
    logic valid_E;
    logic valid_M;
    logic valid_W;

    logic [ADDR_WIDTH - 1:0] rs1_idx_D;
    logic [ADDR_WIDTH - 1:0] rs2_idx_D;
    logic [ADDR_WIDTH - 1:0] rs1_idx_E;
    logic [ADDR_WIDTH - 1:0] rs2_idx_E;
    logic [ADDR_WIDTH - 1:0] rd_idx_E;
    logic [ADDR_WIDTH - 1:0] rd_idx_M;
    logic [ADDR_WIDTH - 1:0] rd_idx_W;

    control_bundle_t ctrl_E;
    ex_mem_control_t ctrl_M;
    mem_wb_control_t ctrl_W;
    pc_src_e pc_src_E;

    hazard_forward_t hazard_forward_ctrl;
    hazard_stallflush_t hazard_stallflush_ctrl;

    hazard_unit dut (
        .valid_D(valid_D),
        .valid_E(valid_E),
        .valid_M(valid_M),
        .valid_W(valid_W),
        .rs1_idx_D(rs1_idx_D),
        .rs2_idx_D(rs2_idx_D),
        .rs1_idx_E(rs1_idx_E),
        .rs2_idx_E(rs2_idx_E),
        .rd_idx_E(rd_idx_E),
        .rd_idx_M(rd_idx_M),
        .rd_idx_W(rd_idx_W),
        .ctrl_E(ctrl_E),
        .ctrl_M(ctrl_M),
        .ctrl_W(ctrl_W),
        .pc_src_E(pc_src_E),
        .hazard_forward_ctrl(hazard_forward_ctrl),
        .hazard_stallflush_ctrl(hazard_stallflush_ctrl)
    );

    // -------------------------- FUNCTION TESTS -------------------------
    initial begin : test_sequence
        test_no_hazard();
        test_mem_forward_rs1();
        test_wb_forward_rs1();
        test_mem_forward_rs2();
        test_wb_forward_rs2();
        test_load_use_rs1();
        test_load_use_rs2();
        test_redirect();

        test_mem_prior_wb_rs1();
        test_mem_prior_wb_rs2();
        test_redirect_prior_lwstall();

        test_mem_x0_forward();
        test_load_use_x0();
        test_invalidD_load_use();
        test_invalidE_load_use();
        test_non_load_result_no_lwstall();
        test_mem_load_result_no_forward();
        test_invalidE_no_forward();
        test_invalidM_no_mem_forward();
        test_invalidW_no_wb_forward();

        $display("HAZARD_UNIT PASS: all tests completed");
        $finish;
    end

    // -------------------------- PORTS INITIAL --------------------------
    task automatic apply_no_hazard_defaults();
        valid_D = 1'b1;
        valid_E = 1'b1;
        valid_M = 1'b1;
        valid_W = 1'b1;

        rs1_idx_D = 5'd1;
        rs2_idx_D = 5'd2;
        rs1_idx_E = 5'd3;
        rs2_idx_E = 5'd4;
        rd_idx_E  = 5'd5;
        rd_idx_M  = 5'd6;
        rd_idx_W  = 5'd7;

        ctrl_E = '{
            rf_write: 1'b0,
            result_src: RSLT_ALU,
            mem_write: 1'b0,
            jump: 1'b0,
            pc_target_src: PC_TARGET_PC_IMM,
            branch: 1'b0,
            alu_ctrl: CTRL_ADD,
            alu_src: BE_RDATA_E,
            btype: BEQ,
            load_type: LB,
            store_type: SB
        };

        ctrl_M = '{
            rf_write: 1'b0,
            result_src: RSLT_ALU,
            mem_write: 1'b0,
            load_type: LB,
            store_type: SB
        };

        ctrl_W = '{
            rf_write: 1'b0,
            result_src: RSLT_ALU
        };

        pc_src_E = PC_PLUS4;
    endtask

    // ------------------------ FUNCTION CHECKS -------------------------
    task automatic test_no_hazard();
        apply_no_hazard_defaults();
        #1;

        check_forward("no hazard forward", AE_RS1_VAL, BE_RDATA_RS2_VAL);
        check_stallflush("no hazard stall/flush", 1'b0, 1'b0, 1'b0, 1'b0);
    endtask

    task automatic test_mem_forward_rs1();
        apply_no_hazard_defaults();

        ctrl_M.rf_write = 1'b1;
        rd_idx_M = 5'd3;
        rs1_idx_E = 5'd3;
        #1;

        check_forward("mem forward rs1", AE_ALU_RESULT_M, BE_RDATA_RS2_VAL);
        check_stallflush("no hazard stall/flush", 1'b0, 1'b0, 1'b0, 1'b0);
    endtask

    task automatic test_wb_forward_rs1();
        apply_no_hazard_defaults();

        ctrl_W.rf_write = 1'b1;
        rd_idx_W = 5'd1;
        rs1_idx_E = 5'd1;
        #1;

        check_forward("wb forward rs1", AE_RESULT_W, BE_RDATA_RS2_VAL);
        check_stallflush("no hazard stall/flush", 1'b0, 1'b0, 1'b0, 1'b0);
    endtask

    task automatic test_mem_forward_rs2();
        apply_no_hazard_defaults();

        ctrl_M.rf_write = 1'b1;
        rd_idx_M = 5'd4;
        rs2_idx_E = 5'd4;
        #1;

        check_forward("mem forward rs2", AE_RS1_VAL, BE_RDATA_ALU_RESULT_M);
        check_stallflush("no hazard stall/flush", 1'b0, 1'b0, 1'b0, 1'b0);
    endtask

    task automatic test_wb_forward_rs2();
        apply_no_hazard_defaults();

        ctrl_W.rf_write = 1'b1;
        rd_idx_W = 5'd2;
        rs2_idx_E = 5'd2;
        #1;

        check_forward("wb forward rs2", AE_RS1_VAL, BE_RDATA_RESULT_W);
        check_stallflush("no hazard stall/flush", 1'b0, 1'b0, 1'b0, 1'b0);
    endtask

    task automatic test_load_use_rs1();
        apply_no_hazard_defaults();

        valid_D = 1'b1;
        valid_E = 1'b1;

        ctrl_E.rf_write = 1'b1;
        rd_idx_E = 5'd1;
        ctrl_E.result_src = RSLT_RDATA;
        rs1_idx_D = 5'd1;
        #1;

        check_forward("no hazard forward", AE_RS1_VAL, BE_RDATA_RS2_VAL);
        check_stallflush("hazard lwstall", 1'b1, 1'b1, 1'b0, 1'b1);
    endtask 

    task automatic test_load_use_rs2();
        apply_no_hazard_defaults();

        valid_D = 1'b1;
        valid_E = 1'b1;

        ctrl_E.rf_write = 1'b1;
        rd_idx_E = 5'd1;
        ctrl_E.result_src = RSLT_RDATA;
        rs1_idx_D = 5'd8; // Overwrite the default value for rs1_idx_D
        rs2_idx_D = 5'd1;
        #1;

        check_forward("no hazard forward", AE_RS1_VAL, BE_RDATA_RS2_VAL);
        check_stallflush("hazard lwstall", 1'b1, 1'b1, 1'b0, 1'b1);
    endtask

    task automatic test_redirect();
        apply_no_hazard_defaults();

        pc_src_E = PC_TARGET;
        #1;

        check_forward("no hazard forward", AE_RS1_VAL, BE_RDATA_RS2_VAL);
        check_stallflush("hazard redirect", 1'b0, 1'b0, 1'b1, 1'b1);
    endtask  

    // --------------------------- CORNER CASES ---------------------------
    task automatic test_mem_prior_wb_rs1();
        apply_no_hazard_defaults();

        ctrl_M.rf_write = 1'b1;
        ctrl_W.rf_write = 1'b1;
        rd_idx_M = 5'd3;
        rd_idx_W = 5'd3;
        rs1_idx_E = 5'd3;
        #1;

        check_forward("MEM prior WB for rs1", AE_ALU_RESULT_M, BE_RDATA_RS2_VAL);
        check_stallflush("no hazard stall/flush", 1'b0, 1'b0, 1'b0, 1'b0);
    endtask 

    task automatic test_mem_prior_wb_rs2();
        apply_no_hazard_defaults();

        ctrl_M.rf_write = 1'b1;
        ctrl_W.rf_write = 1'b1;
        rd_idx_M = 5'd3;
        rd_idx_W = 5'd3;
        rs1_idx_E = 5'd1; // Overwrite the default value for rs1_idx_E
        rs2_idx_E = 5'd3;
        #1;

        check_forward("MEM prior WB for rs2", AE_RS1_VAL, BE_RDATA_ALU_RESULT_M);
        check_stallflush("no hazard stall/flush", 1'b0, 1'b0, 1'b0, 1'b0);
    endtask 

    task automatic test_redirect_prior_lwstall();
        apply_no_hazard_defaults();

        valid_D = 1'b1;
        valid_E = 1'b1;

        ctrl_E.rf_write = 1'b1;
        rd_idx_E = 5'd1;
        ctrl_E.result_src = RSLT_RDATA;
        rs2_idx_D = 5'd1;

        pc_src_E = PC_TARGET;
        #1;

        check_forward("no hazard forward", AE_RS1_VAL, BE_RDATA_RS2_VAL);
        check_stallflush("redirect prior lwstall", 1'b0, 1'b0, 1'b1, 1'b1);
    endtask 

    task automatic test_mem_x0_forward();
        apply_no_hazard_defaults();

        ctrl_M.rf_write = 1'b1;
        ctrl_W.rf_write = 1'b1;
        rd_idx_M = 5'd0;
        rd_idx_W = 5'd0;
        rs1_idx_E = 5'd0;
        #1;

        check_forward("x0 no forward", AE_RS1_VAL, BE_RDATA_RS2_VAL);
        check_stallflush("no hazard stall/flush", 1'b0, 1'b0, 1'b0, 1'b0);
    endtask 

    task automatic test_load_use_x0();
        apply_no_hazard_defaults();

        valid_D = 1'b1;
        valid_E = 1'b1;

        ctrl_E.rf_write = 1'b1;
        rd_idx_E = 5'd0;
        ctrl_E.result_src = RSLT_RDATA;
        rs2_idx_D = 5'd0;
        #1;

        check_forward("no hazard forward", AE_RS1_VAL, BE_RDATA_RS2_VAL);
        check_stallflush("x0 no lwstall", 1'b0, 1'b0, 1'b0, 1'b0);
    endtask 

    task automatic test_invalidD_load_use();
        apply_no_hazard_defaults();

        valid_D = 1'b0;
        valid_E = 1'b1;

        ctrl_E.rf_write = 1'b1;
        rd_idx_E = 5'd9;
        ctrl_E.result_src = RSLT_RDATA;
        rs2_idx_D = 5'd9;
        #1;

        check_forward("no hazard forward", AE_RS1_VAL, BE_RDATA_RS2_VAL);
        check_stallflush("invalid D no lwstall", 1'b0, 1'b0, 1'b0, 1'b0);
    endtask 

    task automatic test_invalidE_load_use();
        apply_no_hazard_defaults();

        valid_D = 1'b1;
        valid_E = 1'b0;

        ctrl_E.rf_write = 1'b1;
        rd_idx_E = 5'd9;
        ctrl_E.result_src = RSLT_RDATA;
        rs2_idx_D = 5'd9;
        #1;

        check_forward("no hazard forward", AE_RS1_VAL, BE_RDATA_RS2_VAL);
        check_stallflush("invalid E no lwstall", 1'b0, 1'b0, 1'b0, 1'b0);
    endtask 

    task automatic test_non_load_result_no_lwstall();
        apply_no_hazard_defaults();
        
        valid_D = 1'b1;
        valid_E = 1'b1;

        ctrl_E.rf_write = 1'b1;
        rd_idx_E = 5'd1;
        ctrl_E.result_src = RSLT_ALU;
        rs2_idx_D = 5'd1;
        #1;

        check_forward("no hazard forward", AE_RS1_VAL, BE_RDATA_RS2_VAL);
        check_stallflush("non-load no lwstall", 1'b0, 1'b0, 1'b0, 1'b0);
    endtask 

    task automatic test_mem_load_result_no_forward();
        apply_no_hazard_defaults();

        ctrl_M.rf_write = 1'b1;
        ctrl_W.rf_write = 1'b1;
        ctrl_M.result_src = RSLT_RDATA;
        rd_idx_M = 5'd11;
        rs1_idx_E = 5'd11;
        #1;

        check_forward("MEM load result no forward", AE_RS1_VAL, BE_RDATA_RS2_VAL);
        check_stallflush("no hazard stall/flush", 1'b0, 1'b0, 1'b0, 1'b0);
    endtask //automatic

    task automatic test_invalidE_no_forward();
        apply_no_hazard_defaults();

        valid_E = 1'b0;
        ctrl_M.rf_write = 1'b1;
        ctrl_W.rf_write = 1'b1;
        rd_idx_M = 5'd3;
        rd_idx_W = 5'd4;
        rs1_idx_E = 5'd3;
        rs2_idx_E = 5'd4;
        #1;

        check_forward("invalid E no forward", AE_RS1_VAL, BE_RDATA_RS2_VAL);
        check_stallflush("no hazard stall/flush", 1'b0, 1'b0, 1'b0, 1'b0);
    endtask

    task automatic test_invalidM_no_mem_forward();
        apply_no_hazard_defaults();

        valid_M = 1'b0;
        ctrl_M.rf_write = 1'b1;
        rd_idx_M = 5'd3;
        rs1_idx_E = 5'd3;
        #1;

        check_forward("invalid M no forward", AE_RS1_VAL, BE_RDATA_RS2_VAL);
        check_stallflush("no hazard stall/flush", 1'b0, 1'b0, 1'b0, 1'b0);
    endtask

    task automatic test_invalidW_no_wb_forward();
        apply_no_hazard_defaults();

        valid_W = 1'b0;
        ctrl_W.rf_write = 1'b1;
        rd_idx_W = 5'd4;
        rs2_idx_E = 5'd4;
        #1;

        check_forward("invalid W no forward", AE_RS1_VAL, BE_RDATA_RS2_VAL);
        check_stallflush("no hazard stall/flush", 1'b0, 1'b0, 1'b0, 1'b0);
    endtask

    // --------------------------- CHECK TASKS ---------------------------
    task automatic check_forward(
        input string name,
        input forward_ae expected_forward_AE,
        input forward_rdata_be expected_forward_BE
    );
        if (hazard_forward_ctrl.forward_AE !== expected_forward_AE) begin
            $fatal(1, "%s: forward_AE expected %0d, got %0d",
                   name, expected_forward_AE, hazard_forward_ctrl.forward_AE);
        end

        if (hazard_forward_ctrl.forward_BE !== expected_forward_BE) begin
            $fatal(1, "%s: forward_BE expected %0d, got %0d",
                   name, expected_forward_BE, hazard_forward_ctrl.forward_BE);
        end
    endtask

    task automatic check_stallflush(
        input string name,
        input logic expected_stall_F,
        input logic expected_stall_D,
        input logic expected_flush_D,
        input logic expected_flush_E
    );
        if (hazard_stallflush_ctrl.stall_F !== expected_stall_F) begin
            $fatal(1, "%s: stall_F expected %0b, got %0b",
                   name, expected_stall_F, hazard_stallflush_ctrl.stall_F);
        end

        if (hazard_stallflush_ctrl.stall_D !== expected_stall_D) begin
            $fatal(1, "%s: stall_D expected %0b, got %0b",
                   name, expected_stall_D, hazard_stallflush_ctrl.stall_D);
        end

        if (hazard_stallflush_ctrl.flush_D !== expected_flush_D) begin
            $fatal(1, "%s: flush_D expected %0b, got %0b",
                   name, expected_flush_D, hazard_stallflush_ctrl.flush_D);
        end

        if (hazard_stallflush_ctrl.flush_E !== expected_flush_E) begin
            $fatal(1, "%s: flush_E expected %0b, got %0b",
                   name, expected_flush_E, hazard_stallflush_ctrl.flush_E);
        end
    endtask

endmodule
