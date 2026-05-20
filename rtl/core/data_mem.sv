module data_mem #(
    WORD_WIDTH = 32
)(
    input logic clk,
    input logic reset,

    input logic mem_write_M,

    input logic [WORD_WIDTH - 1:0] alu_result_M,
    input logic [WORD_WIDTH - 1:0] write_data_M,

    output logic [WORD_WIDTH - 1:0] mem_rdata_M
);

    always_ff @(posedge clk) begin
        if (reset) begin
            mem_rdata_M <= 32'b0;
        end
        else begin
            if (mem_write_M && (alu_result_M != 32'b0)) begin
                regs[alu_result_M] = write_data_M;
            end
        end
    end
    
endmodule