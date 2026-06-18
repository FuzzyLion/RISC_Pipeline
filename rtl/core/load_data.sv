module load_data 
    import core_types_pkg::*;
(
    input itype_load_e load_type_M,

    input logic [WORD_WIDTH - 1:0] alu_result_M,
    input logic [WORD_WIDTH - 1:0] mem_rdata_M,

    output logic [WORD_WIDTH - 1:0] load_result_M
);
    
    always_comb begin
        load_result_M = '0;

        case (load_type_M)        

            LB: begin
                
                if (alu_result_M[1:0] == 2'b00) begin
                    load_result_M = {{24{mem_rdata_M[7]}}, mem_rdata_M[7:0]};
                end
                else if (alu_result_M[1:0] == 2'b01) begin
                    load_result_M = {{24{mem_rdata_M[15]}}, mem_rdata_M[15:8]};
                end
                else if (alu_result_M[1:0] == 2'b10) begin
                    load_result_M = {{24{mem_rdata_M[23]}}, mem_rdata_M[23:16]};
                end
                else if (alu_result_M[1:0] == 2'b11) begin
                    load_result_M = {{24{mem_rdata_M[31]}}, mem_rdata_M[31:24]};
                end
                else begin
                    load_result_M = 32'b0;
                end

            end 
            LH: begin
                
                if (alu_result_M[1:0] == 2'b00) begin
                    load_result_M = {{16{mem_rdata_M[15]}}, mem_rdata_M[15:0]};
                end
                else if (alu_result_M[1:0] == 2'b10) begin
                    load_result_M = {{16{mem_rdata_M[31]}}, mem_rdata_M[31:16]};
                end
                // alu_result_M[1:0] == 01/11 are halfword misaligned, need to tackle in the future
                else begin
                    load_result_M = 32'b0;
                end

            end
            LW: begin
                
                // Misaligned LW: future exception path
                if (alu_result_M[1:0] == 2'b00) begin
                    load_result_M = mem_rdata_M;
                end
                else begin
                    load_result_M = 32'b0;
                end

            end
            LBU: begin
                
                if (alu_result_M[1:0] == 2'b00) begin
                    load_result_M = {24'b0, mem_rdata_M[7:0]};
                end
                else if (alu_result_M[1:0] == 2'b01) begin
                    load_result_M = {24'b0, mem_rdata_M[15:8]};
                end
                else if (alu_result_M[1:0] == 2'b10) begin
                    load_result_M = {24'b0, mem_rdata_M[23:16]};
                end
                else if (alu_result_M[1:0] == 2'b11) begin
                    load_result_M = {24'b0, mem_rdata_M[31:24]};
                end
                else begin
                    load_result_M = 32'b0;
                end

            end
            LHU: begin
                
                if (alu_result_M[1:0] == 2'b00) begin
                    load_result_M = {16'b0, mem_rdata_M[15:0]};
                end
                else if (alu_result_M[1:0] == 2'b10) begin
                    load_result_M = {16'b0, mem_rdata_M[31:16]};
                end
                // alu_result_M[1:0] == 01/11 are halfword misaligned, need to tackle in the future
                else begin
                    load_result_M = 32'b0;
                end

            end
            default: begin
                load_result_M = 32'b0;
            end
        endcase

    end

endmodule
