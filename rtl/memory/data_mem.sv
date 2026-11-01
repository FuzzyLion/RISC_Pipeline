module data_mem
    import core_types_pkg::*;
#(
    parameter string INIT_FILE = ""
)(
    input logic clk,
    /* 
    DO NOT CREATE THE DECLARATION LIKE THIS:
    input logic reset,

    CPU reset does not clear data memory!
    Initialization is handled separately to preserve RAM inference!
    */

    input logic data_mem_write,

    input logic [WORD_WIDTH - 1:0] alu_result_M,
    input logic [WORD_WIDTH - 1:0] store_wdata_M,

    input logic [3:0] store_wstrb_M,

    output logic [WORD_WIDTH - 1:0] mem_rdata_M,
    // 8 bits word index into data memory
    output logic [MEM_ADDR_WIDTH - 1:0] word_idx
);

    /* 
    Regs are always 32 bits large in RV32, so it will have 2^32 kinds of byte address.
    
    Relationship:
    byte address 0..3       -> mem[0]
    byte address 4..7       -> mem[1]
    ...
    byte address 1020..1023 -> mem[255]
    */
    logic [WORD_WIDTH - 1:0] mem [0:MEM_WORDS - 1]; // 256 entries, each entry stores one 32-bit word

    initial begin
        /*
        Synthesis semantics of initial depend on the target platform: 
        Used for register/RAM power-up initialization in FPGAs, 
        but typically unsupported in ASICs.
        */
        for (int i = 0; i < MEM_WORDS; i++) begin
            mem[i] = '0;
        end

        // Used for LB/LH/LW/LBU/LHU instructions
        if (INIT_FILE != "") begin
            $readmemh(INIT_FILE, mem);
        end
    end

    /* 
    ISA view:
    RISC-V memory is byte-addressed. For lw/sw, alu_result_M is the byte address,
    and the access starts at that byte address and covers 4 consecutive bytes.

    This Verilog model:
    mem is organized as 32-bit words. Each mem entry already contains 4 bytes,
    so the byte address must be divided by 4 to become a word-array index.

    For MEM_WORDS = 256, MEM_ADDR_WIDTH = 8, so word_idx uses alu_result_M[9:2].
    */

    assign word_idx = alu_result_M[MEM_ADDR_WIDTH + 1:2]; 
    assign mem_rdata_M = mem[word_idx];
    // Combinational read from the selected memory word

    always @(posedge clk) begin // Synchronous write
    // always_ff stipulate the inner variables can only be write in this section
    
        if (data_mem_write) begin
            
            // When the specific byte lanes are enable, update the pointed bytes
            if (store_wstrb_M[0]) begin
                mem[word_idx][7:0] <= store_wdata_M[7:0];
            end
            if (store_wstrb_M[1]) begin
                mem[word_idx][15:8] <= store_wdata_M[15:8];
            end
            if (store_wstrb_M[2]) begin
                mem[word_idx][23:16] <= store_wdata_M[23:16];
            end
            if (store_wstrb_M[3]) begin
                mem[word_idx][31:24] <= store_wdata_M[31:24];
            end

        end
    end
    
endmodule
