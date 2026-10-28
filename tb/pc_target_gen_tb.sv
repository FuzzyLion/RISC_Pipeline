`timescale 1ns/1ps

module pc_target_gen_tb
    import core_types_pkg::*;
();

    pc_target_src_e pc_target_src_E;
    logic jump_E;
    logic branch_E;
    logic zero_E;
    logic mret_en_E;

    logic [WORD_WIDTH - 1:0] pc_E;
    logic [WORD_WIDTH - 1:0] alu_src_AE;
    logic [WORD_WIDTH - 1:0] imm_E;

    logic [WORD_WIDTH - 1:0] pc_target_E;
    pc_src_e pc_src_E;
    trap_event_e trap_event_branch_jump_E;

    pc_target_gen dut (
        .pc_target_src_E(pc_target_src_E),
        .jump_E(jump_E),
        .branch_E(branch_E),
        .zero_E(zero_E),
        .mret_en_E(mret_en_E),
        .pc_E(pc_E),
        .alu_src_AE(alu_src_AE),
        .imm_E(imm_E),
        .trap_event_branch_jump_E(trap_event_branch_jump_E),
        .pc_target_E(pc_target_E),
        .pc_src_E(pc_src_E)
    );

`ifdef TRACE_VCD
    // The runner supplies an absolute path only when TRACE=1.
    initial begin : waveform_dump
        string trace_file;
        if ($value$plusargs("trace=%s", trace_file)) begin
            $dumpfile(trace_file);
            $dumpvars(0, pc_target_gen_tb);
        end
    end
`endif

    initial begin
        test_pc_relative_positive_offset();
        test_pc_relative_negative_offset();
        test_pc_relative_wraparound();
        test_jalr_even_target();
        test_jalr_clears_bit_zero();
        test_jalr_uses_alu_source_a();
        test_no_redirect();
        test_branch_not_taken();
        test_branch_taken();
        test_jump_redirect();
        test_mret_redirect();
        test_aligned_redirect_no_trap();
        test_misaligned_branch_target();
        test_misaligned_not_taken_no_trap();
        test_jalr_bit_one_misaligned();

        $display("PC_TARGET_GEN PASS: all tests completed");
        $finish;
    end

    task automatic apply_defaults();
        pc_target_src_E = PC_TARGET_PC_IMM;
        jump_E = 1'b0;
        branch_E = 1'b0;
        zero_E = 1'b0;
        mret_en_E = 1'b0;
        pc_E = '0;
        alu_src_AE = '0;
        imm_E = '0;
    endtask

    task automatic test_pc_relative_positive_offset();
        apply_defaults();

        pc_E = 32'h0000_0100;
        imm_E = 32'h0000_0020;
        #1;

        check_target("PC-relative positive offset", 32'h0000_0120);
    endtask

    task automatic test_pc_relative_negative_offset();
        apply_defaults();

        pc_E = 32'h0000_0100;
        imm_E = 32'hffff_fff0;
        #1;

        check_target("PC-relative negative offset", 32'h0000_00f0);
    endtask

    task automatic test_pc_relative_wraparound();
        apply_defaults();

        pc_E = 32'hffff_fff0;
        imm_E = 32'h0000_0020;
        #1;

        check_target("PC-relative 32-bit wraparound", 32'h0000_0010);
    endtask

    task automatic test_jalr_even_target();
        apply_defaults();

        pc_target_src_E = PC_TARGET_RS1_IMM;
        alu_src_AE = 32'h0000_0100;
        imm_E = 32'h0000_0004;
        #1;

        check_target("JALR even target", 32'h0000_0104);
    endtask

    task automatic test_jalr_clears_bit_zero();
        apply_defaults();

        pc_target_src_E = PC_TARGET_RS1_IMM;
        alu_src_AE = 32'h0000_0101;
        imm_E = 32'h0000_0004;
        #1;

        check_target("JALR clears target bit zero", 32'h0000_0104);
    endtask

    task automatic test_jalr_uses_alu_source_a();
        apply_defaults();

        pc_target_src_E = PC_TARGET_RS1_IMM;
        pc_E = 32'hdead_beef;
        alu_src_AE = 32'h0000_0200;
        imm_E = 32'h0000_0008;
        #1;

        check_target("JALR uses ALU source A instead of PC", 32'h0000_0208);
    endtask

    task automatic test_no_redirect();
        apply_defaults();
        #1;

        check_pc_src("ordinary instruction does not redirect", PC_PLUS4);
    endtask

    task automatic test_branch_not_taken();
        apply_defaults();

        branch_E = 1'b1;
        zero_E = 1'b0;
        #1;

        check_pc_src("branch with false condition", PC_PLUS4);
    endtask

    task automatic test_branch_taken();
        apply_defaults();

        branch_E = 1'b1;
        zero_E = 1'b1;
        #1;

        check_pc_src("branch with true condition", PC_TARGET);
    endtask

    task automatic test_jump_redirect();
        apply_defaults();
        
        jump_E = 1'b1;
        #1;

        check_pc_src("jump redirects unconditionally", PC_TARGET);
    endtask

    task automatic test_mret_redirect();
        apply_defaults();

        jump_E = 1'b1;
        mret_en_E = 1'b1;
        #1;

        check_pc_src("MRET has redirect priority", PC_MRET);
        check_trap_event("MRET with aligned ordinary target", TRAP_EVENT_NONE);
    endtask

    task automatic test_aligned_redirect_no_trap();
        apply_defaults();

        branch_E = 1'b1;
        zero_E = 1'b1;
        pc_E = 32'h0000_0100;
        imm_E = 32'h0000_0004;
        #1;

        check_trap_event("Aligned taken branch", TRAP_EVENT_NONE);
    endtask

    task automatic test_misaligned_branch_target();
        apply_defaults();

        branch_E = 1'b1;
        zero_E = 1'b1;
        pc_E = 32'h0000_0100;
        imm_E = 32'h0000_0002;
        #1;

        check_pc_src("Misaligned taken branch still requests target", PC_TARGET);
        check_trap_event("Misaligned taken branch", TRAP_EVENT_INSTR_ADDR_MISALIGNED);
    endtask

    task automatic test_misaligned_not_taken_no_trap();
        apply_defaults();

        branch_E = 1'b1;
        zero_E = 1'b0;
        pc_E = 32'h0000_0100;
        imm_E = 32'h0000_0002;
        #1;

        check_pc_src("Misaligned untaken branch does not redirect", PC_PLUS4);
        check_trap_event("Misaligned untaken branch", TRAP_EVENT_NONE);
    endtask

    task automatic test_jalr_bit_one_misaligned();
        apply_defaults();

        pc_target_src_E = PC_TARGET_RS1_IMM;
        jump_E = 1'b1;
        alu_src_AE = 32'h0000_0103;
        #1;

        check_target("JALR clears bit zero but preserves bit one", 32'h0000_0102);
        check_trap_event("JALR target with bit one set", TRAP_EVENT_INSTR_ADDR_MISALIGNED);
    endtask

    task automatic check_target(
        input string name,
        input logic [WORD_WIDTH - 1:0] expected_target
    );
        if (pc_target_E !== expected_target) begin
            $fatal(1, "%s: pc_target_E expected 0x%08h, got 0x%08h",
                   name, expected_target, pc_target_E);
        end
    endtask

    task automatic check_pc_src(
        input string name,
        input pc_src_e expected_pc_src
    );
        if (pc_src_E !== expected_pc_src) begin
            $fatal(1, "%s: pc_src_E expected %0b, got %0b",
                   name, expected_pc_src, pc_src_E);
        end
    endtask

    task automatic check_trap_event(
        input string name,
        input trap_event_e expected_trap_event
    );
        if (trap_event_branch_jump_E !== expected_trap_event) begin
            $fatal(1, "%s: trap event expected %0d, got %0d",
                   name, expected_trap_event, trap_event_branch_jump_E);
        end
    endtask

endmodule
