//generate pseuto-random numbers

module random_lfsr (
	input logic clk,
	input logic reset,
	input logic enable,
	output logic [15:0] random_out
);
	
	//Fibonacci-LSFR 
	logic feedback
	assign feedback = random_out[15] ^ random_out[13] ^ random_out[12] ^ random_out[10];
	
	//ff
    always_ff @(posedge clk_i or posedge reset_i)
    begin
        if (reset_i)
            random_out <= 16'h0FCB;
        else if (enable_i)
            random_out <= {random_out[14:0], feedback};
    end
	
endmodule

	