module trap_ctrl 
    import core_types_pkg::*;
(
    input logic valid_E,

    input logic [WORD_WIDTH - 1:0] instr_E,
    input logic [WORD_WIDTH - 1:0] pc_E,
    input logic [WORD_WIDTH - 1:0] pc_target_E,
    input logic [WORD_WIDTH - 1:0] alu_result_E,

    input trap_event_e trap_event_illegal_instr_E,
    input trap_event_e trap_event_branch_jump_E,
    input trap_event_e trap_event_load_store_E,
    input logic illegal_csr_access_E,

    output pc_src_with_trap_e pc_src_with_trap_E,
    
    output logic [WORD_WIDTH - 1:0] trap_mcause_E,
    output logic [WORD_WIDTH - 1:0] trap_mtval_E,
    output logic [WORD_WIDTH - 1:0] trap_mepc_E,
    output logic trap_flush_D,
    output logic trap_flush_E,
    output logic trap_flush_M,
    output logic trap_entry_E
);

    logic illegal_instr;
    logic instr_addr_misaligned;
    logic load_misaligned;
    logic store_misaligned;
    logic env_call;
    logic env_break;

    always_comb begin : trap_define
        illegal_instr = valid_E &&
                        (illegal_csr_access_E ||
                        (trap_event_illegal_instr_E == TRAP_EVENT_ILLEGAL_INSTR));
        instr_addr_misaligned = valid_E &&
                        (trap_event_branch_jump_E == TRAP_EVENT_INSTR_ADDR_MISALIGNED);
        load_misaligned = valid_E &&
                        (trap_event_load_store_E == TRAP_EVENT_LOAD_ADDR_MISALIGNED);
        store_misaligned = valid_E &&
                        (trap_event_load_store_E == TRAP_EVENT_STORE_ADDR_MISALIGNED);
        env_call = valid_E &&
                        (trap_event_illegal_instr_E == TRAP_EVENT_ENV_CALL_M_MODE);
        env_break = valid_E &&
                        (trap_event_illegal_instr_E == TRAP_EVENT_BREAKPOINT);
    end

    always_comb begin : trap_entry
        trap_entry_E = illegal_instr ||
                       env_call ||
                       env_break ||
                       instr_addr_misaligned ||
                       load_misaligned ||
                       store_misaligned;

        pc_src_with_trap_E = pc_src_with_trap_e'(trap_entry_E);
    end

    always_comb begin : trap_ctrl
        trap_mcause_E = 32'b0;
        trap_mtval_E = 32'b0;
        trap_mepc_E = 32'b0;
        trap_flush_D = 1'b0;
        trap_flush_E = 1'b0;
        trap_flush_M = 1'b0;

        /* 
        The reason why we set this kind of priority:
        1. If this instr can be running as a normal instr?
        - illegal / ecall / ebreak

        2. If it's a legal ctrl instr, is the fetch target also legal?
        - instruction address misaligned

        3. If it's a legal load/store instr, is the data addr also legal?
        - load/store address misaligned
        */
        if (illegal_instr) begin
            trap_mcause_E = {1'b0, 31'd2};
            trap_mtval_E = instr_E;
            trap_mepc_E = pc_E;
            trap_flush_D = 1'b1;
            trap_flush_E = 1'b1;
            trap_flush_M = 1'b1;
        end
        else if (env_call) begin
            trap_mcause_E = {1'b0, 31'd11};
            trap_mtval_E = 0;
            trap_mepc_E = pc_E;
            trap_flush_D = 1'b1;
            trap_flush_E = 1'b1;
            trap_flush_M = 1'b1;
        end
        else if (env_break) begin
            trap_mcause_E = {1'b0, 31'd3};
            trap_mtval_E = 32'b0;
            trap_mepc_E = pc_E;
            trap_flush_D = 1'b1;
            trap_flush_E = 1'b1;
            trap_flush_M = 1'b1;
        end
        else if (instr_addr_misaligned) begin
            trap_mcause_E = {1'b0, 31'd0};
            trap_mtval_E = pc_target_E;
            trap_mepc_E = pc_E;
            trap_flush_D = 1'b1;
            trap_flush_E = 1'b1;
            trap_flush_M = 1'b1;
        end
        else if (load_misaligned) begin
            trap_mcause_E = {1'b0, 31'd4};
            trap_mtval_E = alu_result_E;
            trap_mepc_E = pc_E;
            trap_flush_D = 1'b1;
            trap_flush_E = 1'b1;
            trap_flush_M = 1'b1;
        end
        else if (store_misaligned) begin
            trap_mcause_E = {1'b0, 31'd6};
            trap_mtval_E = alu_result_E;
            trap_mepc_E = pc_E;
            trap_flush_D = 1'b1;
            trap_flush_E = 1'b1;
            trap_flush_M = 1'b1;
        end
    end

endmodule
