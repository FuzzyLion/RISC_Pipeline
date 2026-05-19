package core_types_pkg;

// localparam int WORD_WIDTH = 32;
// localparam int 

typedef enum logic [2:0] {
    IMM_I = 3'b000,
    IMM_S = 3'b001,
    IMM_B = 3'b010,
    IMM_J = 3'b011,
    IMM_U = 3'b100
} imm_src_e;

typedef enum logic [2:0] {
    CTRL_ADD = 3'b000,
    CTRL_SUB = 3'b001,
    CTRL_AND = 3'b010,
    CTRL_OR = 3'b011,
    CTRL_SLT = 3'b101,
    CTRL_PASS_B = 3'b110
} alu_control_e;

endpackage
