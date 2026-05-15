//Output a random sequence to LED slower than the clock
//saves the sequence in another register
//Give the length of the sequence and the number of bits of the sequence as parameter

module random_number_generator #(
	parameter int CLOCK_HZ = 50_000_000,
	parameter int SIGNAL_SECONDS = 1,
	parameter int SEQUENCE_BITS = 20
)(
    input  logic clk_i,
    input  logic reset_i,
	input logic enable_i,
    output logic led,
	output logic [SEQUENCE_BITS-1:0] saved_sequence
);

	//Calculate the length of the counter
    localparam int SIGNAL_CYCLES = CLOCK_HZ * SIGNAL_SECONDS;

    logic [15:0] random_value;
	logic [31:0] counter;
	logic next_bit_enable;
	logic current_led_bit;
	
	random_lfsr rng (
        .clk (clk_i),
        .reset (reset_i),
        .enable (next_bit_enable),
        .random_out (random_value)
    );
	
	sequence_shift_register #(
        .WIDTH(SEQUENCE_BITS)
    ) sequence_memory (
        .clk_i (clk_i),
        .reset_i (reset_i),
        .enable_i (next_bit_enable),
        .bit_in (random_value[0]),
        .sequence_out (saved_sequence)
    );
	
    always_ff @(posedge clk_i or posedge reset_i)
    begin
		if (reset_i) begin
            counter <= 32'd0;
            next_bit_enable <= 1'b0;
			current_led_bit <= 1'b0;		
        end else begin
			next_bit_enable <= 1'b0;
            if (enable_i) begin				
				if (counter == SIGNAL_CYCLES - 1) begin
					counter <= 32'd0;
					next_bit_enable <= 1'b1;
					current_led_bit <= random_value[0];
				end else begin
					counter <= counter + 1'b1;
				end
			end
		end
	end

    assign led = current_led_bit;

endmodule