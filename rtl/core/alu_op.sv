import core_types_pkg::*;

module alu_op #(
    parameter WORD_WIDTH = 32
)(
    input alu_control_e alu_control_E,

    input logic [WORD_WIDTH - 1:0] alu_src_AE,
    input logic [WORD_WIDTH - 1:0] alu_src_BE,

    output logic zero_E,
    output logic [WORD_WIDTH - 1:0] alu_result_E
);

always_comb begin
    alu_result_E = 32'b0;

    case (alu_control_E)
        CTRL_ADD: begin
            alu_result_E = alu_src_AE + alu_src_BE;
        end
        CTRL_SUB: begin
            alu_result_E = alu_src_AE - alu_src_BE;
        end
        CTRL_AND: begin
            alu_result_E = alu_src_AE & alu_src_BE;
        end
        CTRL_OR: begin
            alu_result_E = alu_src_AE | alu_src_BE;
        end
        CTRL_SLT: begin // Signed
            alu_result_E = {{(WORD_WIDTH - 1){1'b0}}, ($signed(alu_src_AE) < $signed(alu_src_BE))};
        end
        CTRL_PASS_B: begin
            alu_result_E = alu_src_BE; // Instruction lui
        end
        default: begin
            alu_result_E = 32'b0;
        end
    endcase
    
    zero_E = (alu_result_E == '0);
end
    
endmodule
