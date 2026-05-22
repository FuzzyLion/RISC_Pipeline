import core_types_pkg::*;

module control_unit #(
    WORD_WIDTH = 32,
    FUNCT7_EN = 7'b0100000,
    FUNCT7_DI = 7'b0000000
)(
    input logic [WORD_WIDTH - 1:0] instr_D,

    output logic rf_write_D,
    output result_src_e result_src_D,
    output logic mem_write_D,
    output logic jump_D,
    output pc_target_src_e pc_target_src_D,
    output logic branch_D,
    output alu_ctrl_e alu_ctrl_D,
    output alu_src_e alu_src_D,
    output imm_src_e imm_src_D
);

    logic [6:0] opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;

    assign opcode = instr_D[6:0];
    assign funct3 = instr_D[14:12];
    assign funct7 = instr_D[31:25];

    always_comb begin

        rf_write_D = 1'b0;
        result_src_D = RSLT_IDLE;
        mem_write_D = 1'b0;
        jump_D = 1'b0;
        pc_target_src_D = PC_TARGET_PC_IMM;
        branch_D = 1'b0;
        alu_ctrl_D = CTRL_IDLE;
        alu_src_D = BE_IDLE;
        imm_src_D = IMM_IDLE;

        case (opcode)
            7'b0110011: begin // (51)
                rf_write_D = 1'b1;
                result_src_D = RSLT_ALU;
                mem_write_D = 1'b0;
                jump_D = 1'b0;
                pc_target_src_D = PC_TARGET_PC_IMM;
                branch_D = 1'b0;
                alu_ctrl_D = CTRL_IDLE;
                alu_src_D = BE_RDATA_E;
                imm_src_D = IMM_IDLE;

                case (funct3)
                    3'b000: begin
                        // ADD & SUB
                        if (funct7 == FUNCT7_DI) begin
                            alu_ctrl_D = CTRL_ADD;
                        end else if (funct7 == FUNCT7_EN) begin
                            alu_ctrl_D = CTRL_SUB;
                        end
                    end 
                    3'b001: begin
                        // SLL
                        if (funct7 == FUNCT7_DI) begin
                            alu_ctrl_D = CTRL_SLL;
                        end else begin
                            alu_ctrl_D = CTRL_IDLE;
                        end
                    end
                    3'b010: begin
                        //SLT
                        if (funct7 == FUNCT7_DI) begin
                            alu_ctrl_D = CTRL_SLT;
                        end
                    end
                    3'b011: begin
                        // SLTU
                        if (funct7 == FUNCT7_DI) begin
                            alu_ctrl_D = CTRL_SLTU;
                        end
                    end
                    3'b100: begin
                        //XOR
                        if (funct7 == FUNCT7_DI) begin
                            alu_ctrl_D = CTRL_XOR;
                        end 
                    end
                    3'b101: begin
                        //SRL & SRA
                        if (funct7 == FUNCT7_DI) begin
                            alu_ctrl_D = CTRL_SRL;
                        end else if (funct7 == FUNCT7_EN) begin
                            alu_ctrl_D = CTRL_SRA;
                        end
                    end
                    3'b110: begin
                        //OR
                        if (funct7 == FUNCT7_DI) begin
                            alu_ctrl_D = CTRL_OR;
                        end 
                    end
                    3'b111: begin
                        //AND
                        if (funct7 == FUNCT7_DI) begin
                            alu_ctrl_D = CTRL_AND;
                        end 
                    end
                    default: alu_ctrl_D = CTRL_IDLE;
                endcase
            end  

            7'b0000011: begin // (3)
                // LW
                rf_write_D = 1'b1;
                result_src_D = RSLT_RDATA;
                mem_write_D = 1'b0;
                jump_D = 1'b0;
                pc_target_src_D = PC_TARGET_PC_IMM;
                branch_D = 1'b0;
                alu_ctrl_D = CTRL_ADD;
                alu_src_D = BE_IMM_E;
                imm_src_D = IMM_I;

                // Use case & if sentences to wirte more "load" instructions control here,
                // gonna do this in the future
            end
                
            7'b0010011: begin //(19)
                // ADDI
                rf_write_D = 1'b1;
                result_src_D = RSLT_ALU;
                mem_write_D = 1'b0;
                jump_D = 1'b0;
                pc_target_src_D = PC_TARGET_PC_IMM;
                branch_D = 1'b0;
                alu_ctrl_D = CTRL_ADD;
                alu_src_D = BE_IMM_E;
                imm_src_D = IMM_I;

                // Use case & if sentences to wirte more "load" instructions control here,
                // gonna do this in the future
            end

            7'b0110111: begin // (55)
                // LUI
                rf_write_D = 1'b1;
                result_src_D = RSLT_ALU;
                mem_write_D = 1'b0;
                jump_D = 1'b0;
                pc_target_src_D = PC_TARGET_PC_IMM;
                branch_D = 1'b0;
                alu_ctrl_D = CTRL_PASS_B;
                alu_src_D = BE_IMM_E;
                imm_src_D = IMM_U;
            end

            7'b0100011: begin // (35)
                // SW
                rf_write_D = 1'b0;
                result_src_D = RSLT_IDLE;
                mem_write_D = 1'b1;
                jump_D = 1'b0;
                pc_target_src_D = PC_TARGET_PC_IMM;
                branch_D = 1'b0;
                alu_ctrl_D = CTRL_ADD;
                alu_src_D = BE_IMM_E;
                imm_src_D = IMM_S;
            end

            7'b1100011: begin // (99)
                // BEQ
                rf_write_D = 1'b0;
                result_src_D = RSLT_IDLE;
                mem_write_D = 1'b0;
                jump_D = 1'b0;
                pc_target_src_D = PC_TARGET_PC_IMM;
                branch_D = 1'b1;
                alu_ctrl_D = CTRL_SUB;
                alu_src_D = BE_RDATA_E;
                imm_src_D = IMM_B;
            end

            7'b1100111: begin // (103)
                // JALR
                rf_write_D = 1'b1;
                result_src_D = RSLT_PCPLUS4;
                mem_write_D = 1'b0;
                jump_D = 1'b1;
                pc_target_src_D = PC_TARGET_RS1_IMM;
                branch_D = 1'b0;
                alu_ctrl_D = CTRL_ADD;
                alu_src_D = BE_IMM_E;
                imm_src_D = IMM_I;
            end

            7'b1101111: begin // (111)
                // JAL
                rf_write_D = 1'b1;
                result_src_D = RSLT_PCPLUS4;
                mem_write_D = 1'b0;
                jump_D = 1'b1;
                pc_target_src_D = PC_TARGET_PC_IMM;
                branch_D = 1'b0;
                alu_ctrl_D = CTRL_IDLE;
                alu_src_D = BE_IDLE;
                imm_src_D = IMM_J;
            end
                
            default: begin
                rf_write_D = 1'b0;
                result_src_D = RSLT_IDLE;
                mem_write_D = 1'b0;
                jump_D = 1'b0;
                pc_target_src_D = PC_TARGET_PC_IMM;
                branch_D = 1'b0;
                alu_ctrl_D = CTRL_IDLE;
                alu_src_D = BE_IDLE;
                imm_src_D = IMM_IDLE;
            end
        endcase

    end
    
endmodule
