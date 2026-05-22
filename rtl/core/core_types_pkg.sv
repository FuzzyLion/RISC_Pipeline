package core_types_pkg;

    // localparam int WORD_WIDTH = 32;
    // localparam int

    typedef enum logic [2:0] {
        IMM_I = 3'b000,
        IMM_S = 3'b001,
        IMM_B = 3'b010,
        IMM_J = 3'b011,
        IMM_U = 3'b100,
        IMM_IDLE = 3'b111
    } imm_src_e;

    typedef enum logic [3:0] {
        CTRL_ADD = 4'b0000,
        CTRL_SUB = 4'b0001,
        CTRL_AND = 4'b0010,
        CTRL_OR = 4'b0011,
        CTRL_XOR = 4'b0101,
        CTRL_PASS_B = 4'b0110,
        CTRL_SLT = 4'b0111,
        CTRL_SLTU = 4'b1000,
        CTRL_SLL = 4'b1001,
        CTRL_SRL = 4'b1010,
        CTRL_SRA = 4'b1100,
        CTRL_IDLE = 4'b1111
    } alu_ctrl_e;

    typedef enum logic [1:0] {
        RSLT_ALU = 2'b00,
        RSLT_RDATA = 2'b01,
        RSLT_PCPLUS4 = 2'b10,
        RSLT_IDLE = 2'b11
    } result_src_e;

    typedef enum logic {
        PC_PLUS4 = 1'b0,
        PC_TARGET = 1'b1
    } pc_src_e;

    typedef enum logic [1:0] {
        AE_RS1_VAL = 2'b00,
        AE_RSLT_W = 2'b01,
        AE_ALURSLT_W = 2'b10
    } forward_ae;

    typedef enum logic [1:0] {
        BE_RDATA_RS2_VAL = 2'b00,
        BE_RDATA_RSLT_W = 2'b01,
        BE_RDATA_ALURSLT_W = 2'b10
    } forward_rdata_be;

    typedef enum logic [1:0] {
        BE_RDATA_E = 2'b00,
        BE_IMM_E = 2'b01,
        BE_IDLE = 2'b11
    } alu_src_e;

    typedef enum logic [1:0] {
        PC_TARGET_PC_IMM = 2'b00,
        PC_TARGET_RS1_IMM = 2'b01,
        PC_TARGET_IDLE = 2'b11
    } pc_target_src_e;
endpackage
