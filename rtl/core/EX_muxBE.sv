import core_types_pkg::*;

module EX_muxBE #(
    WORD_WIDTH = 32
)(
    input alu_src_e alu_src_E,

    input logic [WORD_WIDTH - 1:0] write_data_E,
    input logic [WORD_WIDTH - 1:0] imm_E,

    output logic [WORD_WIDTH - 1:0] alu_src_BE
);

    always_comb begin 
        case (alu_src_E)
            BE_RD_E: begin
                alu_src_BE = write_data_E;
            end 
            BE_IMM_E: begin
                alu_src_BE = imm_E;
            end
            default: begin
                alu_src_BE = 32'b0;
            end
        endcase
    end
    
endmodule