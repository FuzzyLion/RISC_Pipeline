import core_types_pkg::*;

module EX_forward_rd_muxBE #(
    WORD_WIDTH = 32
)(
    input forward_rdata_be forward_rd_BE,

    input logic [WORD_WIDTH - 1:0] rs2_val_E,
    input logic [WORD_WIDTH - 1:0] result_W,
    input logic [WORD_WIDTH - 1:0] alu_result_M,

    output logic [WORD_WIDTH - 1:0] write_data_E
);

    always_comb begin
        case (forward_rd_BE)
            BE_RDATA_RS2_VAL: begin
                write_data_E = rs2_val_E;
            end 
            BE_RDATA_RSLT_W: begin
                write_data_E = result_W;
            end
            BE_RDATA_ALURSLT_W: begin
                write_data_E = alu_result_M;
            end
            default: begin
                write_data_E = 32'b0;
            end
        endcase
    end
    
endmodule