module store_data 
    import core_types_pkg::*;
(
    input stype_e store_type,

    input [WORD_WIDTH - 1:0] alu_result_M,
    input [WORD_WIDTH - 1:0] write_data_M,

    output [WORD_WIDTH - 1:0] store_wdata_M,
    output [3:0] store_wstrb_M
);

    always_comb begin
        store_wdata_M = '0;
        store_wstrb_M = '0;

        case (store_type)
            SB: begin
                
                if (alu_result_M[1:0] == 2'b00) begin
                    store_wdata_M = {24'b0, write_data_M[7:0]};
                    store_wstrb_M = 4'b0001;
                end
                else if (alu_result_M[1:0] == 2'b01) begin
                    store_wdata_M = {16'b0, write_data_M[7:0], 8'b0};
                    store_wstrb_M = 4'b0010;
                end
                else if (alu_result_M[1:0] == 2'b10) begin
                    store_wdata_M = {8'b0, write_data_M[7:0], 16'b0};
                    store_wstrb_M = 4'b0100;
                end
                else if (alu_result_M[1:0] == 2'b11) begin
                    store_wdata_M = {write_data_M[7:0], 24'b0};
                    store_wstrb_M = 4'b1000;
                end
                else begin
                    store_wdata_M = 32'b0;
                    store_wstrb_M = 4'b0000;
                end

            end 
            SH: begin
                
                if (alu_result_M[1:0] == 2'b00) begin
                    store_wdata_M = {16'b0, write_data_M[15:0]};
                    store_wstrb_M = 4'b0011;
                end
                else if (alu_result_M[1:0] == 2'b10) begin
                    store_wdata_M = {write_data_M[15:0], 16'b0};
                    store_wstrb_M = 4'b1100;
                end
                // alu_result_M[1:0] == 01/11 are halfword misaligned, need to tackle in the future
                else begin
                    store_wdata_M = 32'b0;
                    store_wstrb_M = 4'b0000;
                end

            end
            SW: begin
                
                // Misaligned SW: future exception path
                if (alu_result_M[1:0] == 2'b00) begin
                    store_wdata_M = write_data_M;
                    store_wstrb_M = 4'b1111;
                end
                else begin
                    store_wdata_M = 32'b0;
                    store_wstrb_M = 4'b0000;
                end

            end
            default: begin
                store_wdata_M = 32'b0;
                store_wstrb_M = 4'b0;
            end
        endcase
    end
    
endmodule
