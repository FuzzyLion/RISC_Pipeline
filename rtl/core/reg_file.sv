module reg_file
    import core_types_pkg::*;
(
    input logic clk,
    input logic reset,

    input logic rf_write_W,

    input logic [ADDR_WIDTH - 1:0] rs1_idx_rf,
    input logic [ADDR_WIDTH - 1:0] rs2_idx_rf,
    input logic [ADDR_WIDTH - 1:0] rd_idx_W,
    input logic [WORD_WIDTH - 1:0] WB_mux_result,

    output logic [WORD_WIDTH - 1:0] rs1_val_D,
    output logic [WORD_WIDTH - 1:0] rs2_val_D
);

    logic [WORD_WIDTH - 1:0] regs [31:0]; // Declaration all of the inner registers in RV32

    always_ff @(posedge clk) begin
        if (reset) begin
            for (int i = 0; i < 32; i++) begin //Set i as a local variable
                regs[i] <= '0;
            end
        end else begin
            if (rf_write_W && (rd_idx_W != 5'b0)) begin
                regs[rd_idx_W] <= WB_mux_result;
            end
        end
    end

    assign rs1_val_D = (rs1_idx_rf == 5'b0) ? '0 : regs[rs1_idx_rf];
    assign rs2_val_D = (rs2_idx_rf == 5'b0) ? '0 : regs[rs2_idx_rf];
    
endmodule
