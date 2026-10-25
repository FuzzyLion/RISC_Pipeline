module csr_file
    import core_types_pkg::*;
(
    input logic clk,
    input logic reset,

    input logic valid_E,
    input logic csr_en_E, // Euqals to CSR opcode
    input logic mret_en_E,
    input logic timer_irq,

    input logic [WORD_WIDTH - 1:0] instr_E,
    input logic [WORD_WIDTH - 1:0] rs1_val_E,
    input logic [4:0] rs1_idx_E,
    input logic [WORD_WIDTH - 1:0] imm_E,

    input csrtype_e csrtype_E,
    input logic trap_entry_E,

    input logic [WORD_WIDTH - 1:0] trap_mcause_E,
    input logic [WORD_WIDTH - 1:0] trap_mtval_E,
    input logic [WORD_WIDTH - 1:0] trap_mepc_E,

    output logic [WORD_WIDTH - 1:0] csr_rdata_E,
    output logic [WORD_WIDTH - 1:0] mstatus_reg,
    output logic [WORD_WIDTH - 1:0] mtvec_reg,
    output logic [WORD_WIDTH - 1:0] mepc_reg,
    output logic [WORD_WIDTH - 1:0] mip_reg,
    output logic [WORD_WIDTH - 1:0] mie_reg,

    output logic illegal_csr_access_E
);

    localparam logic [WORD_WIDTH - 1:0] MSTATUS_WRITE_MUSK = 32'h0000_0088;

    localparam logic [11:0] CSR_MSTATUS = 12'h300;
    localparam logic [11:0] CSR_MIE = 12'h304;
    localparam logic [11:0] CSR_MTVEC = 12'h305;
    localparam logic [11:0] CSR_MSCRATCH = 12'h340;
    localparam logic [11:0] CSR_MEPC = 12'h341;
    localparam logic [11:0] CSR_MCAUSE = 12'h342;
    localparam logic [11:0] CSR_MTVAL = 12'h343;
    localparam logic [11:0] CSR_MIP = 12'h344;

    logic [WORD_WIDTH - 1:0] mcause_reg;
    logic [WORD_WIDTH - 1:0] mtval_reg;
    logic [WORD_WIDTH - 1:0] mscratch_reg;


    logic csr_addr_supported;
    logic csr_instr_E;
    logic csr_we;
    logic [11:0] csr_addr;
    logic [WORD_WIDTH - 1:0] csr_wdata_E;

    assign csr_addr = instr_E[31:20];

    always_comb begin : csr_we_assignment
        // Judge if it's a pure read-instruction or not
        csr_instr_E = valid_E && (csrtype_E !== TRAP) && (csr_en_E == 1'b1);

        case (csrtype_E)
            TRAP: begin
                csr_we = 1'b0;
            end
            CSRRW, CSRRWI: begin
                csr_we = csr_instr_E;
            end 
            CSRRS, CSRRC: begin
                csr_we = csr_instr_E && (rs1_idx_E !== 5'b0);
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

    always_comb begin : csr_wdata_E_assignment
        csr_rdata_E = '0;

        case (csr_addr)
            CSR_MSTATUS: begin
                csr_rdata_E = mstatus_reg;
            end
            CSR_MIE: begin
                csr_rdata_E = mie_reg;
            end
            CSR_MTVEC: begin
                csr_rdata_E = mtvec_reg;
            end
            CSR_MSCRATCH: begin
                csr_rdata_E = mscratch_reg;
            end
            CSR_MEPC: begin
                csr_rdata_E = mepc_reg;
            end
            CSR_MCAUSE: begin
                csr_rdata_E = mcause_reg;
            end
            CSR_MTVAL: begin
                csr_rdata_E = mtval_reg;
            end
            CSR_MIP: begin
                csr_rdata_E = mip_reg;
            end
            default: begin
                csr_rdata_E = '0;
            end
        endcase

        case (csrtype_E)
            TRAP: begin
                csr_wdata_E = '0;
            end
            CSRRW: begin
                csr_wdata_E = rs1_val_E;
            end
            CSRRS: begin
                csr_wdata_E = csr_rdata_E | rs1_val_E;
            end
            CSRRC: begin
                csr_wdata_E = csr_rdata_E & ~rs1_val_E;
            end
            CSRRWI: begin
                csr_wdata_E = imm_E;
            end
            CSRRSI: begin
                csr_wdata_E = csr_rdata_E | imm_E;
            end
            CSRRCI: begin
                csr_wdata_E = csr_rdata_E & ~imm_E;
            end
            default: begin
                csr_wdata_E = '0;
            end
        endcase
    end

    always_comb begin : csr_addr_access
        case (csr_addr)
            CSR_MSTATUS, CSR_MIE, CSR_MTVEC, CSR_MSCRATCH, 
            CSR_MEPC, CSR_MCAUSE, CSR_MTVAL, CSR_MIP: begin
                csr_addr_supported = 1'b1;
            end

            default: begin
                csr_addr_supported = 1'b0;
            end
        endcase

        illegal_csr_access_E = csr_instr_E && !csr_addr_supported;
    end

    always_comb begin : MTIP_hardware_pending
        mip_reg = 32'b0;

        mip_reg[7] = timer_irq;
    end

    always_ff @(posedge clk) begin
        /*
        A CSR’s address is defined by the decode logic that maps the CSR address 
        to its storage register, not by the register’s physical location or 
        declaration.
        */
        
        if (reset) begin : init_CSRs
            mtvec_reg <= 32'b0;
            mepc_reg <= 32'b0;
            mcause_reg <= 32'b0;
            mtval_reg <= 32'b0;
            mscratch_reg <= 32'b0;
            mstatus_reg <= 32'h0000_1800;
            mie_reg <= 32'b0;
        end
        else if (trap_entry_E) begin : trap_occurs
            /*
            [ Trigger Condition Met ]
            │
            ├──> 1. mstatus.MPIE  <=  mstatus.MIE   (Backup current MIE state)
            ├──> 2. mstatus.MIE   <=  0             (Disable global interrupts)
            ├──> 3. mepc          <=  PC            (Save return address)
            ├──> 4. mcause        <=  Interrupt_ID  (Record cause of interrupt)
            └──> 5. PC            <=  mtvec         (Jump to trap handler)
            */
            mepc_reg <= trap_mepc_E;
            mcause_reg <= trap_mcause_E;
            mtval_reg <= trap_mtval_E;
            mstatus_reg[7] <= mstatus_reg[3]; // MPIE <- MIE
            mstatus_reg[3] <= 1'b0; // MIE <- 0
            mstatus_reg[12:11] <= 2'b11; // Machine Mode
        end
        else if (mret_en_E && valid_E) begin : trap_return
            /*
            [ Execute mret ]
            │
            ├──> 1. mstatus.MIE   <=  mstatus.MPIE  (Restore global interrupt state)
            ├──> 2. mstatus.MPIE  <=  1             (Reset backup bit)
            └──> 3. PC            <=  mepc          (Return to original execution)
            */
            mstatus_reg[3] <= mstatus_reg[7]; // MIE <- MPIE
            mstatus_reg[7] <= 1'b1; // MPIE <- 1
            mstatus_reg[12:11] <= 2'b11;
        end
        else if (csr_we) begin : CSR_Instructions
            
            case (csr_addr)
                CSR_MSTATUS: begin
                    // Unimplemented WPRI fields are read as zero, writes are ignored
                    // 32'h0000_1800 means only MPP = 11
                    // Only update MIE & MPIE in CSR instrs
                    mstatus_reg <= 32'h0000_1800 | 
                                   (csr_wdata_E & MSTATUS_WRITE_MUSK);
                end
                CSR_MIE: begin
                    // Currently only support machine timer interrupt
                    // Only update MTIE in CSR instrs
                    mie_reg <= csr_wdata_E & 32'h0000_0080;
                end
                CSR_MTVEC: begin
                    mtvec_reg <= {csr_wdata_E[WORD_WIDTH - 1:2], 2'b00};
                end
                CSR_MSCRATCH: begin
                    mscratch_reg <= csr_wdata_E;
                end
                CSR_MEPC: begin
                    // IALIGN=32 requires mepc[1:0] to be zero for CSR reads and MRET (Definition)
                    mepc_reg <= {csr_wdata_E[WORD_WIDTH - 1:2], 2'b00};
                end
                CSR_MCAUSE: begin
                   mcause_reg <= csr_wdata_E; 
                end
                CSR_MTVAL: begin
                    mtval_reg <= csr_wdata_E;
                end
                // MIP is a read-only reg, so no CSR_MIP is enabled
                default: begin
                    // All CSRs remain its former status
                end
            endcase
        end

    end
    
endmodule
