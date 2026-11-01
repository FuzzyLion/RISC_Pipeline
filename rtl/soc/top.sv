// Future for board/SoC wrapper: clock/reset/memory/peripherals

module top 
    import core_types_pkg::*;
#(
    parameter string IMEM_INIT_FILE = ""
) (
    input logic clk,
    input logic reset,

    output logic [WORD_WIDTH - 1:0] observation_wb_data,
    output logic observation_wb_rf_write,
    output logic [ADDR_WIDTH - 1:0] observation_wb_rd_idx,
    output logic [WORD_WIDTH - 1:0] observation_store_data,
    output logic observation_data_mem,
    output logic [MEM_ADDR_WIDTH - 1:0] observation_idx_mem,
    output logic [3:0] observation_store_wstrb
);

    core #(
        .IMEM_INIT_FILE(IMEM_INIT_FILE)
    ) core_processor (
        .clk(clk),
        .reset(reset),
        // Observation Signals in Vivado
        .observation_wb_data(observation_wb_data),
        .observation_wb_rf_write(observation_wb_rf_write),
        .observation_wb_rd_idx(observation_wb_rd_idx),
        .observation_store_data(observation_store_data),
        .observation_data_mem(observation_data_mem),
        .observation_idx_mem(observation_idx_mem),
        .observation_store_wstrb(observation_store_wstrb)
    );
    
endmodule
