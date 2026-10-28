`timescale 1ns/1ps

module core_smoke_alu_tb
    import core_types_pkg::*;
();

    logic clk;
    logic reset;

    top #(
        .IMEM_INIT_FILE("programs/hex/smoke_alu.hex")
    ) dut (
        .clk(clk),
        .reset(reset)
    );

    localparam int CLK_PERIOD_NS = 10;
    localparam int TIMEOUT_CYCLES = 160;
    localparam logic [WORD_WIDTH - 1:0] PASS_VALUE = 32'd1;

`ifdef TRACE_VCD
    // The runner supplies an absolute path only when TRACE=1.
    initial begin : waveform_dump
        string trace_file;
        if ($value$plusargs("trace=%s", trace_file)) begin
            $dumpfile(trace_file);
            $dumpvars(0, core_smoke_alu_tb);
        end
    end
`endif

    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD_NS / 2) clk = ~clk;
    end

    initial begin
        reset = 1'b1;
        repeat (3) @(negedge clk);
        reset = 1'b0;
    end

    initial begin : test_sequence
        wait (!reset);
        wait (dut.core_processor.reg_file1.regs[31] != '0);
        #1;

        check_word("completion code", dut.core_processor.reg_file1.regs[31], PASS_VALUE);
        check_word("slti", dut.core_processor.reg_file1.regs[3], 32'd1);
        check_word("sltiu", dut.core_processor.reg_file1.regs[4], 32'd0);
        check_word("xori", dut.core_processor.reg_file1.regs[5], 32'd5);
        check_word("ori", dut.core_processor.reg_file1.regs[6], 32'd11);
        check_word("andi", dut.core_processor.reg_file1.regs[7], 32'd8);
        check_word("slli", dut.core_processor.reg_file1.regs[8], 32'd48);
        check_word("srli", dut.core_processor.reg_file1.regs[9], 32'h0fff_ffff);
        check_word("srai", dut.core_processor.reg_file1.regs[10], 32'hffff_ffff);

        $display("SMOKE PASS: ALU-immediate and branch program completed");
        $finish;
    end

    initial begin : timeout_guard
        repeat (TIMEOUT_CYCLES) @(posedge clk);
        $fatal(1, "SMOKE ALU/BRANCH TB TIMEOUT");
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
