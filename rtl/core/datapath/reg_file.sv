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

    /*
    Function:
    1. regs array: architectural register state
    2. synchronous write: WB stage commits rd
    3. combinational read: ID stage reads rs1/rs2
    4. read-side bypass: same-cycle WB-to-ID forwarding
    */

    // Declaration all of the inner registers in RV32
    // Addresses from 5'd0 to 5'd31
    logic [WORD_WIDTH - 1:0] regs [31:0]; 

    always_ff @(posedge clk) begin : initial_and_WB
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

    // Read-side WB bypass: if WB writes the same register being read, return the new WB value
    assign rs1_val_D =  (rs1_idx_rf == 5'b0) ? '0 :
                        (rf_write_W && (rs1_idx_rf == rd_idx_W)) ? WB_mux_result :
                         regs[rs1_idx_rf];
    assign rs2_val_D =  (rs2_idx_rf == 5'b0) ? '0 : 
                        (rf_write_W && (rs2_idx_rf == rd_idx_W)) ? WB_mux_result :
                         regs[rs2_idx_rf];
    
endmodule
