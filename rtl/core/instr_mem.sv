module instr_mem #(
    WORD_WIDTH = 32,
    MEM_WORDS = 256
)(
    input logic [WORD_WIDTH - 1:0] pc_F,

    output logic [WORD_WIDTH - 1:0] instr_F
);
    
    localparam int MEM_ADDR_WIDTH = $clog2(MEM_WORDS);

    logic [WORD_WIDTH - 1:0] mem_instr [0:MEM_WORDS - 1];
    logic [MEM_ADDR_WIDTH - 1:0] word_idx;

    /*
    ISA view:
    In RV32, pc_F is a 32-bit byte address. Normal RV32I instructions are
    32 bits wide, so each instruction occupies 4 consecutive bytes.

    This Verilog model:
    mem_instr is organized as a word array. Each entry already stores one
    complete 32-bit instruction, so the byte address must be divided by 4
    before it can be used as an array index.

    Example:
    pc_F = 0x00000000 -> word_idx = 0 -> mem_instr[0]
    pc_F = 0x00000004 -> word_idx = 1 -> mem_instr[1]
    pc_F = 0x00000008 -> word_idx = 2 -> mem_instr[2]

    For MEM_WORDS = 256, MEM_ADDR_WIDTH = 8, so word_idx uses pc_F[9:2].
    The low bits pc_F[1:0] are the byte offset inside a 32-bit instruction
    word. In this first RV32I-only instruction memory, valid fetch addresses
    should have pc_F[1:0] == 2'b00. A later exception path can use those bits
    to detect a misaligned instruction fetch.
    */
    
    assign word_idx = pc_F[MEM_ADDR_WIDTH + 1:2];

    always_comb begin
        instr_F = mem_instr[word_idx];
    end

endmodule
