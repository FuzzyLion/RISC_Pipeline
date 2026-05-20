module pc_plus4_adder #(
    WORD_WIDTH = 32
)(
    input logic [WORD_WIDTH - 1:0] pc_F,

    output logic [WORD_WIDTH - 1:0] pc_plus4_F
);
    
    always_comb begin
        pc_plus4_F = pc_F + 4;
    end

endmodule