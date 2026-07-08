module csr_file
    import core_types_pkg::*;
(
    input logic clk,
    input logic reset,

    input csrtype_e csrtype,
    input logic trap_entry_E,
    input logic csr_we,
    input logic csr_wdata,

    input logic [WORD_WIDTH - 1:0] trap_mcause_E,
    input logic [WORD_WIDTH - 1:0] trap_mtval_E,
    input logic [WORD_WIDTH - 1:0] trap_mepc_E,

    output logic [WORD_WIDTH - 1:0] mtvec,
    output logic [WORD_WIDTH - 1:0] mepc,
    output logic [WORD_WIDTH - 1:0] csr_rdata
);

    logic [WORD_WIDTH - 1:0] mtvec_reg;
    logic [WORD_WIDTH - 1:0] mepc_reg;
    logic [WORD_WIDTH - 1:0] mcause_reg;
    logic [WORD_WIDTH - 1:0] mtval_reg;
    logic [WORD_WIDTH - 1:0] mscratch_reg;
    logic [WORD_WIDTH - 1:0] mstatus_reg;
    logic [WORD_WIDTH - 1:0] mie_reg;
    logic [WORD_WIDTH - 1:0] mip_reg;


    assign csr_we = (csrtype !== TRAP);

    always_ff @(posedge clk) begin
        
        if (reset) begin
            mtvec_reg <= 32'b0;
            mepc_reg <= 32'b0;
            mcause_reg <= 32'b0;
            mtval_reg <= 32'b0;
            mscratch_reg <= 32'b0;
            mstatus_reg <= 32'h0000_1800;
            mie_reg <= 32'b0;
            mip_reg <= 32'b0;
        end
        else if (trap_entry_E) begin
            mtvec_reg <= mtvec_pc;
            mepc_reg <= trap_mepc_E;
            mcause_reg <= trap_mcause_E;
            mtval_reg <= trap_mtval_E;
            mstatus_reg[7] <= mstatus_reg[3];
            mstatus_reg[3] <= 1'b0;
            mstatus_reg[12:11] <= 2'b11; // Machine Mode
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
