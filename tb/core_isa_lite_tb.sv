`timescale 1ns/1ps

module core_isa_lite_tb #(
    parameter string IMEM_INIT_FILE = "programs/hex/riscv_lite/rv32ui_addi.hex",
    parameter string ISA_TEST_NAME = "rv32ui_addi"
);

    import core_types_pkg::*;

    logic clk;
    logic reset;

    top #(
        .IMEM_INIT_FILE(IMEM_INIT_FILE)
    ) dut (
        .clk(clk),
        .reset(reset)
    );

    localparam int CLK_PERIOD_NS = 10;
    localparam int TIMEOUT_CYCLES = 2000;
    localparam logic [WORD_WIDTH - 1:0] PASS_VALUE = 32'd1;

`ifdef TRACE_VCD
    // The runner supplies an absolute path only when TRACE=1.
    initial begin : waveform_dump
        string trace_file;
        if ($value$plusargs("trace=%s", trace_file)) begin
            $dumpfile(trace_file);
            $dumpvars(0, core_isa_lite_tb);
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
        logic [WORD_WIDTH - 1:0] completion_code;

        wait (!reset);
        wait (dut.core_processor.id_stage1.reg_file1.regs[31] != '0);
        #1;

        completion_code = dut.core_processor.id_stage1.reg_file1.regs[31];
        if (completion_code !== PASS_VALUE) begin
            $fatal(1,
                   "ISA LITE FAIL: expected x31=1, got 0x%08h. If odd and >1, failing testnum is (x31 - 1) / 2.",
                   completion_code);
        end

        $display("ISA LITE PASS: %s completed", ISA_TEST_NAME);
        $finish;
    end

    initial begin : timeout_guard
        repeat (TIMEOUT_CYCLES) @(posedge clk);
        $fatal(1, "ISA LITE TB TIMEOUT: %s", ISA_TEST_NAME);
    end

endmodule
