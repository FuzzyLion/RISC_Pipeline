module ID_EX #(
    parameter WORD_WIDTH = 32,
    parameter ADDR_WIDTH = 5
)(
    input logic clk,
    input logic reset,
    input logic flush_E,
    
    input logic rf_write_D,
    input logic [1:0] result_src_D,
    input logic mem_write_D,
    input logic jump_D,
    input logic branch_D,
    input logic [2:0] alu_ctrl_D,
    input logic alu_src_D,

    input logic valid_D,
    input logic [WORD_WIDTH - 1:0] pc_D,
    input logic [WORD_WIDTH - 1:0] pc_plus4_D,
    input logic [ADDR_WIDTH - 1:0] rs1_idx_D,
    input logic [ADDR_WIDTH - 1:0] rs2_idx_D,
    input logic [ADDR_WIDTH - 1:0] rd_idx_D,
    // All value variables are 32 bits large in RV32
    input logic [WORD_WIDTH - 1:0] rs1_val_D, 
    input logic [WORD_WIDTH - 1:0] rs2_val_D,
    input logic [WORD_WIDTH - 1:0] imm_D,

    output logic rf_write_E,
    output logic [1:0] result_src_E,
    output logic mem_write_E,
    output logic jump_E,
    output logic branch_E,
    output logic [2:0] alu_ctrl_E,
    output logic alu_src_E,

    output logic valid_E,
    output logic [WORD_WIDTH - 1:0] pc_E,
    output logic [WORD_WIDTH - 1:0] pc_plus4_E,
    output logic [ADDR_WIDTH - 1:0] rs1_idx_E,
    output logic [ADDR_WIDTH - 1:0] rs2_idx_E,
    output logic [ADDR_WIDTH - 1:0] rd_idx_E,
    output logic [WORD_WIDTH - 1:0] rs1_val_E,
    output logic [WORD_WIDTH - 1:0] rs2_val_E,
    output logic [WORD_WIDTH - 1:0] imm_E
);

always_ff @(posedge clk) begin
    if (reset || flush_E) begin
        rf_write_E <= 1'b0;
        result_src_E <= 2'b0;
        mem_write_E <= 1'b0;
        jump_E <= 1'b0;
        branch_E <= 1'b0;
        alu_ctrl_E <= 3'b0;
        alu_src_E <= 1'b0;

        valid_E <= 1'b0;
        pc_E <= 32'b0;
        pc_plus4_E <= 32'b0;
        rs1_idx_E <= 5'b0;
        rs2_idx_E <= 5'b0;
        rd_idx_E <= 5'b0;
        rs1_val_E <= 32'b0;
        rs2_val_E <= 32'b0;
        imm_E <= 32'b0;
    end
    else begin
        rf_write_E <= rf_write_D;
        result_src_E <= result_src_D;
        mem_write_E <= mem_write_D;
        jump_E <= jump_D;
        branch_E <= branch_D;
        alu_ctrl_E <= alu_ctrl_D;
        alu_src_E <= alu_src_D;

        valid_E <= valid_D;
        pc_E <= pc_D;
        pc_plus4_E <= pc_plus4_D;
        rs1_idx_E <= rs1_idx_D;
        rs2_idx_E <= rs2_idx_D;
        rd_idx_E <= rd_idx_D;
        rs1_val_E <= rs1_val_D;
        rs2_val_E <= rs2_val_D;
        imm_E <= imm_D;
    end
end
    
endmodule