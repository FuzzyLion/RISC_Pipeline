module IF_ID (
    input logic clk,
    input logic reset, //The signal from the chips/FPGA
    input logic stall_D,
    input logic flush_D,

    input logic valid_F,
    input logic [31:0] pc_F,
    input logic [31:0] instr_F,
    input logic [31:0] pc_plus4_F,

    output logic valid_D,
    output logic [31:0] pc_D,
    output logic [31:0] instr_D,
    output logic [31:0] pc_plus4_D
);

always_ff @(posedge clk) begin
    if (reset || flush_D) begin
        // Reset or flush turns the Decode-stage instructions into a bubble
        valid_D <= 1'b0;
        instr_D <= 32'b0;
        pc_D <= 32'b0;
        pc_plus4_D <= 32'b0;
    end
    else if (!stall_D) begin
        // When Decode is not stalled, IF/ID captures the next fetched instruction
        valid_D <= valid_F;
        instr_D <= instr_F;
        pc_D <= pc_F;
        pc_plus4_D <= pc_plus4_F;
    end
end
    
endmodule