// MEM: store/load formatting, internal RAM/timer MMIO, and outgoing MEM/WB register.

module mem_stage
    import core_types_pkg::*;
(
    input logic clk,
    input logic reset,
    input ex_mem_control_t ctrl_M,
    input ex_mem_data_t data_M_exmem,
    output mem_wb_control_t ctrl_W,
    output mem_wb_data_t data_W_memwb,
    output logic timer_irq,

    output logic [WORD_WIDTH - 1:0] observation_store_data,
    output logic observation_data_mem,
    output logic [MEM_ADDR_WIDTH - 1:0] observation_idx_mem,
    output logic [3:0] observation_store_wstrb
);

    // Internal stage signals.
    mem_wb_control_t ctrl_next_M;
    logic [3:0] store_wstrb_M_en;
    logic [WORD_WIDTH - 1:0] store_wdata_M_out;
    logic [WORD_WIDTH - 1:0] mtimecmp_wdata_M;
    logic mtimecmp_high_we;
    logic mtimecmp_low_we;
    logic data_mem_write;
    logic [WORD_WIDTH - 1:0] mem_rdata_M_out;
    logic [WORD_WIDTH - 1:0] load_result_M_out;
    mem_wb_data_t data_M_memwb;

    assign observation_store_data = store_wdata_M_out;
    assign observation_data_mem = data_mem_write;
    assign observation_store_wstrb = store_wstrb_M_en;

    assign ctrl_next_M = '{
        rf_write: ctrl_M.rf_write,
        result_src: ctrl_M.result_src
    };

    assign data_M_memwb = '{
        valid: data_M_exmem.valid,
        alu_result: data_M_exmem.alu_result,
        load_result: load_result_M_out,
        rd_idx: data_M_exmem.rd_idx,
        pc_plus4: data_M_exmem.pc_plus4,
        csr_rdata: data_M_exmem.csr_rdata
    };

    // Store Data Instructions Alignment
    store_data store_data1 (
        .store_type_M(ctrl_M.store_type),
        .alu_result_M(data_M_exmem.alu_result),
        .write_data_M(data_M_exmem.write_data),
        .store_wdata_M(store_wdata_M_out),
        .store_wstrb_M(store_wstrb_M_en)
    );

    // Machine Timer MMIO Decode
    mmio_decoder mmio_decoder1 (
        .mem_write_M(ctrl_M.mem_write),
        .alu_result_M(data_M_exmem.alu_result),
        .store_wdata_M(store_wdata_M_out),
        .store_wstrb_M(store_wstrb_M_en),
        .mtimecmp_wdata_M(mtimecmp_wdata_M),
        .mtimecmp_high_we(mtimecmp_high_we),
        .mtimecmp_low_we(mtimecmp_low_we),
        .data_mem_write(data_mem_write)
    );

    // Machine Timer
    machine_timer machine_timer1 (
        .clk(clk),
        .reset(reset),
        .mtimecmp_low_we(mtimecmp_low_we),
        .mtimecmp_high_we(mtimecmp_high_we),
        .mtimecmp_wdata(mtimecmp_wdata_M),
        .timer_irq(timer_irq)
    );

    // Data Memory
    data_mem data_mem1 (
        .clk(clk),
        .data_mem_write(data_mem_write),
        .alu_result_M(data_M_exmem.alu_result),
        .store_wdata_M(store_wdata_M_out),
        .store_wstrb_M(store_wstrb_M_en),
        .mem_rdata_M(mem_rdata_M_out),
        // Observation Signals in Vivado
        .word_idx(observation_idx_mem)
    );

    // Load Data Instructions Alignment
    load_data load_data1 (
        .load_type_M(ctrl_M.load_type),
        .alu_result_M(data_M_exmem.alu_result),
        .mem_rdata_M(mem_rdata_M_out),
        .load_result_M(load_result_M_out)
    );

    // MEM_WB Pipeline Register
    MEM_WB MEM_WB1 (
        .clk(clk),
        .reset(reset),
        .ctrl_next_M(ctrl_next_M),
        .data_M(data_M_memwb),
        .ctrl_W(ctrl_W),
        .data_W(data_W_memwb)
    );

endmodule
