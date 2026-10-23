module EX_MEM
    import core_types_pkg::*;
(
    input logic clk,
    input logic reset,

    input ex_mem_control_t ctrl_next_E,
    
    input ex_mem_data_t data_E,

    input logic trap_flush_M,

    output ex_mem_control_t ctrl_M,

    output ex_mem_data_t data_M
);

    localparam ex_mem_control_t CTRL_NOP = '{
        rf_write: 1'b0,
        result_src: RSLT_ALU,
        mem_write: 1'b0,
        load_type: LB,
        store_type: SB
    };

    always_ff @(posedge clk) begin
        if (reset || trap_flush_M) begin
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
