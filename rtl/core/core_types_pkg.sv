package core_types_pkg;

    localparam int WORD_WIDTH = 32;
    localparam int ADDR_WIDTH = 5;

    localparam logic [6:0] FUNCT7_EN = 7'b0100000;
    localparam logic [6:0] FUNCT7_DI = 7'b0000000;

    localparam logic [2:0] JALR = 3'b000;

    parameter int MEM_WORDS = 256;
    localparam int MEM_ADDR_WIDTH = $clog2(MEM_WORDS); 
    /* 
    MEM_ADDR_WIDTH = 8
    According to the data size to derive to the MEM_ADDR_WIDTH
    */

    //--------------------------------------------------------------------------------------

    typedef enum logic [6:0] { 
        OP_ITYPE_LOAD = 7'b0000011,
        OP_ITYPE_IMM = 7'b0010011,
        OP_UTYPE_AUIPC = 7'b0010111,
        OP_STYPE = 7'b0100011,
        OP_RTYPE = 7'b0110011,
        OP_UTYPE_LUI = 7'b0110111,
        OP_BTYPE = 7'b1100011,
        OP_ITYPE_JALR = 7'b1100111,
        OP_JTYPE_JAL = 7'b1101111,
        OP_CSR = 7'b1110011
    } opcode_e;

    typedef enum logic [9:0] { 
        ADD = {3'b000, FUNCT7_DI},
        SUB = {3'b000, FUNCT7_EN},
        SLL = {3'b001, FUNCT7_DI},
        SLT = {3'b010, FUNCT7_DI},
        SLTU = {3'b011, FUNCT7_DI},
        XOR = {3'b100, FUNCT7_DI},
        SRL = {3'b101, FUNCT7_DI},
        SRA = {3'b101, FUNCT7_EN},
        OR = {3'b110, FUNCT7_DI},
        AND = {3'b111, FUNCT7_DI}
    } rtype_e;

    typedef enum logic [2:0] { 
        LB = 3'b000,
        LH = 3'b001,
        LW = 3'b010,
        LBU = 3'b100,
        LHU = 3'b101
    } itype_load_e;

    typedef enum logic [2:0] { 
        ADDI = 3'b000,
        SLTIU = 3'b011,
        ORI = 3'b110,
        ANDI = 3'b111,
        SLTI = 3'b010,
        XORI = 3'b100
    } itype_imm_e;

    typedef enum logic [9:0] { 
        SLLI = {3'b001, FUNCT7_DI},
        SRLI = {3'b101, FUNCT7_DI},
        SRAI = {3'b101, FUNCT7_EN}
    } itype_immext_e;

    typedef enum logic [2:0] { 
        SB = 3'b000,
        SH = 3'b001,
        SW = 3'b010
    } stype_e;

    typedef enum logic [2:0] { 
        BEQ = 3'b000,
        BNE = 3'b001,
        BLT = 3'b100,
        BGE = 3'b101,
        BLTU = 3'b110,
        BGEU = 3'b111
    } btype_e;

    typedef enum logic [2:0] { 
        TRAP = 3'b000,
        CSRRW = 3'b001,
        CSRRS = 3'b010,
        CSRRC = 3'b011,
        CSRRWI = 3'b101,
        CSRRSI = 3'b110,
        CSRRCI = 3'b111
    } csrtype_e;

    typedef enum logic [2:0] {
        IMM_I = 3'b000,
        IMM_S = 3'b001,
        IMM_B = 3'b010,
        IMM_J = 3'b011,
        IMM_U = 3'b100,
        IMM_CSR = 3'b101
    } imm_src_e;

    typedef enum logic [3:0] {
        CTRL_ADD = 4'b0000,
        CTRL_SUB = 4'b0001,
        CTRL_AND = 4'b0010,
        CTRL_OR = 4'b0011,
        CTRL_XOR = 4'b0101,
        CTRL_PASS_B = 4'b0110,
        CTRL_PASS_B4PC = 4'b1101,
        CTRL_SLT = 4'b0111,
        CTRL_SLTU = 4'b1000,
        CTRL_SLL = 4'b1001,
        CTRL_SRL = 4'b1010,
        CTRL_SRA = 4'b1100
    } alu_ctrl_e;

    typedef enum logic [1:0] {
        RSLT_ALU = 2'b00,
        RSLT_RDATA = 2'b01,
        RSLT_PCPLUS4 = 2'b10,
        RSLT_CSR_RDATA = 2'b11
    } result_src_e;

    typedef enum logic [1:0] {
        PC_PLUS4 = 2'b00,
        PC_TARGET = 2'b01,
        PC_MRET = 2'b10
    } pc_src_e;

    typedef enum logic {
        PC_TRAP_NONE = 1'b0,
        PC_TRAP_HANDLER = 1'b1
    } pc_src_with_trap_e;

    typedef enum logic [1:0] {
        AE_RS1_VAL = 2'b00,
        AE_RESULT_W = 2'b01,
        AE_ALU_RESULT_M = 2'b10,
        AE_CSR_RDATA_M = 2'b11
    } forward_ae;

    typedef enum logic [1:0] {
        BE_RDATA_RS2_VAL = 2'b00,
        BE_RDATA_RESULT_W = 2'b01,
        BE_RDATA_ALU_RESULT_M = 2'b10,
        BE_CSR_RDATA_M = 2'b11
    } forward_rdata_be;

    typedef enum logic {
        BE_RDATA_E = 1'b0,
        BE_IMM_E = 1'b1
    } alu_src_e;

    typedef enum logic {
        PC_TARGET_PC_IMM = 1'b0,
        PC_TARGET_RS1_IMM = 1'b1
    } pc_target_src_e;

    typedef enum logic [3:0] { 
        TRAP_EVENT_M_SOFTWARE_INTERRUPT = 4'b0000,
        TRAP_EVENT_M_TIMER_INTERRUPT = 4'b0001,
        TRAP_EVENT_M_EXTER_INTERRUPT = 4'b0010,
        TRAP_EVENT_INSTR_ADDR_MISALIGNED = 4'b0011,
        TRAP_EVENT_ILLEGAL_INSTR = 4'b0100,
        TRAP_EVENT_BREAKPOINT = 4'b0101,
        TRAP_EVENT_LOAD_ADDR_MISALIGNED = 4'b0110,
        TRAP_EVENT_LOAD_ACCESS_FAULT = 4'b0111,
        TRAP_EVENT_STORE_ADDR_MISALIGNED = 4'b1000,
        TRAP_EVENT_STORE_ACCESS_FAULT = 4'b1001,
        TRAP_EVENT_ENV_CALL_M_MODE = 4'b1010,
        TRAP_EVENT_NONE = 4'b1111
    } trap_event_e;

    typedef enum logic [11:0] { 
        CSR_ECALL = 12'b0000_0000_0000,
        CSR_EBREAK = 12'b0000_0000_0001,
        CSR_MRET = 12'b0011_0000_0010
    } csr_imm_e;

    //--------------------------------------------------------------------------------------

    typedef struct packed {
        logic rf_write;
        result_src_e result_src;
        logic mem_write;
        logic jump;
        pc_target_src_e pc_target_src;
        logic branch;
        alu_ctrl_e alu_ctrl;
        alu_src_e alu_src;
        btype_e btype;
        itype_load_e load_type;
        stype_e store_type;
        csrtype_e csrtype;
        logic csr_en;
        logic mret_en;
    } control_bundle_t;

    typedef struct packed {
        logic rf_write;
        result_src_e result_src;
        logic mem_write;
        itype_load_e load_type;
        stype_e store_type;
    } ex_mem_control_t;

    typedef struct packed {
        logic rf_write;
        result_src_e result_src;
    } mem_wb_control_t;

    typedef struct packed {
        logic valid;
        logic [WORD_WIDTH - 1:0] pc;
        logic [WORD_WIDTH - 1:0] instr;
        logic [WORD_WIDTH - 1:0] pc_plus4;
    } if_id_data_t;

    typedef struct packed {
        logic valid;
        logic [WORD_WIDTH - 1:0] pc;
        logic [WORD_WIDTH - 1:0] instr;
        logic [WORD_WIDTH - 1:0] pc_plus4;
        logic [ADDR_WIDTH - 1:0] rs1_idx;
        logic [ADDR_WIDTH - 1:0] rs2_idx;
        logic [ADDR_WIDTH - 1:0] rd_idx;
        // All value variables are 32 bits large in RV32
        logic [WORD_WIDTH - 1:0] rs1_val;
        logic [WORD_WIDTH - 1:0] rs2_val;
        logic [WORD_WIDTH - 1:0] imm;
    } id_ex_data_t;

    typedef struct packed {
        logic valid;
        logic [WORD_WIDTH - 1:0] alu_result;
        logic [WORD_WIDTH - 1:0] write_data;
        logic [ADDR_WIDTH - 1:0] rd_idx;
        logic [WORD_WIDTH - 1:0] pc_plus4;
        logic [WORD_WIDTH - 1:0] csr_rdata;
    } ex_mem_data_t;

    typedef struct packed {
        logic valid;
        logic [WORD_WIDTH - 1:0] alu_result;
        logic [WORD_WIDTH - 1:0] load_result;
        logic [ADDR_WIDTH - 1:0] rd_idx;
        logic [WORD_WIDTH - 1:0] pc_plus4;
        logic [WORD_WIDTH - 1:0] csr_rdata;
    } mem_wb_data_t;

    typedef struct packed {
        forward_ae forward_AE;
        forward_rdata_be forward_BE;
    } hazard_forward_t;

    typedef struct packed {
        logic stall_F;
        logic stall_D;
        logic flush_D;
        logic flush_E;
    } hazard_stallflush_t;

endpackage
