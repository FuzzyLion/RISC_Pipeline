`timescale 1ns/1ps // Time units / Time accuracy

module core_smoke_branch_tb
    import core_types_pkg::*;
();

    logic clk;
    logic reset;

    top #(
        .IMEM_INIT_FILE("programs/hex/smoke_branch.hex")
    ) dut (
        .clk(clk),
        .reset(reset)
    );

    localparam int CLK_PERIOD_NS = 10;
    localparam int TIMEOUT_CYCLES = 80;
    localparam logic [WORD_WIDTH - 1:0] PASS_VALUE = 32'd1;

`ifdef TRACE_VCD
    // The runner supplies an absolute path only when TRACE=1.
    initial begin : waveform_dump
        string trace_file;
        if ($value$plusargs("trace=%s", trace_file)) begin
            $dumpfile(trace_file);
            $dumpvars(0, core_smoke_branch_tb);
        end
    end
`endif

    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD_NS / 2) clk = ~clk;
        // Toggle clock every half period
    end

    initial begin
        // Let all regs to be reset from state x
        reset = 1'b1;
        repeat (3) @(negedge clk);
        // Deassert reset on negedge to avoid setup time violations and race conditions
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
