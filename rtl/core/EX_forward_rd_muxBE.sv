module EX_forward_rd_muxBE
    import core_types_pkg::*;
(
    input forward_rdata_be forward_rd_BE,

    input logic [WORD_WIDTH - 1:0] rs2_val_E,
    input logic [WORD_WIDTH - 1:0] result_W,
    input logic [WORD_WIDTH - 1:0] alu_result_M,
    input logic [WORD_WIDTH - 1:0] csr_rdata_M,

    output logic [WORD_WIDTH - 1:0] write_data_E
);

    always_comb begin
        case (forward_rd_BE)
            BE_RDATA_RS2_VAL: begin
                write_data_E = rs2_val_E;
            end 
            BE_RDATA_RESULT_W: begin
                write_data_E = result_W;
            end
            BE_RDATA_ALU_RESULT_M: begin
                write_data_E = alu_result_M;
            end
            BE_CSR_RDATA_M: begin
                write_data_E = csr_rdata_M;
            end
            default: begin
                write_data_E = '0;
            end
        endcase
    end
    
endmodule
