`timescale 1ns/1ps

module core_smoke_csr_trap_tb
    import core_types_pkg::*;
();

    logic clk;
    logic reset;

    top #(
        .IMEM_INIT_FILE("programs/hex/smoke_csr_trap.hex")
    ) dut (
        .clk(clk),
        .reset(reset)
    );

    localparam int CLK_PERIOD_NS = 10;
    localparam int TIMEOUT_CYCLES = 400;
    localparam logic [WORD_WIDTH - 1:0] PASS_VALUE = 32'd1;

    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD_NS / 2) clk = ~clk;
    end

    initial begin
        $dumpfile("sim/build/smoke_csr_trap/smoke_csr_trap.vcd");
        $dumpvars(0, core_smoke_csr_trap_tb);
    end

    initial begin
        reset = 1'b1;
        repeat (3) @(negedge clk);
        reset = 1'b0;
    end

    initial begin : test_sequence
        logic [WORD_WIDTH - 1:0] completion_code;

        wait (!reset);
        wait (dut.core_processor.reg_file1.regs[31] != '0);
        #1;

        completion_code = dut.core_processor.reg_file1.regs[31];
        if (completion_code !== PASS_VALUE) begin
            $fatal(1, "SMOKE TRAP FAIL: completion code %0d", completion_code);
        end

        check_word("t0 scratch base", dut.core_processor.reg_file1.regs[5], 32'h0000_0100);
        check_word("t1 preserved", dut.core_processor.reg_file1.regs[6], 32'h0000_0011);
        check_word("t2 preserved", dut.core_processor.reg_file1.regs[7], 32'h0000_0022);
        check_word("t3 preserved", dut.core_processor.reg_file1.regs[28], 32'h0000_0033);
        check_word("three mixed trap returns", dut.core_processor.reg_file1.regs[9], 32'd3);

        check_word("CSRRW old value", dut.core_processor.reg_file1.regs[18], 32'h0000_0000);
        check_word("CSRRS old value", dut.core_processor.reg_file1.regs[19], 32'h0000_000f);
        check_word("CSRRC old value", dut.core_processor.reg_file1.regs[20], 32'h0000_003f);
        check_word("CSRRWI old value", dut.core_processor.reg_file1.regs[21], 32'h0000_0033);
        check_word("CSRRSI old value", dut.core_processor.reg_file1.regs[22], 32'h0000_0005);
        check_word("CSRRCI old value", dut.core_processor.reg_file1.regs[23], 32'h0000_0015);
        check_word("CSRRS pure read", dut.core_processor.reg_file1.regs[24], 32'h0000_0014);
        check_word("CSRRSI pure read", dut.core_processor.reg_file1.regs[25], 32'h0000_0014);

        check_word("saved t1", dut.core_processor.data_mem1.mem[64], 32'h0000_0011);
        check_word("saved t2", dut.core_processor.data_mem1.mem[65], 32'h0000_0022);
        check_word("saved t3", dut.core_processor.data_mem1.mem[66], 32'h0000_0033);

        check_word("mcause", dut.core_processor.csr_file1.mcause_reg, 32'd11);
        check_word("mtval", dut.core_processor.csr_file1.mtval_reg, 32'd0);
        check_word("mstatus", dut.core_processor.csr_file1.mstatus_reg, 32'h0000_1880);
        check_word("mepc return PC",
                   dut.core_processor.csr_file1.mepc_reg,
                   dut.core_processor.reg_file1.regs[17]);

        $display("SMOKE PASS: repeated trap and CSR program completed");
        $finish;
    end

    initial begin : timeout_guard
        repeat (TIMEOUT_CYCLES) @(posedge clk);
        $fatal(1, "SMOKE TRAP TB TIMEOUT");
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
