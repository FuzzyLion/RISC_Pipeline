module control_unit
    import core_types_pkg::*;
(
    input logic [WORD_WIDTH - 1:0] instr_D,
    
    output imm_src_e imm_src_D,
    output control_bundle_t ctrl_D
);

    opcode_e opcode_D;
    rtype_e rtype_D;
    itype_load_e itype_load_D;
    itype_imm_e itype_imm_D;
    itype_immext_e itype_immext_D;
    stype_e stype_D;
    btype_e btype_D;
    logic [2:0] funct3;
    logic [6:0] funct7;

    localparam control_bundle_t CTRL_NOP = '{
        rf_write: 1'b0,
        result_src: RSLT_ALU,
        mem_write: 1'b0,
        jump: 1'b0,
        pc_target_src: PC_TARGET_PC_IMM,
        branch: 1'b0,
        alu_ctrl: CTRL_ADD,
        alu_src: BE_RDATA_E,
        funct3_ctrl: BEQ_FUNCT3
    };

    assign opcode_D = opcode_e'(instr_D[6:0]); 
    // Explain into "opcode_e" form and then transfer 7 bits value into 7 bit enum.
    // Decode raw opcode bits into the opcode enum used by the control case.
    
    assign funct3 = instr_D[14:12];
    assign funct7 = instr_D[31:25];

    assign rtype_D = rtype_e'({funct3, funct7});
    assign itype_load_D = itype_load_e'(funct3);
    assign itype_imm_D = itype_imm_e'(funct3);
    assign itype_immext_D = itype_immext_e'({funct3, funct7});
    assign stype_D = stype_e'(funct3);
    assign btype_D = btype_e'(funct3);


    always_comb begin

        ctrl_D = CTRL_NOP;
        imm_src_D = IMM_I;

        
        case (opcode_D)
            OP_RTYPE: begin // (51)

                case (rtype_D)
                    ADD: begin
                        ctrl_D.rf_write = 1'b1;
                        ctrl_D.alu_ctrl = CTRL_ADD;
                    end 
                    SUB: begin
                        ctrl_D.rf_write = 1'b1;
                        ctrl_D.alu_ctrl = CTRL_SUB;
                    end
                    SLL: begin
                        ctrl_D.rf_write = 1'b1;
                        ctrl_D.alu_ctrl = CTRL_SLL;
                    end
                    SLT: begin
                        ctrl_D.rf_write = 1'b1;
                        ctrl_D.alu_ctrl = CTRL_SLT;
                    end
                    SLTU: begin
                        ctrl_D.rf_write = 1'b1;
                        ctrl_D.alu_ctrl = CTRL_SLTU;
                    end
                    XOR: begin
                        ctrl_D.rf_write = 1'b1;
                        ctrl_D.alu_ctrl = CTRL_XOR;
                    end
                    SRL: begin
                        ctrl_D.rf_write = 1'b1;
                        ctrl_D.alu_ctrl = CTRL_SRL;
                    end 
                    SRA: begin
                        ctrl_D.rf_write = 1'b1;
                        ctrl_D.alu_ctrl = CTRL_SRA;
                    end
                    OR: begin
                        ctrl_D.rf_write = 1'b1;
                        ctrl_D.alu_ctrl = CTRL_OR;
                    end
                    AND: begin
                        ctrl_D.rf_write = 1'b1;
                        ctrl_D.alu_ctrl = CTRL_AND;
                    end
                    default: begin
                        ctrl_D.rf_write = 1'b0;
                        ctrl_D.alu_ctrl = CTRL_ADD;
                    end
                endcase
            end  

            OP_ITYPE_LOAD: begin // (3)

                case (itype_load_D)
                    LW: begin
                        ctrl_D.rf_write = 1'b1;
                        ctrl_D.result_src = RSLT_RDATA;
                        ctrl_D.alu_src = BE_IMM_E;
                    end
                    /*
                    LH:
                    LW:
                    LBU:
                    LHU:
                    */
                    default: begin
                        ctrl_D.rf_write = 1'b0;
                        ctrl_D.result_src = RSLT_ALU;
                        ctrl_D.alu_src = BE_RDATA_E;
                    end
                endcase
            end
                
            OP_ITYPE_IMM: begin //(19)

                case (itype_imm_D)
                    ADDI: begin
                        ctrl_D.rf_write = 1'b1;
                        ctrl_D.alu_ctrl = CTRL_ADD;
                        ctrl_D.alu_src = BE_IMM_E;
                    end
                    /*
                        SLTI:
                        SLTIU:
                        XORI:
                        ORI:
                        ANDI:
                        */
                    default: begin
                        case (itype_immext_D)
                            /*
                            SLLI:
                            SRLI:
                            SRAI: 
                            */ 
                            default: begin
                                ctrl_D.rf_write = 1'b0;
                                ctrl_D.alu_ctrl = CTRL_ADD;
                                ctrl_D.alu_src = BE_RDATA_E;
                            end
                        endcase
                    end
                endcase
            end

            OP_UTYPE_LUI: begin // (55)
                // LUI
                ctrl_D.rf_write = 1'b1;
                ctrl_D.alu_ctrl = CTRL_PASS_B;
                ctrl_D.alu_src = BE_IMM_E;
                imm_src_D = IMM_U;
            end

            OP_UTYPE_AUIPC: begin // (23)
                //AUIPC
                ctrl_D.rf_write = 1'b1;
                ctrl_D.pc_target_src = PC_TARGET_PC_IMM;
                ctrl_D.alu_ctrl = CTRL_PASS_B;
                ctrl_D.alu_src = BE_IMM_E;
                imm_src_D = IMM_U;
            end

            OP_STYPE: begin // (35)

                case (stype_D)
                    SW: begin
                        ctrl_D.mem_write = 1'b1;
                        ctrl_D.alu_src = BE_IMM_E;
                        imm_src_D = IMM_S;
                    end 
                    /*
                    SB:
                    SH:
                    */
                    default: begin
                        ctrl_D.mem_write = 1'b0;
                        ctrl_D.alu_src = BE_RDATA_E;
                        imm_src_D = IMM_I;
                    end
                endcase
            end

            OP_BTYPE: begin // (99)

                case (btype_D)
                    BEQ: begin
                        ctrl_D.branch = 1'b1;
                        ctrl_D.alu_ctrl = CTRL_SUB;
                        imm_src_D = IMM_B;
                        ctrl_D.funct3_ctrl = BEQ_FUNCT3;
                    end
                    BNE: begin
                        ctrl_D.branch = 1'b1;
                        ctrl_D.alu_ctrl = CTRL_SUB;
                        imm_src_D = IMM_B;
                        ctrl_D.funct3_ctrl = BNE_FUNCT3;
                    end
                    BLT: begin
                        ctrl_D.branch = 1'b1;
                        ctrl_D.alu_ctrl = CTRL_SUB;
                        imm_src_D = IMM_B;
                        ctrl_D.funct3_ctrl = BLT_FUNCT3;
                    end
                    BGE: begin
                        ctrl_D.branch = 1'b1;
                        ctrl_D.alu_ctrl = CTRL_SUB;
                        imm_src_D = IMM_B;
                        ctrl_D.funct3_ctrl = BGE_FUNCT3;
                    end
                    BLTU: begin
                        ctrl_D.branch = 1'b1;
                        ctrl_D.alu_ctrl = CTRL_SUB;
                        imm_src_D = IMM_B;
                        ctrl_D.funct3_ctrl = BLTU_FUNCT3;
                    end
                    BGEU: begin
                        ctrl_D.branch = 1'b1;
                        ctrl_D.alu_ctrl = CTRL_SUB;
                        imm_src_D = IMM_B;
                        ctrl_D.funct3_ctrl = BGEU_FUNCT3; 
                    end
                    default: begin
                        ctrl_D.branch = 1'b0;
                        ctrl_D.alu_ctrl = CTRL_ADD;
                        imm_src_D = IMM_I;
                        ctrl_D.funct3_ctrl = BEQ_FUNCT3;
                    end
                endcase
            end

            OP_ITYPE_JALR: begin // (103)
                // JALR

                if (funct3 == JALR) begin
                    ctrl_D.rf_write = 1'b1;
                    ctrl_D.result_src = RSLT_PCPLUS4;
                    ctrl_D.jump = 1'b1;
                    ctrl_D.pc_target_src = PC_TARGET_RS1_IMM;
                    ctrl_D.alu_src = BE_IMM_E;
                end else begin
                    ctrl_D.rf_write = 1'b0;
                    ctrl_D.result_src = RSLT_ALU;
                    ctrl_D.jump = 1'b0;
                    ctrl_D.pc_target_src = PC_TARGET_PC_IMM;
                    ctrl_D.alu_src = BE_RDATA_E;
                end
            end

            OP_JTYPE_JAL: begin // (111)
                // JAL
                ctrl_D.rf_write = 1'b1;
                ctrl_D.result_src = RSLT_PCPLUS4;
                ctrl_D.jump = 1'b1;
                imm_src_D = IMM_J;
            end
                
            default: begin
                ctrl_D = CTRL_NOP;
            end
        endcase

    end
    
endmodule
