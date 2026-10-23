// Future for board/SoC wrapper: clock/reset/memory/peripherals

module top #(
    parameter string IMEM_INIT_FILE = ""
) (
    input logic clk,
    input logic reset
);

    core #(
        .IMEM_INIT_FILE(IMEM_INIT_FILE)
    ) core_processor (
        .clk(clk),
        .reset(reset)
    );
    
endmodule
