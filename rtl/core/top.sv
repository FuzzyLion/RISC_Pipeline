// Future for board/SoC wrapper: clock/reset/memory/peripherals

module top (
    input logic clk,
    input logic reset
);

    core core_processor (
        .clk(clk),
        .reset(reset)
    );
    
endmodule
