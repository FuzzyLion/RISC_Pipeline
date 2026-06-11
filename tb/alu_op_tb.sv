`timescale 1ps/1ps

module alu_op_tb
    import core_types_pkg::*;
;

    alu_ctrl_e alu_control_E;
    btype_e btype_E;
    logic branch_E;

    logic [WORD_WIDTH - 1:0] alu_src_AE;
    logic [WORD_WIDTH - 1:0] alu_src_BE;
    logic [WORD_WIDTH - 1:0] pc_E;

    logic zero_E;
    logic [WORD_WIDTH - 1:0] alu_result_E;

    alu_op dut (
        .alu_control_E(alu_control_E),
        .btype_E(btype_E),
        .branch_E(branch_E),
        .alu_src_AE(alu_src_AE),
        .alu_src_BE(alu_src_BE),
        .pc_E(pc_E),
        .zero_E(zero_E),
        .alu_result_E(alu_result_E)
    );

    initial begin : test_sequence
        test_add_instr();
        test_add_overflow_instr();
        test_sub_negative_instr();
        test_sub_equal_instr();
        test_and_instr();
        test_or_instr();
        test_xor_instr();
        test_pass_b_instr();
        test_pass_b4pc_instr();
        test_slt_true_instr();
        test_slt_false_instr();
        test_sltu_false_instr();
        test_sltu_true_instr();
        test_sll_instr();
        test_sll_low_five_bits_instr();
        test_srl_instr();
        test_sra_instr();
        test_beq_taken_instr();
        test_beq_not_taken_instr();
        test_bne_taken_instr();
        test_bne_not_taken_instr();
        test_blt_taken_instr();
        test_blt_not_taken_instr();
        test_bge_taken_instr();
        test_bge_not_taken_instr();
        test_bltu_taken_instr();
        test_bltu_not_taken_instr();
        test_bgeu_taken_instr();
        test_bgeu_not_taken_instr();
        test_invalid_control();

        $display("ALU_OP PASS: all tests completed");
        $finish;
    end

    task automatic apply_alu_defaults();
        alu_control_E = CTRL_ADD;
        btype_E = BEQ;
        branch_E = 1'b0;
        alu_src_AE = 32'b0;
        alu_src_BE = 32'b0;
        pc_E = 32'b0;
    endtask

    task automatic test_beq_taken_instr();
        apply_alu_defaults();

        alu_control_E = CTRL_SUB;
        btype_E = BEQ;
        branch_E = 1'b1;
        alu_src_AE = 32'hffff_ffff;
        alu_src_BE = 32'hffff_ffff;
        #1;

        check_zero_E("BEQ taken", 1'b1, zero_E);
    endtask

    task automatic test_beq_not_taken_instr();
        apply_alu_defaults();

        alu_control_E = CTRL_SUB;
        btype_E = BEQ;
        branch_E = 1'b1;
        alu_src_AE = 32'd1;
        alu_src_BE = 32'd2;
        #1;

        check_zero_E("BEQ not taken", 1'b0, zero_E);
    endtask

    task automatic test_bne_taken_instr();
        apply_alu_defaults();

        alu_control_E = CTRL_SUB;
        btype_E = BNE;
        branch_E = 1'b1;
        alu_src_AE = 32'd1;
        alu_src_BE = 32'd2;
        #1;

        check_zero_E("BNE taken", 1'b1, zero_E);
    endtask

    task automatic test_bne_not_taken_instr();
        apply_alu_defaults();

        alu_control_E = CTRL_SUB;
        btype_E = BNE;
        branch_E = 1'b1;
        alu_src_AE = 32'd2;
        alu_src_BE = 32'd2;
        #1;

        check_zero_E("BNE not taken", 1'b0, zero_E);
    endtask

    task automatic test_blt_taken_instr();
        apply_alu_defaults();

        alu_control_E = CTRL_SUB;
        btype_E = BLT;
        branch_E = 1'b1;
        alu_src_AE = 32'hffff_ffff;
        alu_src_BE = 32'd1;
        #1;

        check_zero_E("BLT signed taken", 1'b1, zero_E);
    endtask

    task automatic test_blt_not_taken_instr();
        apply_alu_defaults();

        alu_control_E = CTRL_SUB;
        btype_E = BLT;
        branch_E = 1'b1;
        alu_src_AE = 32'd1;
        alu_src_BE = 32'hffff_ffff;
        #1;

        check_zero_E("BLT signed not taken", 1'b0, zero_E);
    endtask

    task automatic test_bge_taken_instr();
        apply_alu_defaults();

        alu_control_E = CTRL_SUB;
        btype_E = BGE;
        branch_E = 1'b1;
        alu_src_AE = 32'd1;
        alu_src_BE = 32'hffff_ffff;
        #1;

        check_zero_E("BGE signed taken", 1'b1, zero_E);
    endtask

    task automatic test_bge_not_taken_instr();
        apply_alu_defaults();

        alu_control_E = CTRL_SUB;
        btype_E = BGE;
        branch_E = 1'b1;
        alu_src_AE = 32'hffff_ffff;
        alu_src_BE = 32'd1;
        #1;

        check_zero_E("BGE signed not taken", 1'b0, zero_E);
    endtask

    task automatic test_bltu_taken_instr();
        apply_alu_defaults();

        alu_control_E = CTRL_SUB;
        btype_E = BLTU;
        branch_E = 1'b1;
        alu_src_AE = 32'd1;
        alu_src_BE = 32'hffff_ffff;
        #1;

        check_zero_E("BLTU unsigned taken", 1'b1, zero_E);
    endtask

    task automatic test_bltu_not_taken_instr();
        apply_alu_defaults();

        alu_control_E = CTRL_SUB;
        btype_E = BLTU;
        branch_E = 1'b1;
        alu_src_AE = 32'hffff_ffff;
        alu_src_BE = 32'd1;
        #1;

        check_zero_E("BLTU unsigned not taken", 1'b0, zero_E);
    endtask

    task automatic test_bgeu_taken_instr();
        apply_alu_defaults();

        alu_control_E = CTRL_SUB;
        btype_E = BGEU;
        branch_E = 1'b1;
        alu_src_AE = 32'hffff_ffff;
        alu_src_BE = 32'd1;
        #1;

        check_zero_E("BGEU unsigned taken", 1'b1, zero_E);
    endtask

    task automatic test_bgeu_not_taken_instr();
        apply_alu_defaults();

        alu_control_E = CTRL_SUB;
        btype_E = BGEU;
        branch_E = 1'b1;
        alu_src_AE = 32'd1;
        alu_src_BE = 32'hffff_ffff;
        #1;

        check_zero_E("BGEU unsigned not taken", 1'b0, zero_E);
    endtask

    task automatic test_add_instr();
        apply_alu_defaults();

        alu_control_E = CTRL_ADD;
        alu_src_AE = 32'd1;
        alu_src_BE = 32'd1;
        #1;

        check_alu_result("ADD instruction", 32'd2, alu_result_E);
        check_zero_E("ADD zero_E", 1'b0, zero_E);

    endtask

    task automatic test_add_overflow_instr();
        apply_alu_defaults();

        alu_control_E = CTRL_ADD;
        alu_src_AE = 32'hffff_ffff;
        alu_src_BE = 32'd1;
        #1;

        check_alu_result("ADD overflow wraps to zero", 32'h0000_0000, alu_result_E);
        check_zero_E("ADD overflow zero_E", 1'b1, zero_E);
    endtask

    task automatic test_sub_negative_instr();
        apply_alu_defaults();

        alu_control_E = CTRL_SUB;
        alu_src_AE = 32'd3;
        alu_src_BE = 32'd5;
        #1;

        check_alu_result("SUB negative result", 32'hffff_fffe, alu_result_E);
        check_zero_E("SUB negative zero_E", 1'b0, zero_E);
    endtask

    task automatic test_sub_equal_instr();
        apply_alu_defaults();

        alu_control_E = CTRL_SUB;
        alu_src_AE = 32'd7;
        alu_src_BE = 32'd7;
        #1;

        check_alu_result("SUB equal operands", 32'h0000_0000, alu_result_E);
        check_zero_E("SUB equal zero_E", 1'b1, zero_E);
    endtask

    task automatic test_and_instr();
        apply_alu_defaults();

        alu_control_E = CTRL_AND;
        alu_src_AE = 32'hf0f0_0ff0;
        alu_src_BE = 32'h0ff0_f0f0;
        #1;

        check_alu_result("AND instruction", 32'h00f0_00f0, alu_result_E);
        check_zero_E("AND zero_E", 1'b0, zero_E);
    endtask

    task automatic test_or_instr();
        apply_alu_defaults();

        alu_control_E = CTRL_OR;
        alu_src_AE = 32'hf0f0_0000;
        alu_src_BE = 32'h0000_0f0f;
        #1;

        check_alu_result("OR instruction", 32'hf0f0_0f0f, alu_result_E);
        check_zero_E("OR zero_E", 1'b0, zero_E);
    endtask

    task automatic test_xor_instr();
        apply_alu_defaults();

        alu_control_E = CTRL_XOR;
        alu_src_AE = 32'ha5a5_5a5a;
        alu_src_BE = 32'ha5a5_5a5a;
        #1;

        check_alu_result("XOR instruction", 32'h0000_0000, alu_result_E);
        check_zero_E("XOR zero_E", 1'b1, zero_E);
    endtask

    task automatic test_pass_b_instr();
        apply_alu_defaults();

        alu_control_E = CTRL_PASS_B;
        alu_src_AE = 32'hdead_beef;
        alu_src_BE = 32'h1234_5000;
        #1;

        check_alu_result("PASS_B instruction", 32'h1234_5000, alu_result_E);
        check_zero_E("PASS_B zero_E", 1'b0, zero_E);
    endtask

    task automatic test_pass_b4pc_instr();
        apply_alu_defaults();

        alu_control_E = CTRL_PASS_B4PC;
        alu_src_AE = 32'hdead_beef;
        alu_src_BE = 32'h1234_5000;
        pc_E = 32'h0000_1234;
        #1;

        check_alu_result("PASS_B4PC instruction", 32'h12346234, alu_result_E);
        check_zero_E("PASS_B4PC zero_E", 1'b0, zero_E);
    endtask 

    task automatic test_slt_true_instr();
        apply_alu_defaults();

        /*
        32'hffff_ffff is -1 when interpreted as signed.
        Therefore signed comparison -1 < 1 is true.

        PS: 
        SIGNED AND UNSIGNED HAVE DIFFERENT VALUES FOR A SAME NUM SUCH AS 0xffff_ffff,
        BECAUSE IT NEED TO CONSIDER THE SIGNED BIT!
        */
        alu_control_E = CTRL_SLT;
        alu_src_AE = 32'hffff_ffff;
        alu_src_BE = 32'd1;
        #1;

        check_alu_result("SLT signed comparison true", 32'd1, alu_result_E);
        check_zero_E("SLT true zero_E", 1'b0, zero_E);

    endtask

    task automatic test_slt_false_instr();
        apply_alu_defaults();

        alu_control_E = CTRL_SLT;
        alu_src_AE = 32'd1;
        alu_src_BE = 32'hffff_ffff;
        #1;

        check_alu_result("SLT signed comparison false", 32'd0, alu_result_E);
        check_zero_E("SLT false zero_E", 1'b1, zero_E);
    endtask

    task automatic test_sltu_false_instr();
        apply_alu_defaults();

        alu_control_E = CTRL_SLTU;
        alu_src_AE = 32'hffff_ffff;
        alu_src_BE = 32'd1;
        #1;

        check_alu_result("SLTU unsigned comparison false", 32'd0, alu_result_E);
        check_zero_E("SLTU false zero_E", 1'b1, zero_E);
    endtask

    task automatic test_sltu_true_instr();
        apply_alu_defaults();

        alu_control_E = CTRL_SLTU;
        alu_src_AE = 32'd1;
        alu_src_BE = 32'hffff_ffff;
        #1;

        check_alu_result("SLTU unsigned comparison true", 32'd1, alu_result_E);
        check_zero_E("SLTU true zero_E", 1'b0, zero_E);
    endtask

    task automatic test_sll_instr();
        apply_alu_defaults();

        alu_control_E = CTRL_SLL;
        alu_src_AE = 32'h0000_0001;
        alu_src_BE = 32'd4;
        #1;

        check_alu_result("SLL instruction", 32'h0000_0010, alu_result_E);
        check_zero_E("SLL zero_E", 1'b0, zero_E);

    endtask

    task automatic test_sll_low_five_bits_instr();
        apply_alu_defaults();

        alu_control_E = CTRL_SLL;
        alu_src_AE = 32'h0000_0001;
        alu_src_BE = 32'd32;
        #1;

        check_alu_result("SLL uses low five shift bits", 32'h0000_0001, alu_result_E);
        check_zero_E("SLL low five bits zero_E", 1'b0, zero_E);
    endtask

    task automatic test_srl_instr();
        // Unsigned! MSB doesn't add 1!
        apply_alu_defaults();

        alu_control_E = CTRL_SRL;
        alu_src_AE = 32'h8000_0000;
        alu_src_BE = 32'd1;
        #1;

        check_alu_result("SRL instruction", 32'h4000_0000, alu_result_E);
        check_zero_E("SRL zero_E", 1'b0, zero_E);
    endtask

    task automatic test_sra_instr();
        // Signed! MSB added 1!
        // 1000_0000_0000_0000_0000_0000_0000_0000 -> 1100_0000_0000_0000_0000_0000_0000_0000
        apply_alu_defaults();

        alu_control_E = CTRL_SRA;
        alu_src_AE = 32'h8000_0000;
        alu_src_BE = 32'd1;
        #1;

        check_alu_result("SRA instruction", 32'hc000_0000, alu_result_E);
        check_zero_E("SRA zero_E", 1'b0, zero_E);
    endtask

    task automatic test_invalid_control();
        apply_alu_defaults();

        alu_control_E = alu_ctrl_e'(4'b1111);
        alu_src_AE = 32'hffff_ffff;
        alu_src_BE = 32'hffff_ffff;
        #1;

        check_alu_result("Invalid control", 32'h0000_0000, alu_result_E);
        check_zero_E("Invalid control zero_E", 1'b1, zero_E);
    endtask

    task automatic check_alu_result(
        input string name,
        input logic [WORD_WIDTH - 1:0] expected_alu_result,
        input logic [WORD_WIDTH - 1:0] real_alu_result
    );
        if (expected_alu_result !== real_alu_result) begin
            $fatal(1, "%s: alu_result expected 0x%08h, got 0x%08h",
                   name, expected_alu_result, real_alu_result);
        end
    endtask

    task automatic check_zero_E(
        input string name,
        input logic expected_zero_E,
        input logic real_zero_E
    );
        if (expected_zero_E !== real_zero_E) begin
            $fatal(1, "%s: zero_E expected %0b, got %0b",
                   name, expected_zero_E, real_zero_E);
        end
    endtask

endmodule
