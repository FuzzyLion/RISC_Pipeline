import core_types_pkg::*;

module IF_pc_mux #(
    WORD_WIDTH = 32
)(
    input pc_src_e pc_src_E,

    input logic [WORD_WIDTH - 1:0] pc_target_E,
    input logic [WORD_WIDTH - 1:0] pc_plus4_F,

    output logic [WORD_WIDTH - 1:0] pc_pre_F
);
    
    always_comb begin
        case (pc_src_E)
            PC_PLUS4: begin
                pc_pre_F = pc_plus4_F;
            end 
            PC_TARGET: begin
                pc_pre_F = pc_target_E;
            end
            default: begin
                pc_pre_F = 32'b0;
            end
        endcase
    end

endmodule