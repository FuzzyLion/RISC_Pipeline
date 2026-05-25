module instr_field 
    import core_types_pkg::*;
(
    input logic [WORD_WIDTH - 1:0] instr_D,

    output logic [ADDR_WIDTH - 1:0] rs1_idx_D,
    output logic [ADDR_WIDTH - 1:0] rs2_idx_D,
    output logic [ADDR_WIDTH - 1:0] rd_idx_D
);

    assign rs1_idx_D = instr_D[19:15];
    assign rs2_idx_D = instr_D[24:20];
    assign rd_idx_D = instr_D[11:7];
    
endmodule
