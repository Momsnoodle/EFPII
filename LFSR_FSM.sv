
module LFSR (
    input  logic clk_i,
    input  logic reset_i,
    output logic [99:0] lfsr_o
);

always_ff @(posedge clk_i) begin
    if (reset_i)
        lfsr_o <= 8'h1;

    else if(tick_i) // try to have minimal combinational logic in the always_ff block (a simple if statement is the maximum advised)
        lfsr_o <= {
            lfsr_o[6:0],
            lfsr_o[7] ^ lfsr_o[5]
        };
end

endmodule
