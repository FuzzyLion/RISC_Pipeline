`timescale 1ns/1ps

module data_mem_tb
    import core_types_pkg::*;
();
    
    logic clk;

    logic mem_write_M;

    logic [WORD_WIDTH - 1:0] alu_result_M;
    logic [WORD_WIDTH - 1:0] store_wdata_M;
    logic [3:0] store_wstrb_M;

    logic [WORD_WIDTH - 1:0] mem_rdata_M;
    logic [MEM_ADDR_WIDTH - 1:0] word_idx;

    data_mem dut (
        .clk(clk),
        .data_mem_write(mem_write_M),
        .alu_result_M(alu_result_M),
        .store_wdata_M(store_wdata_M),
        .store_wstrb_M(store_wstrb_M),
        .mem_rdata_M(mem_rdata_M),
        .word_idx(word_idx)
    );

    localparam int CLK_PERIOD_NS = 10;
    localparam int TIMEOUT_CYCLES = 80;

`ifdef TRACE_VCD
    // The runner supplies an absolute path only when TRACE=1.
    initial begin : waveform_dump
        string trace_file;
        if ($value$plusargs("trace=%s", trace_file)) begin
            $dumpfile(trace_file);
            $dumpvars(0, data_mem_tb);
        end
    end
`endif

    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD_NS / 2) clk = ~clk;
    end

    initial begin : test_sequence
        test_mem_default();
        test_mem_synchronous_write();
        test_mem_combinational_read();
        test_mem_write_disabled();
        test_low_address_bits_ignored();
        test_byte_lane_write();
        test_word_idx();

        $display("DATA MEM PASS: tb completed");
        $finish;
    end

    initial begin : timeout_guard
        repeat (TIMEOUT_CYCLES) @(posedge clk);

        $fatal(1, "DATA MEM TB TIMEOUT");
    end

    task automatic apply_data_mem_default();
        mem_write_M = 1'b0;
        alu_result_M = 32'h0000_0000;
        store_wdata_M = 32'b0;
        store_wstrb_M = 4'b0000;
    endtask

    task automatic test_mem_default();
        apply_data_mem_default();
        #1;

        check_mem_data("mem default", 32'b0, mem_rdata_M);

        alu_result_M = 32'h0000_0010;
        #1;

        check_mem_data("mem default with addr 0x10", 32'b0, mem_rdata_M);

        alu_result_M = 32'h0000_03fc;
        #1;

        check_mem_data("mem default with addr 0x3fc", 32'b0, mem_rdata_M);
    endtask 

    task automatic test_mem_synchronous_write();
        apply_data_mem_default();
        
        @(negedge clk);
        mem_write_M = 1'b1;
        alu_result_M = 32'h0000_0010;
        store_wdata_M = 32'd5;
        store_wstrb_M = 4'b1111;
        #1;

        check_mem_data("synchronous write previous state", 32'd0, mem_rdata_M);

        @(posedge clk);
        #1;

        @(negedge clk);
        mem_write_M = 1'b0;
        #1;

        check_mem_data("synchronous write completed state", 32'd5, mem_rdata_M);
    endtask 

    task automatic test_mem_combinational_read();
        apply_data_mem_default();
        
        alu_result_M = 32'h0000_0010;
        #1;

        check_mem_data("combinational read", 32'd5, mem_rdata_M);
    endtask 

    task automatic test_mem_write_disabled();
        apply_data_mem_default();

        @(negedge clk);
        mem_write_M = 1'b1;
        alu_result_M = 32'h0000_0020;
        store_wdata_M = 32'd55;
        store_wstrb_M = 4'b1111;

        @(posedge clk);
        #1;

        @(negedge clk);
        mem_write_M = 1'b0;
        store_wdata_M = 32'd100;
        #1;

        check_mem_data("write disabled before clock edge", 32'd55, mem_rdata_M);

        @(posedge clk);
        #1;

        check_mem_data("write disabled after clock edge", 32'd55, mem_rdata_M);
    endtask

    task automatic test_low_address_bits_ignored();
        apply_data_mem_default();

        @(negedge clk);
        mem_write_M = 1'b1;
        alu_result_M = 32'h0000_0030;
        store_wdata_M = 32'd10;
        store_wstrb_M = 4'b1111;
        #1;

        check_mem_data("low address bits ignored write previous state", 
                        32'd0, mem_rdata_M);

        @(posedge clk);
        #1;

        @(negedge clk);
        mem_write_M = 1'b0;
        #1;

        check_mem_data("aligned address read", 32'd10, mem_rdata_M);

        alu_result_M = 32'h0000_0031;
        #1;
        check_mem_data("byte offset 1 aliases same word", 32'd10, mem_rdata_M);

        alu_result_M = 32'h0000_0032;
        #1;
        check_mem_data("byte offset 2 aliases same word", 32'd10, mem_rdata_M);

        alu_result_M = 32'h0000_0033;
        #1;
        check_mem_data("byte offset 3 aliases same word", 32'd10, mem_rdata_M);
    endtask 

    task automatic test_byte_lane_write();
        apply_data_mem_default();

        @(negedge clk);
        mem_write_M = 1'b1;
        alu_result_M = 32'h0000_0038;
        store_wdata_M = 32'h1122_3344;
        store_wstrb_M = 4'b1111;

        @(posedge clk);
        #1;

        @(negedge clk);
        store_wdata_M = 32'h0000_AA00;
        store_wstrb_M = 4'b0010;

        @(posedge clk);
        #1;

        @(negedge clk);
        mem_write_M = 1'b0;
        #1;

        check_mem_data("byte lane write preserves other lanes", 32'h1122_AA44, mem_rdata_M);
    endtask

    task automatic test_word_idx();
        apply_data_mem_default();

        @(negedge clk);
        mem_write_M = 1'b1;
        alu_result_M = 32'h0000_0040;
        store_wdata_M = 32'd20;
        store_wstrb_M = 4'b1111;

        @(posedge clk);
        #1;

        @(negedge clk);
        mem_write_M = 1'b1;
        alu_result_M = 32'h0000_0044;
        store_wdata_M = 32'd30;
        store_wstrb_M = 4'b1111;

        @(posedge clk);
        #1;

        @(negedge clk);
        mem_write_M = 1'b0;
        #1;

        check_mem_data("second adjacent word", 32'd30, mem_rdata_M);

        alu_result_M = 32'h0000_0040;
        #1;
        check_mem_data("first adjacent word remains unchanged", 32'd20, mem_rdata_M);

        alu_result_M = 32'h0000_0044;
        #1;
        check_mem_data("second adjacent word remains unchanged", 32'd30, mem_rdata_M);
    endtask 

    task automatic check_mem_data(
        input string name,
        input logic [WORD_WIDTH - 1:0] expected_mem_value,
        input logic [WORD_WIDTH - 1:0] real_mem_value
    );
        if (expected_mem_value !== real_mem_value) begin
            $fatal(1, "%s: memory data expected 0x%08h, got 0x%08h",
                   name, expected_mem_value, real_mem_value);
        end
    endtask 

endmodule
