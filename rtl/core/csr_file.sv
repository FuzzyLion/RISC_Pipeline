module csr_file
    import core_types_pkg::*;
(
    input logic clk,
    input logic reset,

    input logic vaild_E,

    input logic [WORD_WIDTH - 1:0] instr_E,
    input logic [WORD_WIDTH - 1:0] rs1_val_E,
    input logic [4:0] rs1_idx_E,
    input logic [WORD_WIDTH - 1:0] imm_E,

    input csrtype_e csrtype_E,
    input logic trap_entry_E,

    input logic [WORD_WIDTH - 1:0] trap_mcause_E,
    input logic [WORD_WIDTH - 1:0] trap_mtval_E,
    input logic [WORD_WIDTH - 1:0] trap_mepc_E,

    output logic [WORD_WIDTH - 1:0] mtvec,
    output logic [WORD_WIDTH - 1:0] mepc
);

    logic [WORD_WIDTH - 1:0] csr_regs [4096:0];

    logic [WORD_WIDTH - 1:0] mtvec_reg;
    logic [WORD_WIDTH - 1:0] mepc_reg;
    logic [WORD_WIDTH - 1:0] mcause_reg;
    logic [WORD_WIDTH - 1:0] mtval_reg;
    logic [WORD_WIDTH - 1:0] mscratch_reg;
    logic [WORD_WIDTH - 1:0] mstatus_reg;
    logic [WORD_WIDTH - 1:0] mie_reg;
    logic [WORD_WIDTH - 1:0] mip_reg;

    logic csr_instr_E;
    logic csr_we;
    logic [11:0] csr_addr;
    logic [WORD_WIDTH - 1:0] csr_rdata;
    logic [WORD_WIDTH - 1:0] csr_wdata;

    assign csr_addr = instr_E[31:20];

    always_comb begin : csr_we_assignment
        // Judge if it's a pure read-instruction or not
        csr_instr_E = vaild_E && (csrtype_D !== TRAP) && (opcode_D == OP_CSR);

        case (csrtype_E)
            CSRRW, CSRRWI: begin
                csr_we = csr_instr_E;
            end 
            CSRRS, CSRRC: begin
                csr_we = csr_instr_E && (rs1_val !== 5'b0);
                // Spec says: If rs1 = x0, then the instruction shall not write the CSR
            end
            CSRRSI, CSRRCI: begin
                csr_we = csr_instr_E && (imm_E !== 32'b0);
                // Spec says: If uimm = x0, then the instruction shall not write the CSR
                // Used here imm extension value instead of the instr_D[19:15]
            end
            default: begin
                csr_we = 1'b0;
            end
        endcase
    end

    always_comb begin : csr_wdata_assignment
        csr_rdata =  (instr_E == 5'b0) ? '0 : csr_regs[csr_addr];

        case (csrtype_E)
            CSRRW: begin
                csr_wdata = csr_rdata;
            end
            CSRRS: begin
                csr_wdata = csr_rdata | rs1_val_E;
            end
            CSRRC: begin
                csr_wdata = csr_rdata & ~rs1_val_E;
            end
            CSRRWI: begin
                csr_wdata = imm_E;
            end
            CSRRSI: begin
                csr_wdata = csr_rdata | imm_E;
            end
            CSRRCI: begin
                csr_wdata = csr_rdata & ~imm_E;
            end
            default: begin
                csr_wdata = '0;
            end
        endcase
    end

    always_ff @(posedge clk) begin
        
        if (reset) begin
            // Init csr_regs
            for (int i = 0; i < 4096; i++) begin
                csr_regs[i] <= '0;
            end

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
            
            case (csr_addr)
                12'h300: begin
                    mstatus_reg <= csr_wdata;
                end
                12'h305: begin
                    mtvec_reg <= csr_wdata;
                end
                12'h340: begin
                    mscratch_reg <= csr_wdata;
                end
                12'h341: begin
                    mepc_reg <= csr_wdata;
                end
                12'h342: begin
                   mcause_reg <= csr_wdata; 
                end
                12'h343: begin
                    mtval_reg <= csr_wdata;
                end
                default: begin
                    mtvec_reg <= 32'b0;
                    mepc_reg <= 32'b0;
                    mcause_reg <= 32'b0;
                    mtval_reg <= 32'b0;
                    mscratch_reg <= 32'b0;
                    mstatus_reg <= 32'h0000_1800;
                    mie_reg <= 32'b0;
                    mip_reg <= 32'b0;
                end
            endcase

        end

    end
    
endmodule
