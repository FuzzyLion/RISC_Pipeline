module EX_MEM #(
    parameter WORD_WIDTH = 32,
    parameter ADDR_WIDTH = 5
)(
    input logic clk,
    input logic reset,

    input logic rf_write_E,
    input logic [1:0] result_src_E,
    input logic mem_write_E,
    
    input logic valid_E,
    input logic [WORD_WIDTH - 1:0] alu_result_E,
    input logic [WORD_WIDTH - 1:0] write_data_E,
    input logic [ADDR_WIDTH - 1:0] rd_idx_E,
    input logic [WORD_WIDTH - 1:0] pc_plus4_E,

    output logic rf_write_M,
    output logic [1:0] result_src_M,
    output logic mem_write_M,

    output logic valid_M,
    output logic [WORD_WIDTH - 1:0] alu_result_M,
    output logic [WORD_WIDTH - 1:0] write_data_M,
    output logic [ADDR_WIDTH - 1:0] rd_idx_M,
    output logic [WORD_WIDTH - 1:0] pc_plus4_M
);

always_ff @(posedge clk) begin
    if (reset) begin
        rf_write_M <= 1'b0;
        result_src_M <= 2'b0;
        mem_write_M <= 1'b0;

        valid_M <= 1'b0;
        alu_result_M <= 32'b0;
        write_data_M <= 32'b0;
        rd_idx_M <= 5'b0;
        pc_plus4_M <= 32'b0;
    end
    else begin
        rf_write_M <= rf_write_E;
        result_src_M <= result_src_E;
        mem_write_M <= mem_write_E;

        valid_M <= valid_E;
        alu_result_M <= alu_result_E;
        write_data_M <= write_data_E;
        rd_idx_M <= rd_idx_E;
        pc_plus4_M <= pc_plus4_E;
    end
end
    
endmodule