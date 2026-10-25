`timescale 1ns/1ps // Time units / Time accuracy

module core_smoke_hazard_tb
    import core_types_pkg::*;
();

    logic clk;
    logic reset;

    top #(
        .IMEM_INIT_FILE("programs/hex/smoke_hazard.hex")
    ) dut (
        .clk(clk),
        .reset(reset)
    );

    localparam int CLK_PERIOD_NS = 10;
    localparam int TIMEOUT_CYCLES = 80;
    localparam logic [WORD_WIDTH - 1:0] PASS_VALUE = 32'd1;
    localparam logic [WORD_WIDTH - 1:0] LOAD_TARGET_JALR = 32'h00058667; // jalr x12, 0(x11)
    int unsigned load_jalr_stall_cycles;

    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD_NS / 2) clk = ~clk;
        // Always flip per half period, 5ns
    end

    initial begin
        $dumpfile("sim/build/smoke/hazard_smoke.vcd"); 
        // Create the VCD (Value Change Dump) files to observe the waveforms
        $dumpvars(0, core_smoke_hazard_tb);
        // Variables oberservations control
    end

    initial begin
        // Let all regs to be reset from state x
        reset = 1'b1;
        repeat (3) @(negedge clk); 
        // Wait for 3 negedge to make sure all regs have been reseted
        // Deassert reset on negedge to avoid setup time violations and race conditions
        reset = 1'b0;
    end

    always_ff @(posedge clk) begin : load_jalr_monitor
        if (reset) begin
            load_jalr_stall_cycles <= 0;
        end
        else if (dut.core_processor.data_D_ifid.valid &&
                 dut.core_processor.data_E_idex.valid &&
                 (dut.core_processor.data_D_ifid.instr == LOAD_TARGET_JALR) &&
                 (dut.core_processor.ctrl_E.result_src == RSLT_RDATA) &&
                 (dut.core_processor.data_E_idex.rd_idx == 5'd11)) begin
            if (!dut.core_processor.hazard_stallflush_ctrl.stall_F ||
                !dut.core_processor.hazard_stallflush_ctrl.stall_D ||
                !dut.core_processor.hazard_stallflush_ctrl.flush_E ||
                dut.core_processor.hazard_stallflush_ctrl.flush_D) begin
                $fatal(1, "SMOKE FAIL: load-to-JALR must hold F/D and insert an EX bubble");
            end
            load_jalr_stall_cycles <= load_jalr_stall_cycles + 1;
        end
    end

    initial begin : test_sequence
        wait (!reset);
        wait (dut.core_processor.reg_file1.regs[31] == PASS_VALUE);
        #1;

        check_word("x1", dut.core_processor.reg_file1.regs[1], 32'd36);
        check_word("x2", dut.core_processor.reg_file1.regs[2], 32'd7);
        check_word("x3", dut.core_processor.reg_file1.regs[3], 32'd23);
        // reg_file.sv had make some alteration to support the bypass procedure
        check_word("x4", dut.core_processor.reg_file1.regs[4], 32'd22);
        check_word("x5", dut.core_processor.reg_file1.regs[5], 32'd19);
        check_word("x6", dut.core_processor.reg_file1.regs[6], 32'd18);
        check_word("x7", dut.core_processor.reg_file1.regs[7], 32'd18);
        check_word("x8", dut.core_processor.reg_file1.regs[8], 32'hffff_fffb); // x8 = -5
        check_word("data_mem[9]", dut.core_processor.data_mem1.mem[9], 32'd18);
        check_word("loaded JALR target", dut.core_processor.reg_file1.regs[11],
                   dut.core_processor.reg_file1.regs[10]);
        check_word("JALR link PC+4", dut.core_processor.reg_file1.regs[12],
                   dut.core_processor.reg_file1.regs[10] - 32'd4);
        check_word("JALR wrong-path marker", dut.core_processor.reg_file1.regs[13], 32'd0);
        check_word("JALR target marker", dut.core_processor.reg_file1.regs[14], 32'd1);
        if (load_jalr_stall_cycles != 1) begin
            $fatal(1, "SMOKE FAIL: expected one load-to-JALR stall, got %0d",
                   load_jalr_stall_cycles);
        end

        $display("SMOKE PASS: hazard program completed");
        $finish; // End all tests, like clock generator or etc.
    end

    initial begin : timeout_guard
        repeat (TIMEOUT_CYCLES) @(posedge clk);

        $fatal(1, "SMOKE HAZARD TB TIMEOUT");
    end

    task automatic check_word(
        input string name,
        input logic [31:0] actual,
        input logic [31:0] expected
    );
        if (actual !== expected) begin
            $fatal(1, "SMOKE FAIL: %s expected 0x%08h, got 0x%08h",
                   name, expected, actual);
        end
    endtask

endmodule
