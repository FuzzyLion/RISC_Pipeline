import core_types_pkg::*; //Global import

module imm_ext (
    input imm_src_e imm_src_D,

    input logic [WORD_WIDTH - 1:0] instr_D,

    output logic [WORD_WIDTH - 1:0] imm_D
);

    always_comb begin
        imm_D = 32'b0;

        case (imm_src_D)
            IMM_I: begin
                imm_D = {{20{instr_D[31]}}, instr_D[31:20]};
                //I-Type Instructions - 12-bits signed immediate
            end
            IMM_S: begin
                imm_D = {{20{instr_D[31]}}, instr_D[31:25], instr_D[11:7]};
                //S-Type Instructions - 12-bits signed immediate
            end
            IMM_B: begin
                imm_D = {{20{instr_D[31]}}, instr_D[7], instr_D[30:25], instr_D[11:8], 1'b0};
                //B-Type Instrctions - 13-bits signed immediate
            end
            IMM_J: begin
                imm_D = {{12{instr_D[31]}}, instr_D[19:12], instr_D[20], instr_D[30:21], 1'b0};
                //J-Type Instructions - 21-bits signed immediate
            end
            IMM_U: begin
                imm_D = {instr_D[31:12], 12'b0};
                //U-Type Instructions - 20-bits signed immediate
            end
            default: begin
                imm_D = 32'b0;
            end
        endcase
    end
    
endmodule
