`timescale 1ps/1ps

module control_unit_tb 
    import core_types_pkg::*;
;
    
    logic [WORD_WIDTH - 1:0] instr_D;

    imm_src_e imm_src_D;
    control_bundle_t ctrl_D;

    localparam control_bundle_t CTRL_NOP = '{
        rf_write: 1'b0,
        result_src: RSLT_ALU,
        mem_write: 1'b0,
        jump: 1'b0,
        pc_target_src: PC_TARGET_PC_IMM,
        branch: 1'b0,
        alu_ctrl: CTRL_ADD,
        alu_src: BE_RDATA_E
    };

    localparam control_bundle_t CTRL_ITYPE_IMM = '{
        rf_write: 1'b1,
        result_src: RSLT_ALU,
        mem_write: 1'b0,
        jump: 1'b0,
        pc_target_src: PC_TARGET_PC_IMM,
        branch: 1'b0,
        alu_ctrl: CTRL_ADD,
        alu_src: BE_IMM_E
    };

    localparam control_bundle_t CTRL_UTYPE = '{
        rf_write: 1'b1,
        result_src: RSLT_ALU,
        mem_write: 1'b0,
        jump: 1'b0,
        pc_target_src: PC_TARGET_PC_IMM,
        branch: 1'b0,
        alu_ctrl: CTRL_PASS_B,
        alu_src: BE_IMM_E
    };

    localparam control_bundle_t CTRL_STYPE = '{
        rf_write: 1'b0,
        result_src: RSLT_ALU,
        mem_write: 1'b1,
        jump: 1'b0,
        pc_target_src: PC_TARGET_PC_IMM,
        branch: 1'b0,
        alu_ctrl: CTRL_ADD,
        alu_src: BE_IMM_E
    };

    localparam control_bundle_t CTRL_RTYPE = '{
        rf_write: 1'b1,
        result_src: RSLT_ALU,
        mem_write: 1'b0,
        jump: 1'b0,
        pc_target_src: PC_TARGET_PC_IMM,
        branch: 1'b0,
        alu_ctrl: CTRL_ADD,
        alu_src: BE_RDATA_E
    };

    localparam control_bundle_t CTRL_BTYPE = '{
        rf_write: 1'b0,
        result_src: RSLT_ALU,
        mem_write: 1'b0,
        jump: 1'b0,
        pc_target_src: PC_TARGET_PC_IMM,
        branch: 1'b1,
        alu_ctrl: CTRL_SUB,
        alu_src: BE_RDATA_E
    };

    localparam control_bundle_t CTRL_JTYPE = '{
        rf_write: 1'b1,
        result_src: RSLT_PCPLUS4,
        mem_write: 1'b0,
        jump: 1'b1,
        pc_target_src: PC_TARGET_PC_IMM,
        branch: 1'b0,
        alu_ctrl: CTRL_ADD,
        alu_src: BE_RDATA_E
    };

    localparam control_bundle_t CTRL_ITYPE_LOAD = '{
        rf_write: 1'b1,
        result_src: RSLT_RDATA,
        mem_write: 1'b0,
        jump: 1'b0,
        pc_target_src: PC_TARGET_PC_IMM,
        branch: 1'b0,
        alu_ctrl: CTRL_ADD,
        alu_src: BE_IMM_E
    };

    localparam control_bundle_t CTRL_ITYPE_JALR = '{
        rf_write: 1'b1,
        result_src: RSLT_PCPLUS4,
        mem_write: 1'b0,
        jump: 1'b1,
        pc_target_src: PC_TARGET_RS1_IMM,
        branch: 1'b0,
        alu_ctrl: CTRL_ADD,
        alu_src: BE_IMM_E
    };

    control_unit dut(
        .instr_D(instr_D),
        .imm_src_D(imm_src_D),
        .ctrl_D(ctrl_D)
    );

    // -------------------------- FUNCTION TESTS -------------------------
    initial begin
        test_no_instr();
        test_itype_imm();
        test_itype_load();
        test_itype_jalr();
        test_rtype();
        test_btype();
        test_utype();
        test_jtype();
        test_stype();
        test_rtype_alu_variants();
        test_unsupported_bne();
        test_unsupported_lb();
        test_unsupported_sb();
        test_unsupported_ori();
        test_unsupported_rtype_funct7();
        test_unsupported_jalr_funct3();
        test_addi_negative_imm_decode();

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
    endtask

    task automatic test_itype_imm();
        apply_instr_defaults();
        
        instr_D = 32'h00A10093; // addi x1, x2, 10
        #1;

        check_ctrl_bundle("I-Type-IMM control bundle", CTRL_ITYPE_IMM);
        check_imm_src("I mode imm", IMM_I);
    endtask 

    task automatic test_utype();
        apply_instr_defaults();

        instr_D = 32'h123450B7; // lui x1, 0x12345
        #1;

        check_ctrl_bundle("U-Type control bundle", CTRL_UTYPE);
        check_imm_src("U mode imm", IMM_U);
    endtask 

    task automatic test_stype();
        apply_instr_defaults();

        instr_D = 32'h00312423; // sw x3, 8(x2)
        #1;

        check_ctrl_bundle("S-Type control bundle", CTRL_STYPE);
        check_imm_src("S mode imm", IMM_S);
    endtask 

    task automatic test_rtype();
        apply_instr_defaults();

        instr_D = 32'h003100B3; // add x1, x2, x3
        #1;

        check_ctrl_bundle("R-Type control bundle", CTRL_RTYPE);
        check_imm_src("no imm source", IMM_I);
    endtask 

    // Specific test for verifying different alu_ctrl signals in R-Type instructions
    task automatic test_rtype_alu_variants();
        check_rtype_alu("R-Type ADD control bundle", 32'h003100B3, CTRL_ADD); // add x1, x2, x3
        check_rtype_alu("R-Type SUB control bundle", 32'h403100B3, CTRL_SUB); // sub x1, x2, x3
        check_rtype_alu("R-Type SLL control bundle", 32'h003110B3, CTRL_SLL); // sll x1, x2, x3
        check_rtype_alu("R-Type SLT control bundle", 32'h003120B3, CTRL_SLT); // slt x1, x2, x3
        check_rtype_alu("R-Type SLTU control bundle", 32'h003130B3, CTRL_SLTU); // sltu x1, x2, x3
        check_rtype_alu("R-Type XOR control bundle", 32'h003140B3, CTRL_XOR); // xor x1, x2, x3
        check_rtype_alu("R-Type SRL control bundle", 32'h003150B3, CTRL_SRL); // srl x1, x2, x3
        check_rtype_alu("R-Type SRA control bundle", 32'h403150B3, CTRL_SRA); // sra x1, x2, x3
        check_rtype_alu("R-Type OR control bundle", 32'h003160B3, CTRL_OR); // or x1, x2, x3
        check_rtype_alu("R-Type AND control bundle", 32'h003170B3, CTRL_AND); // and x1, x2, x3
    endtask

    task automatic test_btype();
        apply_instr_defaults();

        instr_D = 32'h00208863; // beq x1, x2, 16
        #1;

        check_ctrl_bundle("B-Type control bundle", CTRL_BTYPE);
        check_imm_src("B mode imm", IMM_B);
    endtask 

    task automatic test_jtype();
        apply_instr_defaults();

        instr_D = 32'h0FA000EF; // jal x1, 2000
        #1;

        check_ctrl_bundle("J-Type control bundle", CTRL_JTYPE);
        check_imm_src("J mode imm", IMM_J);
    endtask 

    task automatic test_itype_load();
        apply_instr_defaults();

        instr_D = 32'h00412083; // lw x1, 4(x2)
        #1;

        check_ctrl_bundle("I-Type-Load control bundle", CTRL_ITYPE_LOAD);
        check_imm_src("I mode imm", IMM_I);
    endtask 

    task automatic test_itype_jalr();
        apply_instr_defaults();

        instr_D = 32'h000100E7; // jalr x1, 0(x2)
        #1;

        check_ctrl_bundle("I-Type-JALR control bundle", CTRL_ITYPE_JALR);
        check_imm_src("I mode imm", IMM_I);
    endtask 
    
    // --------------------------- CORNER CASES ---------------------------
    task automatic test_unsupported_bne();
        apply_instr_defaults();

        instr_D = 32'h00209863; // bne x1, x2, 16
        #1;

        check_ctrl_bundle("unsupported instruction BNE", CTRL_NOP);
        check_imm_src("no imm source for BNE", IMM_I);
    endtask 

    task automatic test_unsupported_lb();
        apply_instr_defaults();

        instr_D = 32'h00810083; // lb x1, 8(x2)
        #1;

        check_ctrl_bundle("unsupported instruction LB", CTRL_NOP);
        check_imm_src("no imm source for LB", IMM_I);
    endtask 

    task automatic test_unsupported_sb();
        apply_instr_defaults();

        instr_D = 32'h00310423; // sb x3, 8(x2)
        #1;

        check_ctrl_bundle("unsupported instruction SB", CTRL_NOP);
        check_imm_src("no imm source for SB", IMM_I);
    endtask

    task automatic test_unsupported_ori();
        apply_instr_defaults();

        instr_D = 32'h00A16093; // ori x1, x2, 10
        #1;

        check_ctrl_bundle("unsupported instruction ORI", CTRL_NOP);
        check_imm_src("no imm source for ORI", IMM_I);
    endtask

    task automatic test_unsupported_rtype_funct7();
        apply_instr_defaults();

        instr_D = 32'h023100B3; // R-type shape with funct7=0000001 is not implemented
        #1;

        check_ctrl_bundle("unsupported R-Type funct7", CTRL_NOP);
        check_imm_src("no imm source for unsupported R-Type", IMM_I);
    endtask

    task automatic test_unsupported_jalr_funct3();
        apply_instr_defaults();

        instr_D = 32'h000110E7; // opcode JALR shape, but funct3=001 is not a valid jalr
        #1;

        check_ctrl_bundle("unsupported JALR funct3", CTRL_NOP);
        check_imm_src("no imm source for unsupported JALR", IMM_I);
    endtask

    task automatic test_addi_negative_imm_decode();
        apply_instr_defaults();

        instr_D = 32'hFF900113; // addi x2, x0, -7
        #1;

        check_ctrl_bundle("negative imm addi", CTRL_ITYPE_IMM);
        check_imm_src("I mode imm", IMM_I);
    endtask 

    // -------------------------- SPECIFIC CHECK --------------------------
    task automatic check_rtype_alu(
        input string name,
        input logic [WORD_WIDTH - 1:0] instr,
        input alu_ctrl_e expected_alu_ctrl
    );
        control_bundle_t expected_ctrl_bundle;

        apply_instr_defaults();
        expected_ctrl_bundle = CTRL_RTYPE;
        expected_ctrl_bundle.alu_ctrl = expected_alu_ctrl;

        instr_D = instr;
        #1;

        check_ctrl_bundle(name, expected_ctrl_bundle);
        check_imm_src("no imm source", IMM_I);
    endtask

    // --------------------------- CHECK TASKS ---------------------------
    task automatic check_ctrl_bundle(
        input string name,
        input control_bundle_t expected_ctrl_bundle
    );
        if (ctrl_D.rf_write !== expected_ctrl_bundle.rf_write) begin
            $error("%s: rf_write expected %0b, got %0b",
                    name, expected_ctrl_bundle.rf_write, ctrl_D.rf_write);
            $finish;
        end

        if (ctrl_D.result_src !== expected_ctrl_bundle.result_src) begin
            $error("%s: result_src expected %0b, got %0b",
                    name, expected_ctrl_bundle.result_src, ctrl_D.result_src);
            $finish;
        end

        if (ctrl_D.mem_write !== expected_ctrl_bundle.mem_write) begin
            $error("%s: mem_write expected %0b, got %0b",
                    name, expected_ctrl_bundle.mem_write, ctrl_D.mem_write);
            $finish;
        end

        if (ctrl_D.jump !== expected_ctrl_bundle.jump) begin
            $error("%s: jump expected %0b, got %0b",
                    name, expected_ctrl_bundle.jump, ctrl_D.jump);
            $finish;
        end

        if (ctrl_D.pc_target_src !== expected_ctrl_bundle.pc_target_src) begin
            $error("%s: pc_target_src expected %0b, got %0b",
                    name, expected_ctrl_bundle.pc_target_src, ctrl_D.pc_target_src);
            $finish;
        end

        if (ctrl_D.branch !== expected_ctrl_bundle.branch) begin
            $error("%s: branch expected %0b, got %0b",
                    name, expected_ctrl_bundle.branch, ctrl_D.branch);
            $finish;
        end

        if (ctrl_D.alu_ctrl !== expected_ctrl_bundle.alu_ctrl) begin
            $error("%s: alu_ctrl expected %0b, got %0b",
                    name, expected_ctrl_bundle.alu_ctrl, ctrl_D.alu_ctrl);
            $finish;
        end

        if (ctrl_D.alu_src !== expected_ctrl_bundle.alu_src) begin
            $error("%s: alu_src expected %0b, got %0b",
                    name, expected_ctrl_bundle.alu_src, ctrl_D.alu_src);
            $finish;
        end
    endtask 

    task automatic check_imm_src(
        input string name,
        input imm_src_e expected_imm_src
    );
        if (imm_src_D !== expected_imm_src) begin
            $error("%s: imm_src expected %0b, got %0b",
                    name, expected_imm_src, imm_src_D);
            $finish;
        end
    endtask 

endmodule
