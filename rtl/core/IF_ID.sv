import core_types_pkg::*;

module IF_ID (
    input logic clk,
    input logic reset, //The signal from the chips/FPGA
    input logic stall_D,
    input logic flush_D,

    input if_id_data_t data_F,

    output if_id_data_t data_D
);

    always_ff @(posedge clk) begin
        if (reset || flush_D) begin
            // Reset or flush turns the Decode-stage instructions into a bubble
            data_D <= '0;
        end
        else if (!stall_D) begin
            // When Decode is not stalled, IF/ID captures the next fetched instruction
            data_D <= data_F;
        end
    end
    
endmodule