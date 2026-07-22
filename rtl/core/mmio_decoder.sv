module mmio_decoder
    import core_types_pkg::*;
    import soc_addr_map_pkg::*;
(
    input logic mem_write_M,

    input logic [WORD_WIDTH - 1:0] alu_result_M,
    input logic [WORD_WIDTH - 1:0] store_wdata_M,
    input logic [3:0] store_wstrb_M,

    output logic [WORD_WIDTH - 1:0] mtimecmp_wdata_M,

    output logic mtimecmp_high_we,
    output logic mtimecmp_low_we,

    output logic data_mem_write
);

    logic is_mtimecmp_low;
    logic is_mtimecmp_high;

    assign mtimecmp_wdata_M = store_wdata_M;

    // Whether it's a mtimecmp_we control
    assign is_mtimecmp_high = (alu_result_M == MTIMECMP_HIGH_ADDR);
    assign is_mtimecmp_low = (alu_result_M == MTIMECMP_LOW_ADDR);

    // mtimecmp_we judgment
    // Restrict only aligned SW can write mtimecmp - (store_wstrb_M = 4'b1111)
    assign mtimecmp_high_we = mem_write_M && is_mtimecmp_high &&
                              (store_wstrb_M == 4'b1111);
    assign mtimecmp_low_we = mem_write_M && is_mtimecmp_low &&
                             (store_wstrb_M == 4'b1111);

    // Whether it's a data memory write
    assign data_mem_write = mem_write_M && !(is_mtimecmp_high || is_mtimecmp_low);
    
endmodule
