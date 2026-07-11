module WB_result_mux
    import core_types_pkg::*;
(
    input logic [WORD_WIDTH - 1:0] alu_result_W,
    input logic [WORD_WIDTH - 1:0] load_result_W,
    input logic [WORD_WIDTH - 1:0] pc_plus4_W,
    input logic [WORD_WIDTH - 1:0] csr_rdata_W,

    input result_src_e result_src_W,

    output logic [WORD_WIDTH - 1:0] result_W
);
    
    always_comb begin
        case (result_src_W)
            RSLT_ALU: begin
                result_W = alu_result_W;
            end
            RSLT_RDATA: begin
                result_W = load_result_W;
            end
            RSLT_PCPLUS4: begin
                result_W = pc_plus4_W;
            end
            RSLT_CSR_RDATA: begin
                result_W = csr_rdata_W;
            end
            default: begin
                result_W = '0;
            end
        endcase
    end

endmodule
