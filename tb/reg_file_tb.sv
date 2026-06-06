`timescale 1ps/1ps

module reg_file_tb
    import core_types_pkg::*;
;

    logic clk;
    logic reset;

    logic rf_write_W;
    
    logic [ADDR_WIDTH - 1:0] rs1_idx_rf;
    logic [ADDR_WIDTH - 1:0] rs2_idx_rf;
    logic [ADDR_WIDTH - 1:0] rd_idx_W;
    logic [WORD_WIDTH - 1:0] WB_mux_result;

    logic [WORD_WIDTH - 1:0] rs1_val_D;
    logic [WORD_WIDTH - 1:0] rs2_val_D;

    reg_file dut (
        .clk(clk),
        .reset(reset),
        .rf_write_W(rf_write_W),
        .rs1_idx_rf(rs1_idx_rf),
        .rs2_idx_rf(rs2_idx_rf),
        .rd_idx_W(rd_idx_W),
        .WB_mux_result(WB_mux_result),
        .rs1_val_D(rs1_val_D),
        .rs2_val_D(rs2_val_D)
    );

    localparam int CLK_PERIOD_NS = 10;
    localparam int TIMEOUT_CYCLES = 80;

    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD_NS / 2) clk = ~clk;
    end

    initial begin
        $dumpfile("sim/build/reg_file/reg_file_tb.vcd");
        $dumpvars(0, reg_file_tb);
    end
    
    initial begin
        reset = 1'b1;
        repeat (3) @(posedge clk);
        @(negedge clk);
        reset = 1'b0;
        #1;

        test_default_zero();
        test_synchronous_write();
        test_combinational_read();
        test_bypass();

        $display("REG FILE PASS: tb completed");
        $finish;
    end

    initial begin
        repeat (TIMEOUT_CYCLES) @(posedge clk);

        $error("REG_FILE TIMEOUT after %0d cycles", TIMEOUT_CYCLES);
        $finish;
    end

    task automatic apply_reg_file_defaults();
        rf_write_W = 1'b0;
        rs1_idx_rf = 5'b0;
        rs2_idx_rf = 5'b0;
        rd_idx_W = 5'b0;
        WB_mux_result = 32'b0;
    endtask 

    task automatic test_default_zero();
        apply_reg_file_defaults();

        @(posedge clk);
        rs1_idx_rf = 5'd2;
        rs2_idx_rf = 5'd10;
        #1

        check_value("default value rs1", 32'b0, rs1_val_D);
        check_value("default value rs2", 32'b0, rs2_val_D);
    endtask 

    task automatic test_synchronous_write();
        apply_reg_file_defaults();

        @(negedge clk);
        rf_write_W = 1'b1;
        rd_idx_W = 5'd5;
        WB_mux_result = 32'd10;
        #1;

        @(posedge clk);
        #1;

        @(negedge clk);
        rf_write_W = 1'b0;
        rs1_idx_rf = 5'd5;
        #1;

        check_value("rd value", 32'd10, rs1_val_D);
    endtask 

    task automatic test_combinational_read();
        apply_reg_file_defaults();

        rs1_idx_rf = 5'd5;
        rs2_idx_rf = 5'd5;
        #1

        check_value("Combinational read rs1 value", 32'd10, rs1_val_D);
        check_value("Combinational read rs2 value", 32'd10, rs2_val_D);
    endtask 

    task automatic test_bypass();
        apply_reg_file_defaults();

        @(negedge clk);
        rd_idx_W = 5'd7;
        rf_write_W = 1'b1;
        WB_mux_result = 32'd20;
        #1;

        @(posedge clk);
        #1;

        @(negedge clk);
        rs1_idx_rf  = 5'd7;
        rf_write_W  = 1'b1;
        rd_idx_W    = 5'd7;
        WB_mux_result = 32'd30;
        #1;

        check_value("Bypass value x7", 32'd30, rs1_val_D);
    endtask 

    task automatic check_value(
        input string name,
        input logic [WORD_WIDTH - 1:0] expected_value,
        input logic [WORD_WIDTH - 1:0] actual
    );
        if (actual !== expected_value) begin
            $error("VALUE FAIL: %s expected %0d, got %0d",
                    name, expected_value, actual);
            $finish;
        end
    endtask 

endmodule
