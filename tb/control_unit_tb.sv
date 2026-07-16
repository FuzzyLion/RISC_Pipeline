`timescale 1ps/1ps

module control_unit_tb 
    import core_types_pkg::*;
();
    
    logic [WORD_WIDTH - 1:0] instr_D;

    imm_src_e imm_src_D;
    trap_event_e trap_event_illegal_instr_D;
    control_bundle_t ctrl_D;

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

    localparam control_bundle_t CTRL_ITYPE_IMM = '{
        rf_write: 1'b1,
        result_src: RSLT_ALU,
        mem_write: 1'b0,
        jump: 1'b0,
        pc_target_src: PC_TARGET_PC_IMM,
        branch: 1'b0,
        alu_ctrl: CTRL_ADD,
        alu_src: BE_IMM_E,
        btype: BEQ,
        load_type: LB,
        store_type: SB,
        csrtype: TRAP,
        csr_en: 1'b0,
        mret_en: 1'b0
    };

    localparam control_bundle_t CTRL_UTYPE = '{
        rf_write: 1'b1,
        result_src: RSLT_ALU,
        mem_write: 1'b0,
        jump: 1'b0,
        pc_target_src: PC_TARGET_PC_IMM,
        branch: 1'b0,
        alu_ctrl: CTRL_PASS_B,
        alu_src: BE_IMM_E,
        btype: BEQ,
        load_type: LB,
        store_type: SB,
        csrtype: TRAP,
        csr_en: 1'b0,
        mret_en: 1'b0
    };

    localparam control_bundle_t CTRL_STYPE = '{
        rf_write: 1'b0,
        result_src: RSLT_ALU,
        mem_write: 1'b1,
        jump: 1'b0,
        pc_target_src: PC_TARGET_PC_IMM,
        branch: 1'b0,
        alu_ctrl: CTRL_ADD,
        alu_src: BE_IMM_E,
        btype: BEQ,
        load_type: LB,
        store_type: SW,
        csrtype: TRAP,
        csr_en: 1'b0,
        mret_en: 1'b0
    };

    localparam control_bundle_t CTRL_RTYPE = '{
        rf_write: 1'b1,
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

    localparam control_bundle_t CTRL_BTYPE = '{
        rf_write: 1'b0,
        result_src: RSLT_ALU,
        mem_write: 1'b0,
        jump: 1'b0,
        pc_target_src: PC_TARGET_PC_IMM,
        branch: 1'b1,
        alu_ctrl: CTRL_SUB,
        alu_src: BE_RDATA_E,
        btype: BEQ,
        load_type: LB,
        store_type: SB,
        csrtype: TRAP,
        csr_en: 1'b0,
        mret_en: 1'b0
    };

    localparam control_bundle_t CTRL_JTYPE = '{
        rf_write: 1'b1,
        result_src: RSLT_PCPLUS4,
        mem_write: 1'b0,
        jump: 1'b1,
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

    localparam control_bundle_t CTRL_ITYPE_LOAD = '{
        rf_write: 1'b1,
        result_src: RSLT_RDATA,
        mem_write: 1'b0,
        jump: 1'b0,
        pc_target_src: PC_TARGET_PC_IMM,
        branch: 1'b0,
        alu_ctrl: CTRL_ADD,
        alu_src: BE_IMM_E,
        btype: BEQ,
        load_type: LW,
        store_type: SB,
        csrtype: TRAP,
        csr_en: 1'b0,
        mret_en: 1'b0
    };

    localparam control_bundle_t CTRL_ITYPE_JALR = '{
        rf_write: 1'b1,
        result_src: RSLT_PCPLUS4,
        mem_write: 1'b0,
        jump: 1'b1,
        pc_target_src: PC_TARGET_RS1_IMM,
        branch: 1'b0,
        alu_ctrl: CTRL_ADD,
        alu_src: BE_IMM_E,
        btype: BEQ,
        load_type: LB,
        store_type: SB,
        csrtype: TRAP,
        csr_en: 1'b0,
        mret_en: 1'b0
    };

    localparam control_bundle_t CTRL_UTYPE_AUIPC = '{
        rf_write: 1'b1,
        result_src: RSLT_ALU,
        mem_write: 1'b0,
        jump: 1'b0,
        pc_target_src: PC_TARGET_PC_IMM,
        branch: 1'b0,
        alu_ctrl: CTRL_PASS_B4PC,
        alu_src: BE_IMM_E,
        btype: BEQ,
        load_type: LB,
        store_type: SB,
        csrtype: TRAP,
        csr_en: 1'b0,
        mret_en: 1'b0
    };

    localparam control_bundle_t CTRL_RTYPE_SUB = '{
        rf_write: 1'b1,
        result_src: RSLT_ALU,
        mem_write: 1'b0,
        jump: 1'b0,
        pc_target_src: PC_TARGET_PC_IMM,
        branch: 1'b0,
        alu_ctrl: CTRL_SUB,
        alu_src: BE_RDATA_E,
        btype: BEQ,
        load_type: LB,
        store_type: SB,
        csrtype: TRAP,
        csr_en: 1'b0,
        mret_en: 1'b0
    };

    localparam control_bundle_t CTRL_RTYPE_SLL = '{
        rf_write: 1'b1,
        result_src: RSLT_ALU,
        mem_write: 1'b0,
        jump: 1'b0,
        pc_target_src: PC_TARGET_PC_IMM,
        branch: 1'b0,
        alu_ctrl: CTRL_SLL,
        alu_src: BE_RDATA_E,
        btype: BEQ,
        load_type: LB,
        store_type: SB,
        csrtype: TRAP,
        csr_en: 1'b0,
        mret_en: 1'b0
    };

    localparam control_bundle_t CTRL_RTYPE_SLT = '{
        rf_write: 1'b1,
        result_src: RSLT_ALU,
        mem_write: 1'b0,
        jump: 1'b0,
        pc_target_src: PC_TARGET_PC_IMM,
        branch: 1'b0,
        alu_ctrl: CTRL_SLT,
        alu_src: BE_RDATA_E,
        btype: BEQ,
        load_type: LB,
        store_type: SB,
        csrtype: TRAP,
        csr_en: 1'b0,
        mret_en: 1'b0
    };

    localparam control_bundle_t CTRL_RTYPE_SLTU = '{
        rf_write: 1'b1,
        result_src: RSLT_ALU,
        mem_write: 1'b0,
        jump: 1'b0,
        pc_target_src: PC_TARGET_PC_IMM,
        branch: 1'b0,
        alu_ctrl: CTRL_SLTU,
        alu_src: BE_RDATA_E,
        btype: BEQ,
        load_type: LB,
        store_type: SB,
        csrtype: TRAP,
        csr_en: 1'b0,
        mret_en: 1'b0
    };

    localparam control_bundle_t CTRL_RTYPE_XOR = '{
        rf_write: 1'b1,
        result_src: RSLT_ALU,
        mem_write: 1'b0,
        jump: 1'b0,
        pc_target_src: PC_TARGET_PC_IMM,
        branch: 1'b0,
        alu_ctrl: CTRL_XOR,
        alu_src: BE_RDATA_E,
        btype: BEQ,
        load_type: LB,
        store_type: SB,
        csrtype: TRAP,
        csr_en: 1'b0,
        mret_en: 1'b0
    };

    localparam control_bundle_t CTRL_RTYPE_SRL = '{
        rf_write: 1'b1,
        result_src: RSLT_ALU,
        mem_write: 1'b0,
        jump: 1'b0,
        pc_target_src: PC_TARGET_PC_IMM,
        branch: 1'b0,
        alu_ctrl: CTRL_SRL,
        alu_src: BE_RDATA_E,
        btype: BEQ,
        load_type: LB,
        store_type: SB,
        csrtype: TRAP,
        csr_en: 1'b0,
        mret_en: 1'b0
    };

    localparam control_bundle_t CTRL_RTYPE_SRA = '{
        rf_write: 1'b1,
        result_src: RSLT_ALU,
        mem_write: 1'b0,
        jump: 1'b0,
        pc_target_src: PC_TARGET_PC_IMM,
        branch: 1'b0,
        alu_ctrl: CTRL_SRA,
        alu_src: BE_RDATA_E,
        btype: BEQ,
        load_type: LB,
        store_type: SB,
        csrtype: TRAP,
        csr_en: 1'b0,
        mret_en: 1'b0
    };

    localparam control_bundle_t CTRL_RTYPE_OR = '{
        rf_write: 1'b1,
        result_src: RSLT_ALU,
        mem_write: 1'b0,
        jump: 1'b0,
        pc_target_src: PC_TARGET_PC_IMM,
        branch: 1'b0,
        alu_ctrl: CTRL_OR,
        alu_src: BE_RDATA_E,
        btype: BEQ,
        load_type: LB,
        store_type: SB,
        csrtype: TRAP,
        csr_en: 1'b0,
        mret_en: 1'b0
    };

    localparam control_bundle_t CTRL_RTYPE_AND = '{
        rf_write: 1'b1,
        result_src: RSLT_ALU,
        mem_write: 1'b0,
        jump: 1'b0,
        pc_target_src: PC_TARGET_PC_IMM,
        branch: 1'b0,
        alu_ctrl: CTRL_AND,
        alu_src: BE_RDATA_E,
        btype: BEQ,
        load_type: LB,
        store_type: SB,
        csrtype: TRAP,
        csr_en: 1'b0,
        mret_en: 1'b0
    };

    localparam control_bundle_t CTRL_ITYPE_SLTI = '{
        rf_write: 1'b1,
        result_src: RSLT_ALU,
        mem_write: 1'b0,
        jump: 1'b0,
        pc_target_src: PC_TARGET_PC_IMM,
        branch: 1'b0,
        alu_ctrl: CTRL_SLT,
        alu_src: BE_IMM_E,
        btype: BEQ,
        load_type: LB,
        store_type: SB,
        csrtype: TRAP,
        csr_en: 1'b0,
        mret_en: 1'b0
    };

    localparam control_bundle_t CTRL_ITYPE_SLTIU = '{
        rf_write: 1'b1,
        result_src: RSLT_ALU,
        mem_write: 1'b0,
        jump: 1'b0,
        pc_target_src: PC_TARGET_PC_IMM,
        branch: 1'b0,
        alu_ctrl: CTRL_SLTU,
        alu_src: BE_IMM_E,
        btype: BEQ,
        load_type: LB,
        store_type: SB,
        csrtype: TRAP,
        csr_en: 1'b0,
        mret_en: 1'b0
    };

    localparam control_bundle_t CTRL_ITYPE_XORI = '{
        rf_write: 1'b1,
        result_src: RSLT_ALU,
        mem_write: 1'b0,
        jump: 1'b0,
        pc_target_src: PC_TARGET_PC_IMM,
        branch: 1'b0,
        alu_ctrl: CTRL_XOR,
        alu_src: BE_IMM_E,
        btype: BEQ,
        load_type: LB,
        store_type: SB,
        csrtype: TRAP,
        csr_en: 1'b0,
        mret_en: 1'b0
    };

    localparam control_bundle_t CTRL_ITYPE_ORI = '{
        rf_write: 1'b1,
        result_src: RSLT_ALU,
        mem_write: 1'b0,
        jump: 1'b0,
        pc_target_src: PC_TARGET_PC_IMM,
        branch: 1'b0,
        alu_ctrl: CTRL_OR,
        alu_src: BE_IMM_E,
        btype: BEQ,
        load_type: LB,
        store_type: SB,
        csrtype: TRAP,
        csr_en: 1'b0,
        mret_en: 1'b0
    };

    localparam control_bundle_t CTRL_ITYPE_ANDI = '{
        rf_write: 1'b1,
        result_src: RSLT_ALU,
        mem_write: 1'b0,
        jump: 1'b0,
        pc_target_src: PC_TARGET_PC_IMM,
        branch: 1'b0,
        alu_ctrl: CTRL_AND,
        alu_src: BE_IMM_E,
        btype: BEQ,
        load_type: LB,
        store_type: SB,
        csrtype: TRAP,
        csr_en: 1'b0,
        mret_en: 1'b0
    };

    localparam control_bundle_t CTRL_ITYPE_SLLI = '{
        rf_write: 1'b1,
        result_src: RSLT_ALU,
        mem_write: 1'b0,
        jump: 1'b0,
        pc_target_src: PC_TARGET_PC_IMM,
        branch: 1'b0,
        alu_ctrl: CTRL_SLL,
        alu_src: BE_IMM_E,
        btype: BEQ,
        load_type: LB,
        store_type: SB,
        csrtype: TRAP,
        csr_en: 1'b0,
        mret_en: 1'b0
    };

    localparam control_bundle_t CTRL_ITYPE_SRLI = '{
        rf_write: 1'b1,
        result_src: RSLT_ALU,
        mem_write: 1'b0,
        jump: 1'b0,
        pc_target_src: PC_TARGET_PC_IMM,
        branch: 1'b0,
        alu_ctrl: CTRL_SRL,
        alu_src: BE_IMM_E,
        btype: BEQ,
        load_type: LB,
        store_type: SB,
        csrtype: TRAP,
        csr_en: 1'b0,
        mret_en: 1'b0
    };

    localparam control_bundle_t CTRL_ITYPE_SRAI = '{
        rf_write: 1'b1,
        result_src: RSLT_ALU,
        mem_write: 1'b0,
        jump: 1'b0,
        pc_target_src: PC_TARGET_PC_IMM,
        branch: 1'b0,
        alu_ctrl: CTRL_SRA,
        alu_src: BE_IMM_E,
        btype: BEQ,
        load_type: LB,
        store_type: SB,
        csrtype: TRAP,
        csr_en: 1'b0,
        mret_en: 1'b0
    };

    localparam control_bundle_t CTRL_BTYPE_BNE = '{
        rf_write: 1'b0,
        result_src: RSLT_ALU,
        mem_write: 1'b0,
        jump: 1'b0,
        pc_target_src: PC_TARGET_PC_IMM,
        branch: 1'b1,
        alu_ctrl: CTRL_SUB,
        alu_src: BE_RDATA_E,
        btype: BNE,
        load_type: LB,
        store_type: SB,
        csrtype: TRAP,
        csr_en: 1'b0,
        mret_en: 1'b0
    };

    localparam control_bundle_t CTRL_BTYPE_BLT = '{
        rf_write: 1'b0,
        result_src: RSLT_ALU,
        mem_write: 1'b0,
        jump: 1'b0,
        pc_target_src: PC_TARGET_PC_IMM,
        branch: 1'b1,
        alu_ctrl: CTRL_SUB,
        alu_src: BE_RDATA_E,
        btype: BLT,
        load_type: LB,
        store_type: SB,
        csrtype: TRAP,
        csr_en: 1'b0,
        mret_en: 1'b0
    };

    localparam control_bundle_t CTRL_BTYPE_BGE = '{
        rf_write: 1'b0,
        result_src: RSLT_ALU,
        mem_write: 1'b0,
        jump: 1'b0,
        pc_target_src: PC_TARGET_PC_IMM,
        branch: 1'b1,
        alu_ctrl: CTRL_SUB,
        alu_src: BE_RDATA_E,
        btype: BGE,
        load_type: LB,
        store_type: SB,
        csrtype: TRAP,
        csr_en: 1'b0,
        mret_en: 1'b0
    };

    localparam control_bundle_t CTRL_BTYPE_BLTU = '{
        rf_write: 1'b0,
        result_src: RSLT_ALU,
        mem_write: 1'b0,
        jump: 1'b0,
        pc_target_src: PC_TARGET_PC_IMM,
        branch: 1'b1,
        alu_ctrl: CTRL_SUB,
        alu_src: BE_RDATA_E,
        btype: BLTU,
        load_type: LB,
        store_type: SB,
        csrtype: TRAP,
        csr_en: 1'b0,
        mret_en: 1'b0
    };

    localparam control_bundle_t CTRL_BTYPE_BGEU = '{
        rf_write: 1'b0,
        result_src: RSLT_ALU,
        mem_write: 1'b0,
        jump: 1'b0,
        pc_target_src: PC_TARGET_PC_IMM,
        branch: 1'b1,
        alu_ctrl: CTRL_SUB,
        alu_src: BE_RDATA_E,
        btype: BGEU,
        load_type: LB,
        store_type: SB,
        csrtype: TRAP,
        csr_en: 1'b0,
        mret_en: 1'b0
    };

    control_unit dut(
        .instr_D(instr_D),
        .imm_src_D(imm_src_D),
        .trap_event_illegal_instr_D(trap_event_illegal_instr_D),
        .ctrl_D(ctrl_D)
    );

    // -------------------------- FUNCTION TESTS -------------------------
    initial begin
        test_no_instr();
        test_addi_instr();
        test_jalr_instr();
        test_add_instr();
        test_sub_instr();
        test_sll_instr();
        test_slt_instr();
        test_sltu_instr();
        test_xor_instr();
        test_srl_instr();
        test_sra_instr();
        test_or_instr();
        test_and_instr();
        test_beq_instr();
        test_lui_instr();
        test_auipc_instr();
        test_jal_instr();
        test_sw_instr();
        test_slti_instr();
        test_sltiu_instr();
        test_xori_instr();
        test_ori_instr();
        test_andi_instr();
        test_slli_instr();
        test_srli_instr();
        test_srai_instr();
        test_bne_instr();
        test_blt_instr();
        test_bge_instr();
        test_bltu_instr();
        test_bgeu_instr();
        test_lb_instr();
        test_lh_instr();
        test_lw_instr();
        test_lbu_instr();
        test_lhu_instr();
        test_sb_instr();
        test_sh_instr();
        test_unsupported_rtype_funct7();
        test_unsupported_shift_imm_funct7();
        test_unsupported_jalr_funct3();
        test_unsupported_load_funct3();
        test_addi_negative_imm_decode();
        test_ecall_instr();
        test_ebreak_instr();
        test_mret_instr();
        test_malformed_mret_instr();
        test_csrrw_instr();
        test_csrrs_instr();
        test_csrrc_instr();
        test_csrrwi_instr();
        test_csrrsi_instr();
        test_csrrci_instr();
        test_unsupported_csr_funct3();

        $display("CONTROL_UNIT PASS: all tests completed");
        $finish;
    end

    // -------------------------- PORTS INITIAL --------------------------
    task automatic apply_instr_defaults();
        instr_D = 32'b0;
    endtask

    // ------------------------ FUNCTION CHECKS -------------------------
    task automatic test_no_instr();
        apply_instr_defaults();
        #1;

        check_ctrl_bundle("no control signals", CTRL_NOP);
        check_imm_src("no imm source", IMM_I);
        check_trap_event("zero instruction trap event", TRAP_EVENT_ILLEGAL_INSTR);
    endtask

    task automatic test_addi_instr();
        apply_instr_defaults();
        
        instr_D = 32'h00A10093; // addi x1, x2, 10
        #1;

        check_ctrl_bundle("I-Type-IMM control bundle", CTRL_ITYPE_IMM);
        check_imm_src("I mode imm", IMM_I);
        check_trap_event("ADDI trap event", TRAP_EVENT_NONE);
    endtask 

    task automatic test_lui_instr();
        apply_instr_defaults();

        instr_D = 32'h123450B7; // lui x1, 0x12345
        #1;

        check_ctrl_bundle("U-Type control bundle", CTRL_UTYPE);
        check_imm_src("U mode imm", IMM_U);
    endtask 

    task automatic test_auipc_instr();
        apply_instr_defaults();

        instr_D = 32'h12345097; // auipc x1, 0x12345
        #1;

        check_ctrl_bundle("U-Type AUIPC control bundle", CTRL_UTYPE_AUIPC);
        check_imm_src("U mode imm", IMM_U);
    endtask

    task automatic test_add_instr();
        apply_instr_defaults();

        instr_D = 32'h003100B3; // add x1, x2, x3
        #1;

        check_ctrl_bundle("R-Type ADD control bundle", CTRL_RTYPE);
        check_imm_src("no imm source", IMM_I);
    endtask

    task automatic test_sub_instr();
        apply_instr_defaults();

        instr_D = 32'h403100B3; // sub x1, x2, x3
        #1;

        check_ctrl_bundle("R-Type SUB control bundle", CTRL_RTYPE_SUB);
        check_imm_src("no imm source", IMM_I);
    endtask

    task automatic test_sll_instr();
        apply_instr_defaults();

        instr_D = 32'h003110B3; // sll x1, x2, x3
        #1;

        check_ctrl_bundle("R-Type SLL control bundle", CTRL_RTYPE_SLL);
        check_imm_src("no imm source", IMM_I);
    endtask

    task automatic test_slt_instr();
        apply_instr_defaults();

        instr_D = 32'h003120B3; // slt x1, x2, x3
        #1;

        check_ctrl_bundle("R-Type SLT control bundle", CTRL_RTYPE_SLT);
        check_imm_src("no imm source", IMM_I);
    endtask

    task automatic test_sltu_instr();
        apply_instr_defaults();

        instr_D = 32'h003130B3; // sltu x1, x2, x3
        #1;

        check_ctrl_bundle("R-Type SLTU control bundle", CTRL_RTYPE_SLTU);
        check_imm_src("no imm source", IMM_I);
    endtask

    task automatic test_xor_instr();
        apply_instr_defaults();

        instr_D = 32'h003140B3; // xor x1, x2, x3
        #1;

        check_ctrl_bundle("R-Type XOR control bundle", CTRL_RTYPE_XOR);
        check_imm_src("no imm source", IMM_I);
    endtask

    task automatic test_srl_instr();
        apply_instr_defaults();

        instr_D = 32'h003150B3; // srl x1, x2, x3
        #1;

        check_ctrl_bundle("R-Type SRL control bundle", CTRL_RTYPE_SRL);
        check_imm_src("no imm source", IMM_I);
    endtask

    task automatic test_sra_instr();
        apply_instr_defaults();

        instr_D = 32'h403150B3; // sra x1, x2, x3
        #1;

        check_ctrl_bundle("R-Type SRA control bundle", CTRL_RTYPE_SRA);
        check_imm_src("no imm source", IMM_I);
    endtask

    task automatic test_or_instr();
        apply_instr_defaults();

        instr_D = 32'h003160B3; // or x1, x2, x3
        #1;

        check_ctrl_bundle("R-Type OR control bundle", CTRL_RTYPE_OR);
        check_imm_src("no imm source", IMM_I);
    endtask

    task automatic test_and_instr();
        apply_instr_defaults();

        instr_D = 32'h003170B3; // and x1, x2, x3
        #1;

        check_ctrl_bundle("R-Type AND control bundle", CTRL_RTYPE_AND);
        check_imm_src("no imm source", IMM_I);
    endtask

    task automatic test_beq_instr();
        apply_instr_defaults();

        instr_D = 32'h00208863; // beq x1, x2, 16
        #1;

        check_ctrl_bundle("B-Type BEQ control bundle", CTRL_BTYPE);
        check_imm_src("B mode imm", IMM_B);
    endtask 

    task automatic test_bne_instr();
        apply_instr_defaults();

        instr_D = 32'h00209863; // bne x1, x2, 16
        #1;

        check_ctrl_bundle("B-Type BNE control bundle", CTRL_BTYPE_BNE);
        check_imm_src("B mode imm", IMM_B);
    endtask

    task automatic test_blt_instr();
        apply_instr_defaults();

        instr_D = 32'h0020C863; // blt x1, x2, 16
        #1;

        check_ctrl_bundle("B-Type BLT control bundle", CTRL_BTYPE_BLT);
        check_imm_src("B mode imm", IMM_B);
    endtask

    task automatic test_bge_instr();
        apply_instr_defaults();

        instr_D = 32'h0020D863; // bge x1, x2, 16
        #1;

        check_ctrl_bundle("B-Type BGE control bundle", CTRL_BTYPE_BGE);
        check_imm_src("B mode imm", IMM_B);
    endtask

    task automatic test_bltu_instr();
        apply_instr_defaults();

        instr_D = 32'h0020E863; // bltu x1, x2, 16
        #1;

        check_ctrl_bundle("B-Type BLTU control bundle", CTRL_BTYPE_BLTU);
        check_imm_src("B mode imm", IMM_B);
    endtask

    task automatic test_bgeu_instr();
        apply_instr_defaults();

        instr_D = 32'h0020F863; // bgeu x1, x2, 16
        #1;

        check_ctrl_bundle("B-Type BGEU control bundle", CTRL_BTYPE_BGEU);
        check_imm_src("B mode imm", IMM_B);
    endtask

    task automatic test_jal_instr();
        apply_instr_defaults();

        instr_D = 32'h0FA000EF; // jal x1, 2000
        #1;

        check_ctrl_bundle("J-Type JAL control bundle", CTRL_JTYPE);
        check_imm_src("J mode imm", IMM_J);
    endtask 

    task automatic test_lw_instr();
        control_bundle_t expected_ctrl;

        apply_instr_defaults();

        instr_D = 32'h00412083; // lw x1, 4(x2)
        expected_ctrl = CTRL_ITYPE_LOAD;
        expected_ctrl.load_type = LW;
        #1;

        check_ctrl_bundle("I-Type-Load LW control bundle", expected_ctrl);
        check_imm_src("I mode imm", IMM_I);
    endtask 

    task automatic test_lb_instr();
        control_bundle_t expected_ctrl;

        apply_instr_defaults();

        instr_D = 32'h00810083; // lb x1, 8(x2)
        expected_ctrl = CTRL_ITYPE_LOAD;
        expected_ctrl.load_type = LB;
        #1;

        check_ctrl_bundle("I-Type-Load LB control bundle", expected_ctrl);
        check_imm_src("I mode imm", IMM_I);
    endtask

    task automatic test_lh_instr();
        control_bundle_t expected_ctrl;

        apply_instr_defaults();

        instr_D = 32'h00811083; // lh x1, 8(x2)
        expected_ctrl = CTRL_ITYPE_LOAD;
        expected_ctrl.load_type = LH;
        #1;

        check_ctrl_bundle("I-Type-Load LH control bundle", expected_ctrl);
        check_imm_src("I mode imm", IMM_I);
    endtask

    task automatic test_lbu_instr();
        control_bundle_t expected_ctrl;

        apply_instr_defaults();

        instr_D = 32'h00814083; // lbu x1, 8(x2)
        expected_ctrl = CTRL_ITYPE_LOAD;
        expected_ctrl.load_type = LBU;
        #1;

        check_ctrl_bundle("I-Type-Load LBU control bundle", expected_ctrl);
        check_imm_src("I mode imm", IMM_I);
    endtask

    task automatic test_lhu_instr();
        control_bundle_t expected_ctrl;

        apply_instr_defaults();

        instr_D = 32'h00815083; // lhu x1, 8(x2)
        expected_ctrl = CTRL_ITYPE_LOAD;
        expected_ctrl.load_type = LHU;
        #1;

        check_ctrl_bundle("I-Type-Load LHU control bundle", expected_ctrl);
        check_imm_src("I mode imm", IMM_I);
    endtask

    task automatic test_sb_instr();
        control_bundle_t expected_ctrl;

        apply_instr_defaults();

        instr_D = 32'h00310423; // sb x3, 8(x2)
        expected_ctrl = CTRL_STYPE;
        expected_ctrl.store_type = SB;
        #1;

        check_ctrl_bundle("S-Type SB control bundle", expected_ctrl);
        check_imm_src("S mode imm", IMM_S);
    endtask

    task automatic test_sh_instr();
        control_bundle_t expected_ctrl;

        apply_instr_defaults();

        instr_D = 32'h00311423; // sh x3, 8(x2)
        expected_ctrl = CTRL_STYPE;
        expected_ctrl.store_type = SH;
        #1;

        check_ctrl_bundle("S-Type SH control bundle", expected_ctrl);
        check_imm_src("S mode imm", IMM_S);
    endtask

    task automatic test_sw_instr();
        control_bundle_t expected_ctrl;

        apply_instr_defaults();

        instr_D = 32'h00312423; // sw x3, 8(x2)
        expected_ctrl = CTRL_STYPE;
        #1;

        check_ctrl_bundle("S-Type control bundle", CTRL_STYPE);
        check_imm_src("S mode imm", IMM_S);
    endtask 

    task automatic test_jalr_instr();
        apply_instr_defaults();

        instr_D = 32'h000100E7; // jalr x1, 0(x2)
        #1;

        check_ctrl_bundle("I-Type JALR control bundle", CTRL_ITYPE_JALR);
        check_imm_src("I mode imm", IMM_I);
    endtask 

    task automatic test_slti_instr();
        apply_instr_defaults();

        instr_D = 32'hFFF12093; // slti x1, x2, -1
        #1;

        check_ctrl_bundle("I-Type SLTI control bundle", CTRL_ITYPE_SLTI);
        check_imm_src("I mode imm", IMM_I);
    endtask

    task automatic test_sltiu_instr();
        apply_instr_defaults();

        instr_D = 32'hFFF13093; // sltiu x1, x2, -1
        #1;

        check_ctrl_bundle("I-Type SLTIU control bundle", CTRL_ITYPE_SLTIU);
        check_imm_src("I mode imm", IMM_I);
    endtask

    task automatic test_xori_instr();
        apply_instr_defaults();

        instr_D = 32'h00A14093; // xori x1, x2, 10
        #1;

        check_ctrl_bundle("I-Type XORI control bundle", CTRL_ITYPE_XORI);
        check_imm_src("I mode imm", IMM_I);
    endtask

    task automatic test_ori_instr();
        apply_instr_defaults();

        instr_D = 32'h00A16093; // ori x1, x2, 10
        #1;

        check_ctrl_bundle("I-Type ORI control bundle", CTRL_ITYPE_ORI);
        check_imm_src("I mode imm", IMM_I);
    endtask

    task automatic test_andi_instr();
        apply_instr_defaults();

        instr_D = 32'h00A17093; // andi x1, x2, 10
        #1;

        check_ctrl_bundle("I-Type ANDI control bundle", CTRL_ITYPE_ANDI);
        check_imm_src("I mode imm", IMM_I);
    endtask

    task automatic test_slli_instr();
        apply_instr_defaults();

        instr_D = 32'h00411093; // slli x1, x2, 4
        #1;

        check_ctrl_bundle("I-Type SLLI control bundle", CTRL_ITYPE_SLLI);
        check_imm_src("I mode imm", IMM_I);
    endtask

    task automatic test_srli_instr();
        apply_instr_defaults();

        instr_D = 32'h00415093; // srli x1, x2, 4
        #1;

        check_ctrl_bundle("I-Type SRLI control bundle", CTRL_ITYPE_SRLI);
        check_imm_src("I mode imm", IMM_I);
    endtask

    task automatic test_srai_instr();
        apply_instr_defaults();

        instr_D = 32'h40415093; // srai x1, x2, 4
        #1;

        check_ctrl_bundle("I-Type SRAI control bundle", CTRL_ITYPE_SRAI);
        check_imm_src("I mode imm", IMM_I);
    endtask

    // --------------------------- CORNER CASES ---------------------------
    task automatic test_unsupported_rtype_funct7();
        apply_instr_defaults();

        instr_D = 32'h023100B3; // R-type shape with funct7=0000001 is not implemented
        #1;

        check_ctrl_bundle("unsupported R-Type funct7", CTRL_NOP);
        check_imm_src("no imm source for unsupported R-Type", IMM_I);
        check_trap_event("unsupported R-Type trap event", TRAP_EVENT_ILLEGAL_INSTR);
    endtask

    task automatic test_unsupported_shift_imm_funct7();
        // Besides slli, srli, srai
        apply_instr_defaults();

        instr_D = 32'h20111093; // OP-IMM shift shape with reserved funct7=0010000
        #1;

        check_ctrl_bundle("unsupported shift-immediate funct7", CTRL_NOP);
        check_imm_src("no imm source for unsupported shift-immediate", IMM_I);
        check_trap_event("unsupported shift-immediate trap event", TRAP_EVENT_ILLEGAL_INSTR);
    endtask

    task automatic test_unsupported_jalr_funct3();
        apply_instr_defaults();

        instr_D = 32'h000110E7; // opcode JALR shape, but funct3=001 is not a valid jalr
        #1;

        check_ctrl_bundle("unsupported JALR funct3", CTRL_NOP);
        check_imm_src("no imm source for unsupported JALR", IMM_I);
        check_trap_event("unsupported JALR trap event", TRAP_EVENT_ILLEGAL_INSTR);
    endtask

    task automatic test_unsupported_load_funct3();
        apply_instr_defaults();

        instr_D = 32'h00003083; // LOAD opcode with reserved funct3=011
        #1;

        check_ctrl_bundle("unsupported load funct3", CTRL_NOP);
        check_imm_src("unsupported load imm source", IMM_I);
        check_trap_event("unsupported load trap event", TRAP_EVENT_ILLEGAL_INSTR);
    endtask

    task automatic test_addi_negative_imm_decode();
        apply_instr_defaults();

        instr_D = 32'hFF900113; // addi x2, x0, -7
        #1;

        check_ctrl_bundle("negative imm addi", CTRL_ITYPE_IMM);
        check_imm_src("I mode imm", IMM_I);
    endtask 

    // ------------------------ SYSTEM / CSR TESTS ------------------------
    task automatic test_ecall_instr();
        control_bundle_t expected_ctrl;

        apply_instr_defaults();

        instr_D = 32'h00000073; // ecall
        expected_ctrl = CTRL_NOP;
        expected_ctrl.csr_en = 1'b1;
        #1;

        check_ctrl_bundle("ECALL control bundle", expected_ctrl);
        check_imm_src("ECALL imm source", IMM_I);
        check_trap_event("ECALL trap event", TRAP_EVENT_ENV_CALL_M_MODE);
    endtask

    task automatic test_ebreak_instr();
        control_bundle_t expected_ctrl;

        apply_instr_defaults();

        instr_D = 32'h00100073; // ebreak
        expected_ctrl = CTRL_NOP;
        expected_ctrl.csr_en = 1'b1;
        #1;

        check_ctrl_bundle("EBREAK control bundle", expected_ctrl);
        check_imm_src("EBREAK imm source", IMM_I);
        check_trap_event("EBREAK trap event", TRAP_EVENT_BREAKPOINT);
    endtask

    task automatic test_mret_instr();
        control_bundle_t expected_ctrl;

        apply_instr_defaults();

        instr_D = 32'h30200073; // mret
        expected_ctrl = CTRL_NOP;
        expected_ctrl.csr_en = 1'b1;
        expected_ctrl.mret_en = 1'b1;
        #1;

        check_ctrl_bundle("MRET control bundle", expected_ctrl);
        check_imm_src("MRET imm source", IMM_I);
        check_trap_event("MRET trap event", TRAP_EVENT_NONE);
    endtask

    task automatic test_malformed_mret_instr();
        control_bundle_t expected_ctrl;

        apply_instr_defaults();

        instr_D = 32'h302000f3; // MRET encoding with rd=x1 is illegal
        expected_ctrl = CTRL_NOP;
        expected_ctrl.csr_en = 1'b1;
        #1;

        check_ctrl_bundle("malformed MRET control bundle", expected_ctrl);
        check_imm_src("malformed MRET imm source", IMM_I);
        check_trap_event("malformed MRET trap event", TRAP_EVENT_ILLEGAL_INSTR);
    endtask

    task automatic test_csrrw_instr();
        control_bundle_t expected_ctrl;

        apply_instr_defaults();
        instr_D = 32'h305110F3; // csrrw x1, mtvec, x2
        expected_ctrl = CTRL_NOP;
        expected_ctrl.rf_write = 1'b1;
        expected_ctrl.result_src = RSLT_CSR_RDATA;
        expected_ctrl.csrtype = CSRRW;
        expected_ctrl.csr_en = 1'b1;
        #1;

        check_ctrl_bundle("CSRRW control bundle", expected_ctrl);
        check_imm_src("CSRRW imm source", IMM_I);
        check_trap_event("CSRRW trap event", TRAP_EVENT_NONE);
    endtask

    task automatic test_csrrs_instr();
        control_bundle_t expected_ctrl;

        apply_instr_defaults();
        instr_D = 32'h305120F3; // csrrs x1, mtvec, x2
        expected_ctrl = CTRL_NOP;
        expected_ctrl.rf_write = 1'b1;
        expected_ctrl.result_src = RSLT_CSR_RDATA;
        expected_ctrl.csrtype = CSRRS;
        expected_ctrl.csr_en = 1'b1;
        #1;

        check_ctrl_bundle("CSRRS control bundle", expected_ctrl);
        check_imm_src("CSRRS imm source", IMM_I);
        check_trap_event("CSRRS trap event", TRAP_EVENT_NONE);
    endtask

    task automatic test_csrrc_instr();
        control_bundle_t expected_ctrl;

        apply_instr_defaults();
        instr_D = 32'h305130F3; // csrrc x1, mtvec, x2
        expected_ctrl = CTRL_NOP;
        expected_ctrl.rf_write = 1'b1;
        expected_ctrl.result_src = RSLT_CSR_RDATA;
        expected_ctrl.csrtype = CSRRC;
        expected_ctrl.csr_en = 1'b1;
        #1;

        check_ctrl_bundle("CSRRC control bundle", expected_ctrl);
        check_imm_src("CSRRC imm source", IMM_I);
        check_trap_event("CSRRC trap event", TRAP_EVENT_NONE);
    endtask

    task automatic test_csrrwi_instr();
        control_bundle_t expected_ctrl;

        apply_instr_defaults();
        instr_D = 32'h305150F3; // csrrwi x1, mtvec, 2
        expected_ctrl = CTRL_NOP;
        expected_ctrl.rf_write = 1'b1;
        expected_ctrl.result_src = RSLT_CSR_RDATA;
        expected_ctrl.csrtype = CSRRWI;
        expected_ctrl.csr_en = 1'b1;
        #1;

        check_ctrl_bundle("CSRRWI control bundle", expected_ctrl);
        check_imm_src("CSRRWI imm source", IMM_CSR);
        check_trap_event("CSRRWI trap event", TRAP_EVENT_NONE);
    endtask

    task automatic test_csrrsi_instr();
        control_bundle_t expected_ctrl;

        apply_instr_defaults();
        instr_D = 32'h305160F3; // csrrsi x1, mtvec, 2
        expected_ctrl = CTRL_NOP;
        expected_ctrl.rf_write = 1'b1;
        expected_ctrl.result_src = RSLT_CSR_RDATA;
        expected_ctrl.csrtype = CSRRSI;
        expected_ctrl.csr_en = 1'b1;
        #1;

        check_ctrl_bundle("CSRRSI control bundle", expected_ctrl);
        check_imm_src("CSRRSI imm source", IMM_CSR);
        check_trap_event("CSRRSI trap event", TRAP_EVENT_NONE);
    endtask

    task automatic test_csrrci_instr();
        control_bundle_t expected_ctrl;

        apply_instr_defaults();
        instr_D = 32'h305170F3; // csrrci x1, mtvec, 2
        expected_ctrl = CTRL_NOP;
        expected_ctrl.rf_write = 1'b1;
        expected_ctrl.result_src = RSLT_CSR_RDATA;
        expected_ctrl.csrtype = CSRRCI;
        expected_ctrl.csr_en = 1'b1;
        #1;

        check_ctrl_bundle("CSRRCI control bundle", expected_ctrl);
        check_imm_src("CSRRCI imm source", IMM_CSR);
        check_trap_event("CSRRCI trap event", TRAP_EVENT_NONE);
    endtask

    task automatic test_unsupported_csr_funct3();
        control_bundle_t expected_ctrl;

        apply_instr_defaults();

        instr_D = 32'h305140F3; // SYSTEM opcode with reserved funct3=100
        expected_ctrl = CTRL_NOP;
        expected_ctrl.csr_en = 1'b1;
        #1;

        check_ctrl_bundle("unsupported CSR funct3", expected_ctrl);
        check_imm_src("unsupported CSR imm source", IMM_I);
        check_trap_event("unsupported CSR trap event", TRAP_EVENT_ILLEGAL_INSTR);
    endtask

    // --------------------------- CHECK TASKS ---------------------------
    task automatic check_ctrl_bundle(
        input string name,
        input control_bundle_t expected_ctrl_bundle
    );
        if (ctrl_D.rf_write !== expected_ctrl_bundle.rf_write) begin
            $fatal(1, "%s: rf_write expected %0b, got %0b",
                   name, expected_ctrl_bundle.rf_write, ctrl_D.rf_write);
        end

        if (ctrl_D.result_src !== expected_ctrl_bundle.result_src) begin
            $fatal(1, "%s: result_src expected %0b, got %0b",
                   name, expected_ctrl_bundle.result_src, ctrl_D.result_src);
        end

        if (ctrl_D.mem_write !== expected_ctrl_bundle.mem_write) begin
            $fatal(1, "%s: mem_write expected %0b, got %0b",
                   name, expected_ctrl_bundle.mem_write, ctrl_D.mem_write);
        end

        if (ctrl_D.jump !== expected_ctrl_bundle.jump) begin
            $fatal(1, "%s: jump expected %0b, got %0b",
                   name, expected_ctrl_bundle.jump, ctrl_D.jump);
        end

        if (ctrl_D.pc_target_src !== expected_ctrl_bundle.pc_target_src) begin
            $fatal(1, "%s: pc_target_src expected %0b, got %0b",
                   name, expected_ctrl_bundle.pc_target_src, ctrl_D.pc_target_src);
        end

        if (ctrl_D.branch !== expected_ctrl_bundle.branch) begin
            $fatal(1, "%s: branch expected %0b, got %0b",
                   name, expected_ctrl_bundle.branch, ctrl_D.branch);
        end

        if (ctrl_D.alu_ctrl !== expected_ctrl_bundle.alu_ctrl) begin
            $fatal(1, "%s: alu_ctrl expected %0b, got %0b",
                   name, expected_ctrl_bundle.alu_ctrl, ctrl_D.alu_ctrl);
        end

        if (ctrl_D.alu_src !== expected_ctrl_bundle.alu_src) begin
            $fatal(1, "%s: alu_src expected %0b, got %0b",
                   name, expected_ctrl_bundle.alu_src, ctrl_D.alu_src);
        end

        if (ctrl_D.btype !== expected_ctrl_bundle.btype) begin
            $fatal(1, "%s: btype expected %0b, got %0b",
                   name, expected_ctrl_bundle.btype, ctrl_D.btype);
        end

        if (ctrl_D.load_type !== expected_ctrl_bundle.load_type) begin
            $fatal(1, "%s: load_type expected %0b, got %0b",
                   name, expected_ctrl_bundle.load_type, ctrl_D.load_type);
        end

        if (ctrl_D.store_type !== expected_ctrl_bundle.store_type) begin
            $fatal(1, "%s: store_type expected %0b, got %0b",
                   name, expected_ctrl_bundle.store_type, ctrl_D.store_type);
        end

        if (ctrl_D.csrtype !== expected_ctrl_bundle.csrtype) begin
            $fatal(1, "%s: csrtype expected %0b, got %0b",
                   name, expected_ctrl_bundle.csrtype, ctrl_D.csrtype);
        end

        if (ctrl_D.csr_en !== expected_ctrl_bundle.csr_en) begin
            $fatal(1, "%s: csr_en expected %0b, got %0b",
                   name, expected_ctrl_bundle.csr_en, ctrl_D.csr_en);
        end

        if (ctrl_D.mret_en !== expected_ctrl_bundle.mret_en) begin
            $fatal(1, "%s: mret_en expected %0b, got %0b",
                   name, expected_ctrl_bundle.mret_en, ctrl_D.mret_en);
        end
    endtask 

    task automatic check_imm_src(
        input string name,
        input imm_src_e expected_imm_src
    );
        if (imm_src_D !== expected_imm_src) begin
            $fatal(1, "%s: imm_src expected %0b, got %0b",
                   name, expected_imm_src, imm_src_D);
        end
    endtask 

    task automatic check_trap_event(
        input string name,
        input trap_event_e expected_trap_event
    );
        if (trap_event_illegal_instr_D !== expected_trap_event) begin
            $fatal(1, "%s: trap event expected %0b, got %0b",
                   name, expected_trap_event, trap_event_illegal_instr_D);
        end
    endtask

endmodule
