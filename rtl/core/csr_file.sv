module csr_file
    import core_types_pkg::*;
(
    input logic clk,
    input logic reset,

    input logic [WORD_WIDTH - 1:0] instr,
    input logic [WORD_WIDTH - 1:0] pc_E,
    input logic [WORD_WIDTH - 1:0] rs1_val_E,
    input logic [WORD_WIDTH - 1:0] rs2_val_E,
    input csrtype_e csrtype,

    input trap_event_e trap_event_illegal_instr_E,
    input trap_event_e trap_event_branch_jump_E,
    input trap_event_e trap_event_load_store_E,

    input logic [WORD_WIDTH - 1:0] mcause_val,
    input logic [WORD_WIDTH - 1:0] mtval_val,
    input logic [WORD_WIDTH - 1:0] mepc_pc,
    input logic [WORD_WIDTH - 1:0] mtvec_pc,
    input logic trap_flush_D,
    input logic trap_flush_E
);

    logic [WORD_WIDTH - 1:0] mtvec;
    logic [WORD_WIDTH - 1:0] mepc;
    logic [WORD_WIDTH - 1:0] mcause;
    logic [WORD_WIDTH - 1:0] mtval;
    logic [WORD_WIDTH - 1:0] mscratch;
    logic [WORD_WIDTH - 1:0] mstatus;
    logic [WORD_WIDTH - 1:0] mie;
    logic [WORD_WIDTH - 1:0] mip;

    logic trap_entry;
    logic csr_we;

    assign trap_entry = (trap_event_illegal_instr_E !== TRAP_EVENT_NONE) ||
                        (trap_event_branch_jump_E !== TRAP_EVENT_NONE) ||
                        (trap_event_load_store_E !== TRAP_EVENT_NONE);
    assign csr_we = (csrtype !== TRAP);

    always_ff @(posedge clk) begin
        
        if (reset) begin
            mtvec <= 32'b0;
            mepc <= 32'b0;
            mcause <= 32'b0;
            mtval <= 32'b0;
            mscratch <= 32'b0;
            mstatus <= 32'h0000_1800;
            mie <= 32'b0;
            mip <= 32'b0;
        end
        else if (trap_entry) begin
            mtvec <= mtvec_pc;
            mepc <= mepc_pc;
            mcause <= mcause_val;
            mtval <= mtval_val;
            mstatus[7] <= mstatus[3];
            mstatus[3] <= 1'b0;
            mstatus[12:11] <= 2'b11;
        end
        else if (csr_we) begin
            
            case (csrtype)
                CSRRW: begin
                    
                end
                CSRRS:
                CSRRC:
                CSRRWI:
                CSRRSI:
                CSRRCI: 
                default: 
            endcase

        end

    end
    
endmodule