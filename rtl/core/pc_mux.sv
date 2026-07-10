module pc_mux
    import core_types_pkg::*;
(
    input pc_src_e pc_src_E,
    input pc_src_with_trap_e pc_src_with_trap_E,

    input logic [WORD_WIDTH - 1:0] pc_target_E,
    input logic [WORD_WIDTH - 1:0] pc_plus4_F,
    input logic [WORD_WIDTH - 1:0] mtvec_reg,

    output logic [WORD_WIDTH - 1:0] pc_pre_F
);
    
    always_comb begin
        if (pc_src_with_trap_E == PC_TRAP_HANDLER) begin
            pc_pre_F = mtvec_reg;
        end
        else begin
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
    end

endmodule
