module pc_target_gen
    import core_types_pkg::*;
(
    input pc_target_src_e pc_target_src_E,
    input logic jump_E,
    input logic branch_E,
    input logic zero_E,

    input logic mret_en_E,
    input logic [WORD_WIDTH - 1:0] pc_E,
    input logic [WORD_WIDTH - 1:0] alu_src_AE,
    // Make sure there's no forward to disturb the behaviour
    input logic [WORD_WIDTH - 1:0] imm_E,

    output trap_event_e trap_event_branch_jump_E,

    output logic [WORD_WIDTH - 1:0] pc_target_E,
    output pc_src_e pc_src_E
);

    logic redirect_E;
    
    always_comb begin
        trap_event_branch_jump_E = TRAP_EVENT_ILLEGAL_INSTR;

        case (pc_target_src_E)
            PC_TARGET_PC_IMM: begin
                pc_target_E = pc_E + imm_E;
            end 
            PC_TARGET_RS1_IMM: begin
                // JALR clears bit 0, producing at least a 2-byte-aligned target
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

        redirect_E = jump_E || (branch_E && zero_E);

        if ((pc_target_E[1:0] !== 2'b00) && redirect_E) begin
            // Exception event will be activated when the reirect is really enabled
            trap_event_branch_jump_E = TRAP_EVENT_INSTR_ADDR_MISALIGNED;
        end

        if (mret_en_E) begin
            pc_src_E = PC_MRET;
        end
        else if (redirect_E) begin
            pc_src_E = PC_TARGET;
        end
        else begin
            pc_src_E = PC_PLUS4;
        end

    end

endmodule
