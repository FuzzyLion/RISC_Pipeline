module trap_ctrl 
    import core_types_pkg::*;
(
    input logic [WORD_WIDTH - 1:0] instr_E,
    input logic [WORD_WIDTH - 1:0] pc_E,

    input trap_event_e trap_event_illegal_instr_E,
    input trap_event_e trap_event_branch_jump_E,
    input trap_event_e trap_event_load_store_E,
    
    output logic [WORD_WIDTH - 1:0] mcause_val,
    output logic [WORD_WIDTH - 1:0] mtval_val,
    output logic [WORD_WIDTH - 1:0] mepc_pc,
    output logic [WORD_WIDTH - 1:0] mtvec_pc,
    output logic trap_flush_D,
    output logic trap_flush_E
);
    
    always_comb begin
        mcause_val = 32'b0;
        mtval_val = 32'b0;
        mepc_pc = 32'b0;
        mtvec_pc = 32'b0;
        trap_flush_D = 1'b0;
        trap_flush_E = 1'b0;

        if (trap_event_illegal_instr_E == TRAP_EVENT_ENV_CALL_M_MODE) begin
            mcause_val = {1'b0, 31'd11};
            mtval_val = 0;
            mepc_pc = pc_E;
            trap_flush_D = 1'b0;
            trap_flush_E = 1'b0;
        end
        if (trap_event_illegal_instr_E == TRAP_EVENT_BREAKPOINT) begin
            mcause_val = {1'b0, 31'd3};
            mtval_val = 32'b0;
            mepc_pc = pc_E;
            trap_flush_D = 1'b0;
            trap_flush_E = 1'b0;
        end
        if (trap_event_illegal_instr_E == TRAP_EVENT_ILLEGAL_INSTR) begin
            mcause_val = {1'b0, 31'd2};
            mtval_val = instr_E;
            mepc_pc = pc_E;
            trap_flush_D = 1'b1;
            trap_flush_E = 1'b1;
        end
        if (trap_event_branch_jump_E == TRAP_EVENT_INSTR_ADDR_MISALIGNED) begin
            mcause_val = {1'b0, 31'd0};
            mtval_val = instr_E;
            mepc_pc = pc_E;
            trap_flush_D = 1'b1;
            trap_flush_E = 1'b1;
        end
        if (trap_event_load_store_E == TRAP_EVENT_LOAD_ADDR_MISALIGNED) begin
            mcause_val = {1'b0, 31'd4};
            mtval_val = instr_E;
            mepc_pc = pc_E;
            trap_flush_D = 1'b1;
            trap_flush_E = 1'b1;
        end
        if (trap_event_load_store_E == TRAP_EVENT_STORE_ADDR_MISALIGNED) begin
            mcause_val = {1'b0, 31'd6};
            mtval_val = instr_E;
            mepc_pc = pc_E;
            trap_flush_D = 1'b1;
            trap_flush_E = 1'b1;
        end
    end

endmodule
