`timescale 1ns/1ps

module core_smoke_unsupported_csr_trap_tb
    import core_types_pkg::*;
();

    logic clk;
    logic reset;

    top #(
        .IMEM_INIT_FILE("programs/hex/smoke_unsupported_csr_trap.hex")
    ) dut (
        .clk(clk),
        .reset(reset)
    );

    localparam int CLK_PERIOD_NS = 10;
    localparam int TIMEOUT_CYCLES = 200;
    // csrrw s3, 0x7c0, t4: CSR address / rs1=x29 / funct3 / rd=x19 / opcode.
    localparam logic [31:0] UNSUPPORTED_CSR_INSTR =
        {12'h7c0, 5'd29, 3'b001, 5'd19, 7'b1110011};

    int unsigned trap_count;
    logic saw_unsupported_csr;
    logic saw_trap_state;
    logic check_trap_state;
    logic [31:0] captured_mepc;
    logic [31:0] captured_mtvec;

`ifdef TRACE_VCD
    // The runner supplies an absolute path only when TRACE=1.
    initial begin : waveform_dump
        string trace_file;
        if ($value$plusargs("trace=%s", trace_file)) begin
            $dumpfile(trace_file);
            $dumpvars(0, core_smoke_unsupported_csr_trap_tb);
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

    always_ff @(posedge clk) begin : trap_monitor
        if (reset) begin
            trap_count <= 0;
            saw_unsupported_csr <= 1'b0;
            saw_trap_state <= 1'b0;
            check_trap_state <= 1'b0;
            captured_mepc <= '0;
            captured_mtvec <= '0;
        end
        else begin
            check_trap_state <= dut.core_processor.trap_entry_E;

            if (dut.core_processor.data_E_idex.valid &&
                dut.core_processor.data_E_idex.instr == UNSUPPORTED_CSR_INSTR) begin
                saw_unsupported_csr <= 1'b1;
                if (dut.core_processor.illegal_csr_access_E !== 1'b1 ||
                    dut.core_processor.trap_entry_E !== 1'b1) begin
                    $fatal(1, "UNSUPPORTED CSR FAIL: valid unsupported access did not trap");
                end
            end

            if (dut.core_processor.trap_entry_E) begin
                trap_count <= trap_count + 1;
                captured_mepc <= dut.core_processor.data_E_idex.pc;
                captured_mtvec <= dut.core_processor.mtvec_reg;

                check_word("faulting instruction", dut.core_processor.data_E_idex.instr,
                           UNSUPPORTED_CSR_INSTR);
                check_word("timer source enabled", dut.core_processor.mie_reg, 32'h80);
                check_word("global interrupt enabled", dut.core_processor.mstatus_reg, 32'h1808);
                check_word("no pending timer", dut.core_processor.mip_reg, 32'd0);
                check_word("selected cause", dut.core_processor.trap_mcause_E, 32'd2);
                check_word("selected PC", dut.core_processor.trap_mepc_E,
                           dut.core_processor.data_E_idex.pc);
                check_word("selected instruction bits", dut.core_processor.trap_mtval_E,
                           UNSUPPORTED_CSR_INSTR);
                if (dut.core_processor.pc_src_with_trap_E !== PC_TRAP_HANDLER ||
                    dut.core_processor.trap_flush_D !== 1'b1 ||
                    dut.core_processor.trap_flush_E !== 1'b1 ||
                    dut.core_processor.trap_flush_M !== 1'b1) begin
                    $fatal(1, "UNSUPPORTED CSR FAIL: missing redirect or D/E/M flush");
                end
            end

            // At the next edge, observe the state written by the trap edge.
            if (check_trap_state) begin
                saw_trap_state <= 1'b1;
                check_word("trap PC redirect", dut.core_processor.pc_F_out, captured_mtvec);
                check_word("latched cause", dut.core_processor.csr_file1.mcause_reg, 32'd2);
                check_word("latched PC", dut.core_processor.csr_file1.mepc_reg, captured_mepc);
                check_word("latched instruction bits", dut.core_processor.csr_file1.mtval_reg,
                           UNSUPPORTED_CSR_INSTR);
                check_word("trap saves MIE and clears MIE", dut.core_processor.mstatus_reg, 32'h1880);
            end
        end
    end

    initial begin : test_sequence
        wait (!reset);
        wait (dut.core_processor.reg_file1.regs[31] != '0);
        #1;

        check_word("fatal-handler signature", dut.core_processor.reg_file1.regs[31], 32'd2);
        check_word("older instruction committed", dut.core_processor.reg_file1.regs[8], 32'd1);
        check_word("younger instruction flushed", dut.core_processor.reg_file1.regs[9], 32'd0);
        check_word("faulting CSR did not write rd", dut.core_processor.reg_file1.regs[19], 32'h66);
        check_word("PC marker", captured_mepc, dut.core_processor.reg_file1.regs[18] + 32'd4);
        check_word("final cause", dut.core_processor.csr_file1.mcause_reg, 32'd2);
        check_word("final mepc", dut.core_processor.csr_file1.mepc_reg, captured_mepc);
        check_word("final mtval", dut.core_processor.csr_file1.mtval_reg, UNSUPPORTED_CSR_INSTR);
        check_word("timer enable preserved", dut.core_processor.mie_reg, 32'h80);
        check_word("scratch CSR preserved", dut.core_processor.csr_file1.mscratch_reg, 32'h100);

        if (trap_count != 1 || !saw_unsupported_csr || !saw_trap_state) begin
            $fatal(1, "UNSUPPORTED CSR FAIL: expected one observed unsupported-CSR trap and state update");
        end

        $display("SMOKE PASS: unsupported CSR access raises illegal-instruction exception");
        $finish;
    end

    initial begin : timeout_guard
        repeat (TIMEOUT_CYCLES) @(posedge clk);
        $fatal(1, "UNSUPPORTED CSR TRAP TB TIMEOUT");
    end

    task automatic check_word(
        input string name,
        input logic [WORD_WIDTH - 1:0] actual,
        input logic [WORD_WIDTH - 1:0] expected
    );
        if (actual !== expected) begin
            $fatal(1, "UNSUPPORTED CSR FAIL: %s expected 0x%08h, got 0x%08h",
                   name, expected, actual);
        end
    endtask

endmodule
