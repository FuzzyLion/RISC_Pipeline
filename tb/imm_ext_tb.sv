`timescale 1ps/1ps

module imm_ext_tb
    import core_types_pkg::*;
();

    imm_src_e imm_src_D;
    logic [WORD_WIDTH - 1:0] instr_D;
    logic [WORD_WIDTH - 1:0] imm_D;

    imm_ext dut (
        .imm_src_D(imm_src_D),
        .instr_D(instr_D),
        .imm_D(imm_D)
    );

`ifdef TRACE_VCD
    // The runner supplies an absolute path only when TRACE=1.
    initial begin : waveform_dump
        string trace_file;
        if ($value$plusargs("trace=%s", trace_file)) begin
            $dumpfile(trace_file);
            $dumpvars(0, imm_ext_tb);
        end
    end
`endif

    initial begin : test_sequence
        test_default_zero_ext();
        test_itype_ext();
        test_stype_ext();
        test_btype_ext();
        test_jtype_ext();
        test_utype_ext();

        $display("IMM_EXT PASS: all tests completed");
        $finish;
    end

    task automatic apply_ext_defaults();
        imm_src_D = IMM_I;
        instr_D = 32'b0;
    endtask

    task automatic test_default_zero_ext();
        check_ext("default zero I-Type immediate", IMM_I, 32'b0, 32'h0000_0000);
    endtask

    task automatic test_itype_ext();
        check_ext("I-Type positive immediate", IMM_I, 32'h00F1_0093, 32'h0000_000F); // addi x1, x2, 15
        check_ext("I-Type negative immediate", IMM_I, 32'hFFF1_0093, 32'hFFFF_FFFF); // addi x1, x2, -1
    endtask

    task automatic test_stype_ext();
        check_ext("S-Type positive immediate", IMM_S, 32'h0011_0223, 32'h0000_0004); // sb x1, 4(x2)
        check_ext("S-Type negative immediate", IMM_S, 32'hFE11_0E23, 32'hFFFF_FFFC); // sb x1, -4(x2)
    endtask

    task automatic test_btype_ext();
        check_ext("B-Type positive immediate", IMM_B, 32'h0020_8463, 32'h0000_0008); // beq x1, x2, 8
        check_ext("B-Type negative immediate", IMM_B, 32'hFE20_9CE3, 32'hFFFF_FFF8); // bne x1, x2, -8
    endtask

    task automatic test_jtype_ext();
        check_ext("J-Type positive immediate", IMM_J, 32'h0010_00EF, 32'h0000_0800); // jal x1, 2048
        check_ext("J-Type negative immediate", IMM_J, 32'hFFDF_F0EF, 32'hFFFF_FFFC); // jal x1, -4
    endtask

    task automatic test_utype_ext();
        check_ext("U-Type normal immediate", IMM_U, 32'h1234_50B7, 32'h1234_5000); // lui x1, 0x12345
        check_ext("U-Type high-bit immediate", IMM_U, 32'h8000_00B7, 32'h8000_0000); // lui x1, 0x80000
    endtask

    task automatic check_ext(
        input string name,
        input imm_src_e imm_src,
        input logic [WORD_WIDTH - 1:0] instr,
        input logic [WORD_WIDTH - 1:0] expected_imm
    );
        apply_ext_defaults();

        imm_src_D = imm_src;
        instr_D = instr;
        #1;

        if (imm_D !== expected_imm) begin
            $fatal(1, "%s: imm_D expected %08h, got %08h",
                   name, expected_imm, imm_D);
        end
    endtask

endmodule
