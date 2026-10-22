module alu_op
    import core_types_pkg::*;
(
    input alu_ctrl_e alu_control_E,
    input logic mem_write_E,
    input btype_e btype_E,
    input itype_load_e load_type_E,
    input stype_e store_type_E,
    input result_src_e result_src_E,
    input logic branch_E,

    input logic [WORD_WIDTH - 1:0] alu_src_AE,
    input logic [WORD_WIDTH - 1:0] alu_src_BE,
    input logic [WORD_WIDTH - 1:0] pc_E,

    output trap_event_e trap_event_load_store_E,

    output logic zero_E,
    output logic [WORD_WIDTH - 1:0] alu_result_E
);

    logic is_load_E;
    logic is_store_E;

    assign is_load_E = (result_src_E == RSLT_RDATA);
    assign is_store_E = (mem_write_E == 1'b1);

    always_comb begin
        alu_result_E = '0;
        trap_event_load_store_E = TRAP_EVENT_NONE;

        // 1. ALU
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
            CTRL_XOR: begin
                alu_result_E = alu_src_AE ^ alu_src_BE;
            end
            CTRL_PASS_B: begin
                alu_result_E = alu_src_BE; // Instruction lui
            end
            CTRL_PASS_B4PC: begin
                alu_result_E = alu_src_BE + pc_E; // Instruction auipc
            end
            CTRL_SLT: begin // Signed
                alu_result_E = {{(WORD_WIDTH - 1){1'b0}}, ($signed(alu_src_AE) < $signed(alu_src_BE))};
            end
            CTRL_SLTU: begin
                alu_result_E = {{(WORD_WIDTH - 1){1'b0}}, (alu_src_AE < alu_src_BE)};
            end
            CTRL_SLL: begin
                alu_result_E = alu_src_AE << alu_src_BE[4:0];
                // Only focus on the lower 5bits of rs2, because the maximum num of bits is 32 (2^5)
            end
            CTRL_SRL: begin
                alu_result_E = alu_src_AE >> alu_src_BE[4:0];
            end
            CTRL_SRA: begin
                alu_result_E = $unsigned($signed(alu_src_AE) >>> alu_src_BE[4:0]);
                // Keep the MSB when it's shifting
            end
            default: begin
                alu_result_E = '0;
            end
        endcase

        // 2. Load / Store Check
        if (is_load_E) begin
            case (load_type_E)
                LB, LBU: begin
                    // 1-byte load is always aligned, no check needed
                end
                LH, LHU: begin
                    if (alu_result_E[0] != 1'b0) begin
                        trap_event_load_store_E = TRAP_EVENT_LOAD_ADDR_MISALIGNED;
                    end
                end
                LW: begin
                    if (alu_result_E[1:0] != 2'b00) begin
                        trap_event_load_store_E = TRAP_EVENT_LOAD_ADDR_MISALIGNED;
                    end
                end
                default: begin
                    trap_event_load_store_E = TRAP_EVENT_ILLEGAL_INSTR;
                end
            endcase
        end
        else if (is_store_E) begin
            case (store_type_E)
                SB: begin
                    // 1-byte store is always aligned, no check needed
                end
                SH: begin
                    if (alu_result_E[0] != 1'b0) begin
                        trap_event_load_store_E = TRAP_EVENT_STORE_ADDR_MISALIGNED;
                    end
                end
                SW: begin
                    if (alu_result_E[1:0] != 2'b00) begin
                        trap_event_load_store_E = TRAP_EVENT_STORE_ADDR_MISALIGNED;
                    end
                end
                default: begin
                    trap_event_load_store_E = TRAP_EVENT_ILLEGAL_INSTR;
                end
            endcase
        end
        
        // 3. Branch Compare / Zero Detect
        if (branch_E) begin
            case (btype_E)
                BEQ: begin
                    zero_E = (alu_result_E == '0);
                end 
                BNE: begin
                    zero_E = (alu_result_E != '0) ? 1'b1 : 1'b0;
                end
                BLT: begin // Signed comparition with $signed
                    zero_E = ($signed(alu_src_AE) < $signed(alu_src_BE)) ? 1'b1 : 1'b0;
                end
                BGE: begin
                    zero_E = ($signed(alu_src_AE) >= $signed(alu_src_BE)) ? 1'b1 : 1'b0;
                end
                BLTU: begin // Unsigned comparition
                    zero_E = (alu_src_AE < alu_src_BE) ? 1'b1 : 1'b0;
                end
                BGEU: begin
                    zero_E = (alu_src_AE >= alu_src_BE) ? 1'b1 : 1'b0;
                end
                default: begin
                    zero_E = 1'b0;
                end
            endcase
        end 
        else begin
            zero_E = (alu_result_E == '0); 
            // Keep original behavior for debug/future use to test if result = '0
        end
        
        
    end
    
endmodule
