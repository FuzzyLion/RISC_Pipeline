`timescale 1ns/1ps // Time units / Time accuracy

module core_smoke_hazard_tb;

    logic clk;
    logic reset;

    top #(
        .IMEM_INIT_FILE("programs/smoke_hazard.hex")
    ) dut (
        .clk(clk),
        .reset(reset)
    );

    localparam int CLK_PERIOD_NS = 10;
    localparam int TIMEOUT_CYCLES = 80;

    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD_NS / 2) clk = ~clk;
        // Always flip per half period, 5ns
    end

    initial begin
        $dumpfile("sim/build/smoke/core_hazard_smoke.vcd"); 
        // Create the VCD (Value Change Dump) files to observe the waveforms
        $dumpvars(0, core_smoke_hazard_tb);
        // Variables oberservations control
    end

    initial begin
        // Let all regs to be reset from state x
        reset = 1'b1;
        repeat (3) @(posedge clk); // Wait for 3 posedge to make sure all regs have been reseted
        reset = 1'b0;
    end

    initial begin
        repeat (TIMEOUT_CYCLES) @(posedge clk);

        check_word("x1", dut.core_processor.reg_file1.regs[1], 32'd36);
        check_word("x2", dut.core_processor.reg_file1.regs[2], 32'd7);
        check_word("x3", dut.core_processor.reg_file1.regs[3], 32'd23);
        // RF.sv had make some alteration to support the bypass procedure
        check_word("x4", dut.core_processor.reg_file1.regs[4], 32'd22);
        check_word("x5", dut.core_processor.reg_file1.regs[5], 32'd19);
        check_word("x6", dut.core_processor.reg_file1.regs[6], 32'd18);
        check_word("x7", dut.core_processor.reg_file1.regs[7], 32'd18);
        check_word("x8", dut.core_processor.reg_file1.regs[8], 32'hffff_fffb); // x8 = -5
        check_word("data_mem[9]", dut.core_processor.data_mem1.mem[9], 32'd18);

        $display("SMOKE PASS: hazard program completed");
        $finish; // End all tests, like clock generator or etc.
    end

    task automatic check_word(
        input string name,
        input logic [31:0] actual,
        input logic [31:0] expected
    );
        if (actual !== expected) begin
            $error("SMOKE FAIL: %s expected 0x%08h, got 0x%08h", name, expected, actual);
            $finish; // As long as the error occured, TB needs to finish
        end
    endtask

endmodule
