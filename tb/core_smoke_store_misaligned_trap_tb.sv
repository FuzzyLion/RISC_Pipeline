`timescale 1ns/1ps

module core_smoke_store_misaligned_trap_tb
    import core_types_pkg::*;
();

    logic clk;
    logic reset;

    top #(
        .IMEM_INIT_FILE("programs/smoke_store_misaligned_trap.hex")
    ) dut (
        .clk(clk),
        .reset(reset)
    );

    localparam int CLK_PERIOD_NS = 10;
    localparam int TIMEOUT_CYCLES = 180;
    localparam logic [WORD_WIDTH - 1:0] FATAL_TRAP_REACHED = 32'd2;

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
        logic [WORD_WIDTH - 1:0] faulting_pc;

        wait (!reset);
        wait (dut.core_processor.reg_file1.regs[31] != '0);
        #1;

        check_word("fixed fatal completion signature",
                   dut.core_processor.reg_file1.regs[31],
                   FATAL_TRAP_REACHED);
        check_word("older instruction committed",
                   dut.core_processor.reg_file1.regs[8],
                   32'd1);
        check_word("younger instruction flushed",
                   dut.core_processor.reg_file1.regs[9],
                   32'd0);
        check_word("faulting store left memory unchanged",
                   dut.core_processor.data_mem1.mem[0],
                   32'h0000_0033);

        faulting_pc = dut.core_processor.reg_file1.regs[18] + 32'd4;
        check_word("mcause comes from csr_file",
                   dut.core_processor.csr_file1.mcause_reg,
                   32'd6);
        check_word("mepc comes from csr_file",
                   dut.core_processor.csr_file1.mepc_reg,
                   faulting_pc);
        check_word("mtval contains the misaligned store address",
                   dut.core_processor.csr_file1.mtval_reg,
                   32'd2);

        $display("SMOKE PASS: store-address-misaligned trap is precise");
        $finish;
    end

    initial begin : timeout_guard
        repeat (TIMEOUT_CYCLES) @(posedge clk);
        $fatal(1, "SMOKE STORE MISALIGNED TRAP TB TIMEOUT");
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
