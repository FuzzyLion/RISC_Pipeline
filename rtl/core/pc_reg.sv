module pc_reg #(
    WORD_WIDTH = 32
)(
    input logic clk,
    input logic reset,

    input logic stall_F,

    input logic [WORD_WIDTH - 1:0] pc_pre_F,

    output logic [WORD_WIDTH - 1:0] pc_F
);

    always_ff @(posedge clk) begin
        if (reset) begin
            pc_F <= 32'b0;
        end
        else if (!stall_F) begin
            // When register is not stalled, then it can fetch the next PC
            pc_F <= pc_pre_F;
        end
    end
    
endmodule