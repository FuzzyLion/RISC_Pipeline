module ID_EX
    import core_types_pkg::*;
(
    input logic clk,
    input logic reset,
    input logic flush_E,

    input control_bundle_t ctrl_D,
    input id_ex_data_t data_D,
    input trap_event_e trap_event_illegal_instr_D,

    output control_bundle_t ctrl_E,
    output id_ex_data_t data_E,
    output trap_event_e trap_event_illegal_instr_E
);

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
        csr_en: 1'b0
    };

    always_ff @(posedge clk) begin
        if (reset || flush_E) begin
            ctrl_E <= CTRL_NOP;

            data_E <= '0;
        end
        else begin
            ctrl_E <= ctrl_D;

            // Only controls that can cause architectural side effects or PC redirect are valid-gated.
            ctrl_E.rf_write <= data_D.valid && ctrl_D.rf_write;
            ctrl_E.mem_write <= data_D.valid && ctrl_D.mem_write;
            ctrl_E.jump <= data_D.valid && ctrl_D.jump;
            ctrl_E.branch <= data_D.valid && ctrl_D.branch;

            trap_event_illegal_instr_E <= data_D.valid ? trap_event_illegal_instr_D : TRAP_EVENT_NONE;

            data_E <= data_D;
        end
    end

endmodule
