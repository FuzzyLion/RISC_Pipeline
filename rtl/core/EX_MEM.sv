import core_types_pkg::*;

module EX_MEM (
    input logic clk,
    input logic reset,

    input ex_mem_control_t ctrl_next_E,
    
    input ex_mem_data_t data_E,

    output ex_mem_control_t ctrl_M,

    output ex_mem_data_t data_M
);

    localparam ex_mem_control_t CTRL_NOP = {
        1'b0,              // rf_write_M
        RSLT_ALU,          //result_src_M
        1'b0               //mem_write_M
    };

    always_ff @(posedge clk) begin
        if (reset) begin
            ctrl_M <= CTRL_NOP;

            data_M <= '0;
        end
        else begin
            ctrl_M <= ctrl_next_E;

            ctrl_M.rf_write <= data_E.valid && ctrl_next_E.rf_write;
            ctrl_M.mem_write <= data_E.valid && ctrl_next_E.mem_write;

            data_M <= data_E;
        end
    end
    
endmodule
