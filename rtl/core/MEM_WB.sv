import core_types_pkg::*;

module MEM_WB #(
    parameter WORD_WIDTH = 32,
    parameter ADDR_WIDTH = 5
)(
    input logic clk,
    input logic reset,

    input logic rf_write_M,
    input result_src_e result_src_M,

    input logic valid_M,
    input logic [WORD_WIDTH - 1:0] alu_result_M,
    input logic [WORD_WIDTH - 1:0] mem_rdata_M,
    input logic [ADDR_WIDTH - 1:0] rd_idx_M,
    input logic [WORD_WIDTH - 1:0] pc_plus4_M,

    output logic rf_write_W,
    output result_src_e result_src_W,

    output logic valid_W,
    output logic [WORD_WIDTH - 1:0] alu_result_W,
    output logic [WORD_WIDTH - 1:0] mem_rdata_W,
    output logic [ADDR_WIDTH - 1:0] rd_idx_W,
    output logic [WORD_WIDTH - 1:0] pc_plus4_W
);

    always_ff @(posedge clk) begin
        if (reset) begin
            rf_write_W <= 1'b0;
            result_src_W <= RSLT_ALU;

            valid_W <= 1'b0;
            alu_result_W <= 32'b0;
            mem_rdata_W <= 32'b0;
            rd_idx_W <= 5'b0;
            pc_plus4_W <= 32'b0;
        end
        else begin
            rf_write_W <= valid_M && rf_write_M;
            result_src_W <= result_src_M;

            valid_W <= valid_M;
            alu_result_W <= alu_result_M;
            mem_rdata_W <= mem_rdata_M;
            rd_idx_W <= rd_idx_M;
            pc_plus4_W <= pc_plus4_M;
        end
    end
    
endmodule