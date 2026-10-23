module machine_timer
(
    input logic clk,
    input logic reset,

    input logic mtimecmp_low_we,
    input logic mtimecmp_high_we,

    input logic [31:0] mtimecmp_wdata,

    output logic timer_irq // Timer interrupt request
);

    logic [63:0] mtime;
    logic [63:0] mtimecmp;

    always_ff @(posedge clk) begin

        if (reset) begin
            mtime <= 64'b0;
            mtimecmp <= 64'hFFFF_FFFF_FFFF_FFFF;
        end
        else begin
            mtime <= mtime + 64'b1;

            if (mtimecmp_low_we) begin
                mtimecmp[31:0] <= mtimecmp_wdata;
            end
            if (mtimecmp_high_we) begin
                mtimecmp[63:32] <= mtimecmp_wdata;
            end
        end
    end

    assign timer_irq = (mtime >= mtimecmp);

endmodule
