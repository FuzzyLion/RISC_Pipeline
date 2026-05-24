module MEM_WB
    import core_types_pkg::*;
(
    input logic clk,
    input logic reset,

    input mem_wb_control_t ctrl_next_M,

    input mem_wb_data_t data_M,

    output mem_wb_control_t ctrl_W,

    output mem_wb_data_t data_W
);

    localparam mem_wb_control_t CTRL_NOP = '{
        rf_write: 1'b0,
        result_src: RSLT_ALU
    };

    always_ff @(posedge clk) begin
        if (reset) begin
            ctrl_W <= CTRL_NOP;

            data_W <= '0;
        end
        else begin
            ctrl_W <= ctrl_next_M;

            ctrl_W.rf_write <= data_M.valid && ctrl_next_M.rf_write;

            data_W <= data_M;
        end
    end
    
endmodule
