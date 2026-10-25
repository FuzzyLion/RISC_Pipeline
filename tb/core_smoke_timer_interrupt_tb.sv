`timescale 1ns/1ps

module core_smoke_timer_interrupt_tb
    import core_types_pkg::*;
();

    logic clk;
    logic reset;

    top #(
        .IMEM_INIT_FILE("programs/hex/smoke_timer_interrupt.hex")
    ) dut (
        .clk(clk),
        .reset(reset)
    );

    localparam int CLK_PERIOD_NS = 10;
    localparam int TIMEOUT_CYCLES = 800;
    localparam logic [WORD_WIDTH - 1:0] PASS_VALUE = 32'd1;
    localparam logic [WORD_WIDTH - 1:0] TIMER_MCAUSE = 32'h8000_0007;
    localparam logic [63:0] FIRST_DEADLINE = 64'd80;
    localparam logic [63:0] ACK_DEADLINE = 64'h0000_0001_0000_0000;

    int unsigned timer_trap_count;
    logic saw_pending_while_disabled;
    logic saw_timer_irq_clear;
    logic saw_mret;
    logic saw_mepc_reexecute;
    logic [WORD_WIDTH - 1:0] captured_mepc;

    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD_NS / 2) clk = ~clk;
    end

    initial begin
        $dumpfile("sim/build/smoke_timer_interrupt/smoke_timer_interrupt.vcd");
        $dumpvars(0, core_smoke_timer_interrupt_tb);
    end

    initial begin
        reset = 1'b1;
        repeat (3) @(negedge clk);
        reset = 1'b0;
    end

    always_ff @(posedge clk) begin : timer_monitor
        if (reset) begin
            timer_trap_count <= 0;
            saw_pending_while_disabled <= 1'b0;
            saw_timer_irq_clear <= 1'b0;
            saw_mret <= 1'b0;
            saw_mepc_reexecute <= 1'b0;
            captured_mepc <= '0;
        end
        else begin
            if (dut.core_processor.timer_irq &&
                (!dut.core_processor.mie_reg[7] ||
                 !dut.core_processor.mstatus_reg[3])) begin
                if (dut.core_processor.machine_timer1.mtimecmp !== FIRST_DEADLINE) begin
                    $fatal(1, "TIMER SMOKE FAIL: pending IRQ used mtimecmp 0x%016h, expected 0x%016h",
                           dut.core_processor.machine_timer1.mtimecmp, FIRST_DEADLINE);
                end
                saw_pending_while_disabled <= 1'b1;
            end

            if (saw_pending_while_disabled &&
                !dut.core_processor.timer_irq) begin
                saw_timer_irq_clear <= 1'b1;
            end

            if (dut.core_processor.trap_entry_E) begin
                timer_trap_count <= timer_trap_count + 1;
                captured_mepc <= dut.core_processor.trap_mepc_E;

                if (dut.core_processor.trap_mcause_E !== TIMER_MCAUSE) begin
                    $fatal(1, "TIMER SMOKE FAIL: trap mcause expected 0x%08h, got 0x%08h",
                           TIMER_MCAUSE, dut.core_processor.trap_mcause_E);
                end

                if (!dut.core_processor.trap_flush_D ||
                    !dut.core_processor.trap_flush_E ||
                    !dut.core_processor.trap_flush_M) begin
                    $fatal(1, "TIMER SMOKE FAIL: timer trap did not flush D/E/M");
                end
            end

            if (dut.core_processor.data_E_idex.valid &&
                dut.core_processor.ctrl_E.mret_en) begin
                saw_mret <= 1'b1;
            end

            if (saw_mret &&
                dut.core_processor.data_E_idex.valid &&
                (dut.core_processor.data_E_idex.pc == captured_mepc)) begin
                saw_mepc_reexecute <= 1'b1;
            end
        end
    end

    initial begin : test_sequence
        wait (!reset);
        wait (dut.core_processor.reg_file1.regs[31] != '0);
        #1;

        check_word("completion signature",
                   dut.core_processor.reg_file1.regs[31],
                   PASS_VALUE);

        check_word("timer mcause",
                   dut.core_processor.csr_file1.mcause_reg,
                   TIMER_MCAUSE);
        check_word("timer mtval",
                   dut.core_processor.csr_file1.mtval_reg,
                   32'd0);
        check_word("timer mepc",
                   dut.core_processor.csr_file1.mepc_reg,
                   captured_mepc);
        check_word("mstatus after mret",
                   dut.core_processor.csr_file1.mstatus_reg,
                   32'h0000_1888);
        check_word("mie after one-shot acknowledge",
                   dut.core_processor.csr_file1.mie_reg,
                   32'd0);
        check_word("mip after one-shot acknowledge",
                   dut.core_processor.csr_file1.mip_reg,
                   32'd0);

        check_word("t0 scratch base preserved",
                   dut.core_processor.reg_file1.regs[5],
                   32'h0000_0100);
        check_word("t1 preserved",
                   dut.core_processor.reg_file1.regs[6],
                   32'h0000_0011);
        check_word("t2 preserved",
                   dut.core_processor.reg_file1.regs[7],
                   32'h0000_0022);
        check_word("t3 preserved",
                   dut.core_processor.reg_file1.regs[28],
                   32'h0000_0033);
        check_word("post-mret marker",
                   dut.core_processor.reg_file1.regs[9],
                   32'd1);

        check_word("saved t1",
                   dut.core_processor.data_mem1.mem[64],
                   32'h0000_0011);
        check_word("saved t2",
                   dut.core_processor.data_mem1.mem[65],
                   32'h0000_0022);
        check_word("saved t3",
                   dut.core_processor.data_mem1.mem[66],
                   32'h0000_0033);
        check_word("timer MMIO did not alias data memory",
                   dut.core_processor.data_mem1.mem[0],
                   32'd0);

        if (dut.core_processor.machine_timer1.mtimecmp !== ACK_DEADLINE) begin
            $fatal(1, "TIMER SMOKE FAIL: acknowledged mtimecmp expected 0x%016h, got 0x%016h",
                   ACK_DEADLINE, dut.core_processor.machine_timer1.mtimecmp);
        end

        if (dut.core_processor.reg_file1.regs[8] == '0) begin
            $fatal(1, "TIMER SMOKE FAIL: foreground loop made no progress");
        end

        if (timer_trap_count != 1) begin
            $fatal(1, "TIMER SMOKE FAIL: expected one timer trap, got %0d",
                   timer_trap_count);
        end

        if (!saw_pending_while_disabled) begin
            $fatal(1, "TIMER SMOKE FAIL: did not observe MTIP gated while interrupts were disabled");
        end

        if (!saw_timer_irq_clear) begin
            $fatal(1, "TIMER SMOKE FAIL: pending timer request did not clear");
        end

        if (!saw_mret) begin
            $fatal(1, "TIMER SMOKE FAIL: handler never executed mret");
        end

        if (!saw_mepc_reexecute) begin
            $fatal(1, "TIMER SMOKE FAIL: interrupted mepc was not re-executed");
        end

        $display("SMOKE PASS: one-shot machine-timer interrupt completed");
        $finish;
    end

    initial begin : timeout_guard
        repeat (TIMEOUT_CYCLES) @(posedge clk);
        $fatal(1, "TIMER SMOKE TB TIMEOUT");
    end

    task automatic check_word(
        input string name,
        input logic [WORD_WIDTH - 1:0] actual,
        input logic [WORD_WIDTH - 1:0] expected
    );
        if (actual !== expected) begin
            $fatal(1, "TIMER SMOKE FAIL: %s expected 0x%08h, got 0x%08h",
                   name, expected, actual);
        end
    endtask

endmodule
