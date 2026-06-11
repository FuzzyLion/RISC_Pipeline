module alu_op
    import core_types_pkg::*;
(
    input alu_ctrl_e alu_control_E,
    input btype_e btype_E,
    input logic branch_E,

    input logic [WORD_WIDTH - 1:0] alu_src_AE,
    input logic [WORD_WIDTH - 1:0] alu_src_BE,
    input logic [WORD_WIDTH - 1:0] pc_E,

    output logic zero_E,
    output logic [WORD_WIDTH - 1:0] alu_result_E
);

    always_comb begin
        alu_result_E = '0;

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
                alu_result_E = $signed(alu_src_AE) >>> alu_src_BE[4:0];
                // Keep the MSB when it's shifting
            end
            default: begin
                alu_result_E = '0;
            end
        endcase
        
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
