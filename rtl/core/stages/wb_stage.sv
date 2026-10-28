// WB: final result selection; register-file write ports are wired in ID.

module wb_stage
    import core_types_pkg::*;
(
    input mem_wb_data_t data_W_memwb,
    input result_src_e result_src_W,
    output logic [WORD_WIDTH - 1:0] result_W_out
);

    // WB Result MUX
    WB_result_mux WB_result_mux1 (
        .alu_result_W(data_W_memwb.alu_result),
        .load_result_W(data_W_memwb.load_result),
        .pc_plus4_W(data_W_memwb.pc_plus4),
        .csr_rdata_W(data_W_memwb.csr_rdata),
        .result_src_W(result_src_W),
        .result_W(result_W_out)
    );

endmodule
