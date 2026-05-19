module MEM_WB (
    input logic clk,
    input logic reset,

    input logic rf_write_M,
    input logic [1:0] result_src_M,

    input logic valid_M,
    input logic [31:0] alu_result_M,
    input logic [31:0] mem_rdata_M,
    input logic [4:0] rd_idx_M,
    input logic [31:0] pc_plus4_M,

    output logic rf_write_W,
    output logic [1:0] result_src_W,

    output logic valid_W,
    output logic [31:0] alu_result_W,
    output logic [31:0] mem_rdata_W,
    output logic [4:0] rd_idx_W,
    output logic [31:0] pc_plus4_W
);

always_ff @(posedge clk) begin
    if (reset) begin
        rf_write_W <= 1'b0;
        result_src_W <= 2'b0;

        valid_W <= 1'b0;
        alu_result_W <= 32'b0;
        mem_rdata_W <= 32'b0;
        rd_idx_W <= 5'b0;
        pc_plus4_W <=32'b0;
    end
    else begin
        rf_write_W <= rf_write_M;
        result_src_W <= result_src_M;

        valid_W <= valid_M;
        alu_result_W <= alu_result_M;
        mem_rdata_W <= mem_rdata_M;
        rd_idx_W <= rd_idx_M;
        pc_plus4_W <= pc_plus4_M;
    end
end
    
endmodule