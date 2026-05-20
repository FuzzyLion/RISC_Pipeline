import core_types_pkg::*;

module pc_target_gen #(
    WORD_WIDTH = 32
)(
    input pc_target_src_e pc_target_src_E,

    input logic [WORD_WIDTH - 1:0] pc_E,
    input logic [WORD_WIDTH - 1:0] alu_src_AE,
    input logic [WORD_WIDTH - 1:0] imm_E,

    output logic [WORD_WIDTH - 1:0] pc_target_E
);
    
    always_comb begin
        case (pc_target_src_E)
            PC_TARGET_PC_IMM: begin
                pc_target_E = pc_E + imm_E;
            end 
            PC_TARGET_RS1_IMM: begin
                pc_target_E = (alu_src_AE + imm_E) & 32'hFFFFFFFE; 
                /* 
                Cannot use "rs1_val_E" because it will cause hazard, for example:

                addi x1, x0, target
                jalr x0, 0(x1)

                So we must use alu_src_AE here instead!!!
                */
            end
            default: begin
                pc_target_E = pc_E + imm_E; // Default function of this generator
            end
        endcase
    end

endmodule