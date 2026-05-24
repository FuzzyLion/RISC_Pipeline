import core_types_pkg::*;

module WB_result_mux (
    input logic [WORD_WIDTH - 1:0] alu_result_W,
    input logic [WORD_WIDTH - 1:0] mem_rdata_W,
    input logic [WORD_WIDTH - 1:0] pc_plus4_W,

    input result_src_e result_src_W,

    output logic [WORD_WIDTH - 1:0] result_W
);
    
    always_comb begin
        case (result_src_W)
            RSLT_ALU: begin
                result_W = alu_result_W;
            end
            RSLT_RDATA: begin
                result_W = mem_rdata_W;
            end
            RSLT_PCPLUS4: begin
                result_W = pc_plus4_W;
            end
            default: begin
                result_W = 32'b0;
            end
        endcase
    end

endmodule
