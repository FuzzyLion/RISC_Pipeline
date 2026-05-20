import core_types_pkg::*;

module EX_forward_muxAE #(
    WORD_WIDTH = 32
)(
    input forward_ae forward_AE,

    input logic [WORD_WIDTH - 1:0] rs1_val_E,
    input logic [WORD_WIDTH - 1:0] result_W,
    input logic [WORD_WIDTH - 1:0] alu_result_M,

    output logic [WORD_WIDTH - 1:0] alu_src_AE
);

    always_comb begin
        case (forward_AE)
            AE_RS1_VAL: begin
                alu_src_AE = rs1_val_E;
            end 
            AE_RSLT_W: begin
                alu_src_AE = result_W;
            end
            AE_ALURSLT_W: begin
                alu_src_AE = alu_result_M;
            end
            default: begin
                alu_src_AE = 32'b0;
            end
        endcase
    end
    
endmodule