module control_unit
    import core_types_pkg::*;
(
    input logic [WORD_WIDTH - 1:0] instr_D,
    
    output imm_src_e imm_src_D,
    output trap_event_e trap_event_illegal_instr_D,
    output control_bundle_t ctrl_D
);

    opcode_e opcode_D;
    rtype_e rtype_D;
    itype_load_e itype_load_D;
    itype_imm_e itype_imm_D;
    itype_immext_e itype_immext_D;
    stype_e stype_D;
    btype_e btype_D;
    csrtype_e csrtype_D;
    csr_imm_e csr_imm_D;
    logic [2:0] funct3;
    logic [6:0] funct7;
    logic [11:0] csr_source;

    localparam control_bundle_t CTRL_NOP = '{
        rf_write: 1'b0,
        result_src: RSLT_ALU,
        mem_write: 1'b0,
        jump: 1'b0,
        pc_target_src: PC_TARGET_PC_IMM,
        branch: 1'b0,
        alu_ctrl: CTRL_ADD,
        alu_src: BE_RDATA_E,
        btype: BEQ,
        load_type: LB,
        store_type: SB,
        csrtype: TRAP,
        csr_en: 1'b0,
        mret_en: 1'b0
    };

    assign opcode_D = opcode_e'(instr_D[6:0]); 
    // Explain into "opcode_e" form and then transfer 7 bits value into 7 bit enum.
    // Decode raw opcode bits into the opcode enum used by the control case.
    
    assign funct3 = instr_D[14:12];
    assign funct7 = instr_D[31:25];
    assign csr_source = instr_D[31:20];

    assign rtype_D = rtype_e'({funct3, funct7});
    assign itype_load_D = itype_load_e'(funct3);
    assign itype_imm_D = itype_imm_e'(funct3);
    assign itype_immext_D = itype_immext_e'({funct3, funct7});
    assign stype_D = stype_e'(funct3);
    assign btype_D = btype_e'(funct3);
    assign csrtype_D = csrtype_e'(funct3);
    assign csr_imm_D = csr_imm_e'(csr_source);


    always_comb begin

        ctrl_D = CTRL_NOP;
        imm_src_D = IMM_I;
        trap_event_illegal_instr_D = TRAP_EVENT_ILLEGAL_INSTR;

        
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
                        trap_event_illegal_instr_D = TRAP_EVENT_ILLEGAL_INSTR;
                    end
                endcase
            end  

            OP_ITYPE_LOAD: begin // (3)

                case (itype_load_D)
                    LB, LH, LW, LBU, LHU: begin
                        ctrl_D.rf_write = 1'b1;
                        ctrl_D.result_src = RSLT_RDATA;
                        ctrl_D.alu_src = BE_IMM_E;
                        ctrl_D.load_type = itype_load_D;
                    end
                    default: begin
                        ctrl_D.rf_write = 1'b0;
                        ctrl_D.result_src = RSLT_ALU;
                        ctrl_D.alu_src = BE_RDATA_E;
                        ctrl_D.load_type = LB;
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
                    SLTI: begin
                        ctrl_D.rf_write = 1'b1;
                        ctrl_D.alu_ctrl = CTRL_SLT;
                        ctrl_D.alu_src = BE_IMM_E;
                    end
                    SLTIU: begin
                        ctrl_D.rf_write = 1'b1;
                        ctrl_D.alu_ctrl = CTRL_SLTU;
                        ctrl_D.alu_src = BE_IMM_E;
                    end
                    XORI: begin
                        ctrl_D.rf_write = 1'b1;
                        ctrl_D.alu_ctrl = CTRL_XOR;
                        ctrl_D.alu_src = BE_IMM_E;
                    end
                    ORI: begin
                        ctrl_D.rf_write = 1'b1;
                        ctrl_D.alu_ctrl = CTRL_OR;
                        ctrl_D.alu_src = BE_IMM_E;
                    end
                    ANDI: begin
                        ctrl_D.rf_write = 1'b1;
                        ctrl_D.alu_ctrl = CTRL_AND;
                        ctrl_D.alu_src = BE_IMM_E;
                    end
                    default: begin

                        case (itype_immext_D)
                            SLLI: begin
                                ctrl_D.rf_write = 1'b1;
                                ctrl_D.alu_ctrl = CTRL_SLL;
                                ctrl_D.alu_src = BE_IMM_E;
                            end
                            SRLI: begin
                                ctrl_D.rf_write = 1'b1;
                                ctrl_D.alu_ctrl = CTRL_SRL;
                                ctrl_D.alu_src = BE_IMM_E;
                            end
                            SRAI: begin
                                ctrl_D.rf_write = 1'b1;
                                ctrl_D.alu_ctrl = CTRL_SRA;
                                ctrl_D.alu_src = BE_IMM_E;
                            end
                            default: begin
                                ctrl_D.rf_write = 1'b0;
                                ctrl_D.alu_ctrl = CTRL_ADD;
                                ctrl_D.alu_src = BE_RDATA_E;
                                trap_event_illegal_instr_D = TRAP_EVENT_ILLEGAL_INSTR;
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
                ctrl_D.alu_ctrl = CTRL_PASS_B4PC;
                imm_src_D = IMM_U;  
                ctrl_D.alu_src = BE_IMM_E;
            end

            OP_STYPE: begin // (35)
                case (stype_D)
                    SW, SB, SH: begin
                        ctrl_D.mem_write = 1'b1;
                        ctrl_D.alu_src = BE_IMM_E;
                        imm_src_D = IMM_S;
                        ctrl_D.store_type = stype_D;
                    end 
                    default: begin
                        ctrl_D.mem_write = 1'b0;
                        ctrl_D.alu_src = BE_RDATA_E;
                        imm_src_D = IMM_I;
                        ctrl_D.store_type = SB;
                        trap_event_illegal_instr_D = TRAP_EVENT_ILLEGAL_INSTR;
                    end
                endcase
            end

            OP_BTYPE: begin // (99)

                case (btype_D)
                    BEQ: begin
                        ctrl_D.branch = 1'b1;
                        ctrl_D.alu_ctrl = CTRL_SUB;
                        imm_src_D = IMM_B;
                        ctrl_D.btype = BEQ;
                    end
                    BNE: begin
                        ctrl_D.branch = 1'b1;
                        ctrl_D.alu_ctrl = CTRL_SUB;
                        imm_src_D = IMM_B;
                        ctrl_D.btype = BNE;
                    end
                    BLT: begin
                        ctrl_D.branch = 1'b1;
                        ctrl_D.alu_ctrl = CTRL_SUB;
                        imm_src_D = IMM_B;
                        ctrl_D.btype = BLT;
                    end
                    BGE: begin
                        ctrl_D.branch = 1'b1;
                        ctrl_D.alu_ctrl = CTRL_SUB;
                        imm_src_D = IMM_B;
                        ctrl_D.btype = BGE;
                    end
                    BLTU: begin
                        ctrl_D.branch = 1'b1;
                        ctrl_D.alu_ctrl = CTRL_SUB;
                        imm_src_D = IMM_B;
                        ctrl_D.btype = BLTU;
                    end
                    BGEU: begin
                        ctrl_D.branch = 1'b1;
                        ctrl_D.alu_ctrl = CTRL_SUB;
                        imm_src_D = IMM_B;
                        ctrl_D.btype = BGEU; 
                    end
                    default: begin
                        ctrl_D.branch = 1'b0;
                        ctrl_D.alu_ctrl = CTRL_ADD;
                        imm_src_D = IMM_I;
                        ctrl_D.btype = BEQ;
                        trap_event_illegal_instr_D = TRAP_EVENT_ILLEGAL_INSTR;
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
                    trap_event_illegal_instr_D = TRAP_EVENT_ILLEGAL_INSTR;
                end
            end

            OP_JTYPE_JAL: begin // (111)
                // JAL
                ctrl_D.rf_write = 1'b1;
                ctrl_D.result_src = RSLT_PCPLUS4;
                ctrl_D.jump = 1'b1;
                imm_src_D = IMM_J;
            end

            OP_CSR: begin // (115)
                ctrl_D.csr_en = 1'b1;

                case (csrtype_D)
                    TRAP: begin
                        ctrl_D.csrtype = TRAP;

                        case (csr_imm_D)
                            CSR_ECALL: begin
                                trap_event_illegal_instr_D = TRAP_EVENT_ENV_CALL_M_MODE;
                            end
                            CSR_EBREAK: begin
                                trap_event_illegal_instr_D = TRAP_EVENT_BREAKPOINT;
                            end
                            CSR_MRET: begin
                                if ((instr_D[19:15] == 5'b0) &&
                                    (instr_D[11:7] == 5'b0)) begin
                                    ctrl_D.mret_en = 1'b1;
                                end
                                else begin
                                    ctrl_D.mret_en = 1'b0;
                                    trap_event_illegal_instr_D = TRAP_EVENT_ILLEGAL_INSTR;
                                end
                            end
                            default: begin
                                trap_event_illegal_instr_D = TRAP_EVENT_ILLEGAL_INSTR;
                            end
                        endcase

                    end
                    CSRRW: begin
                        ctrl_D.rf_write = 1'b1;  
                        ctrl_D.result_src = RSLT_CSR_RDATA;
                        ctrl_D.csrtype = CSRRW;
                    end
                    CSRRS: begin
                        ctrl_D.rf_write = 1'b1;
                        ctrl_D.result_src = RSLT_CSR_RDATA;
                        ctrl_D.csrtype = CSRRS;
                    end
                    CSRRC: begin
                        ctrl_D.rf_write = 1'b1;
                        ctrl_D.result_src = RSLT_CSR_RDATA;
                        ctrl_D.csrtype = CSRRC;
                    end
                    CSRRWI: begin
                        ctrl_D.rf_write = 1'b1;
                        imm_src_D = IMM_CSR;
                        ctrl_D.result_src = RSLT_CSR_RDATA;
                        ctrl_D.csrtype = CSRRWI;
                    end
                    CSRRSI: begin
                        ctrl_D.rf_write = 1'b1;
                        imm_src_D = IMM_CSR;
                        ctrl_D.result_src = RSLT_CSR_RDATA;
                        ctrl_D.csrtype = CSRRSI;
                    end
                    CSRRCI:begin
                        ctrl_D.rf_write = 1'b1;
                        imm_src_D = IMM_CSR;
                        ctrl_D.result_src = RSLT_CSR_RDATA;
                        ctrl_D.csrtype = CSRRCI;
                    end
                    default: begin
                        trap_event_illegal_instr_D = TRAP_EVENT_ILLEGAL_INSTR;
                    end
                endcase
            end
                
            default: begin
                ctrl_D = CTRL_NOP;
                trap_event_illegal_instr_D = TRAP_EVENT_ILLEGAL_INSTR;
            end
        endcase

    end
    
endmodule
