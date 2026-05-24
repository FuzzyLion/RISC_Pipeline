import core_types_pkg::*;

module ID_EX (
    input logic clk,
    input logic reset,
    input logic flush_E,

    input control_bundle_t ctrl_D,
    input id_ex_data_t data_D,

    output control_bundle_t ctrl_E,
    output id_ex_data_t data_E
);

    localparam control_bundle_t CTRL_NOP = '{
        1'b0,              // rf_write
        RSLT_ALU,          // result_src
        1'b0,              // mem_write
        1'b0,              // jump
        PC_TARGET_PC_IMM,  // pc_target_src
        1'b0,              // branch
        CTRL_ADD,          // alu_ctrl
        BE_RDATA_E         // alu_src
    };

    always_ff @(posedge clk) begin
        if (reset || flush_E) begin
            ctrl_E <= CTRL_NOP;

            data_E <= '0;
        end
        else begin
            ctrl_E <= ctrl_D;

            // *** Musk ***
            ctrl_E.rf_write <= data_D.valid && ctrl_D.rf_write;
            // These kinds of instructions with "valid" confirmation will influence the further state of the processor
            // This ain't the "Write" action itself so it doesn't need "vaild" control
            ctrl_E.mem_write <= data_D.valid && ctrl_D.mem_write;
            ctrl_E.jump <= data_D.valid && ctrl_D.jump;

            /*
            pc_target_src only selects how the target address is formed.
            It has no effect unless the valid-masked jump/branch controls
            actually redirect the PC.
            */

            ctrl_E.branch <= data_D.valid && ctrl_D.branch;
            // Same reason as "result_src_E" about why they don't need "valid"

            data_E <= data_D;
            /* 
            In fact data transfers as the bits moving, so we need to make sure there's
            a generic payload for both in & output
            */
        end
    end

endmodule
