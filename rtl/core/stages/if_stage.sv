// IF: PC selection, instruction fetch, and outgoing IF/ID register.

module if_stage
    import core_types_pkg::*;
#(
    parameter string IMEM_INIT_FILE = ""
)
(
    input logic clk,
    input logic reset,
    input logic stall_F,
    input logic stall_D,
    input logic flush_D,
    input pc_src_e pc_src_E,
    input pc_src_with_trap_e pc_src_with_trap_E,
    input logic [WORD_WIDTH - 1:0] pc_target_in,
    input logic [WORD_WIDTH - 1:0] mtvec_reg,
    input logic [WORD_WIDTH - 1:0] mepc_reg,
    output if_id_data_t data_D_ifid
);

    // Internal stage signals.
    logic [WORD_WIDTH - 1:0] pc_pre_out;
    logic [WORD_WIDTH - 1:0] pc_F_out;
    logic [WORD_WIDTH - 1:0] pc_plus4_F_out;
    logic [WORD_WIDTH - 1:0] instr_F_out;
    if_id_data_t data_F_ifid;

    assign data_F_ifid = '{
        valid: 1'b1,
        pc: pc_F_out,
        instr: instr_F_out,
        pc_plus4: pc_plus4_F_out
    };

    // PC MUX
    pc_mux pc_mux1 (
        .pc_src_E(pc_src_E),
        .pc_src_with_trap_E(pc_src_with_trap_E),
        .pc_target_E(pc_target_in),
        .pc_plus4_F(pc_plus4_F_out),
        .mtvec_reg(mtvec_reg),
        .mepc_reg(mepc_reg),
        .pc_pre_F(pc_pre_out)
    );

    // PC Reg
    pc_reg pc_reg1 (
        .clk(clk),
        .reset(reset),
        .stall_F(stall_F),
        .pc_pre_F(pc_pre_out),
        .pc_F(pc_F_out)
    );

    // PC4adder
    pc_plus4_adder pc_plus4_adder1 (
        .pc_F(pc_F_out),
        .pc_plus4_F(pc_plus4_F_out)
    );

    // Instruction Memory
    instr_mem #(
        .INIT_FILE(IMEM_INIT_FILE)
    ) instr_mem1 (
        .pc_F(pc_F_out),
        .instr_F(instr_F_out)
    );

    // IF_ID Pipeline Register
    IF_ID IF_ID1 (
        .clk(clk),
        .reset(reset),
        .stall_D(stall_D),
        .flush_D(flush_D),
        .data_F(data_F_ifid),
        .data_D(data_D_ifid)
    );

endmodule
