module pc_mux
    import core_types_pkg::*;
(
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
                pc_pre_F = '0;
            end
        endcase
    end

endmodule
