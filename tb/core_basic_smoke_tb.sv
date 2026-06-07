`timescale 1ns/1ps // Time units / Time accuracy

module core_smoke_tb
    import core_types_pkg::*;
;

    logic clk;
    logic reset;

    /*
    core_smoke_tb: (smoke_basic.hex)
        -> top dut
            -> core core_processor
                -> instr_mem instr_mem1
    */

    top #(
        .IMEM_INIT_FILE("programs/smoke_basic.hex")
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
        // Always flip per half period, 5ns
    end

    initial begin
        $dumpfile("sim/build/smoke/basic_smoke.vcd"); 
        // Create the VCD (Value Change Dump) files to observe the waveforms
        $dumpvars(0, core_smoke_tb);
        // Variables oberservations control
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

        // dut.core_processor.reg_file1.regs[x] -> means observe it's value directly in RF
        // TB only and it cannot be synthesized
        check_word("x1", dut.core_processor.reg_file1.regs[1], 32'd5);
        check_word("x2", dut.core_processor.reg_file1.regs[2], 32'd7);
        check_word("x3", dut.core_processor.reg_file1.regs[3], 32'd12);
        check_word("data_mem[0]", dut.core_processor.data_mem1.mem[0], 32'd12);
        check_word("x4", dut.core_processor.reg_file1.regs[4], 32'd12);

        // auipc:
        // check_word("x16", dut.core_processor.reg_file1.regs[16], 32'h0000006c);

        $display("SMOKE PASS: basic no-hazard program completed");
        $finish; // End all tests, like clock generator or etc.
    end

    initial begin : timeout_guard
        repeat (TIMEOUT_CYCLES) @(posedge clk);

        $fatal(1, "SMOKE BASIC TB TIMEOUT");
    end

    task automatic check_word(
        input string name,
        input logic [31:0] actual,
        input logic [31:0] expected
    );
        if (actual !== expected) begin
            $error("SMOKE FAIL: %s expected 0x%08h, got 0x%08h", name, expected, actual);
            // Minimum output width is 8 bits, if it doesn't fit, top it up with 0
            $finish; // As long as the error occured, TB needs to finish
        end
    endtask

endmodule
