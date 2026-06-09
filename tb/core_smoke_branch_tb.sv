`timescale 1ns/1ps // Time units / Time accuracy

module core_smoke_branch_tb
    import core_types_pkg::*;
;

    logic clk;
    logic reset;

    top #(
        .IMEM_INIT_FILE("programs/smoke_branch.hex")
    ) dut (
        .clk(clk),
        .reset(reset)
    );

    localparam int CLK_PERIOD_NS = 10;
    localparam int TIMEOUT_CYCLES = 80;
    localparam logic [WORD_WIDTH - 1:0] PASS_VALUE = 32'd1;

    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD_NS / 2) clk = ~clk;
        // Toggle clock every half period
    end

    initial begin
        $dumpfile("sim/build/smoke_branch/core_branch_smoke.vcd"); 
        // Create the VCD (Value Change Dump) files to observe the waveforms
        $dumpvars(0, core_smoke_branch_tb);
        
        /* 
        Variables oberservations control,

        For example: 
        0 means record signals in all layers; 
        1 means only record the signals in core module;
        2 means only record the signals in core & it's lower level modules...
        etc.
        */
    end

    initial begin
        // Let all regs to be reset from state x
        reset = 1'b1;
        repeat (3) @(negedge clk); // Wait for 3 posedge to make sure all regs have been reseted
        reset = 1'b0;
    end

    initial begin : test_sequence
        wait (!reset);
        wait (dut.core_processor.reg_file1.regs[31] == PASS_VALUE);
        #1;

        check_word("x1", dut.core_processor.reg_file1.regs[1], 32'd0);
        check_word("x2", dut.core_processor.reg_file1.regs[2], 32'd7);
        check_word("x3", dut.core_processor.reg_file1.regs[3], 32'd7);
        check_word("x5", dut.core_processor.reg_file1.regs[5], 32'd0);
        check_word("x4", dut.core_processor.reg_file1.regs[4], 32'd7);

        $display("SMOKE PASS: branch program completed");
        $finish; // End all tests, like clock generator or etc.
    end

    initial begin : timeout_guard
        repeat (TIMEOUT_CYCLES) @(posedge clk);

        $fatal(1, "SMOKE BRANCH TB TIMEOUT");
    end

    task automatic check_word(
        input string name,
        input logic [WORD_WIDTH - 1:0] actual,
        input logic [WORD_WIDTH - 1:0] expected
    );
        if (actual !== expected) begin
            $fatal(1, "SMOKE FAIL: %s expected 0x%08h, got 0x%08h",
                   name, expected, actual);
        end
    endtask

endmodule
