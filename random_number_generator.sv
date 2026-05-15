//Output a random sequence to LED

module random_number_generator (
    input  logic clk_i,
    input  logic reset_i,
	input logic enable_i,
    output logic led
);

    logic [15:0] random_value;

    random_lfsr rng (
        .clk_i (clk_i),
        .reset_i (reset_i),
        .enable_i (enable_i),
        .random_out (random_value)
    );

    assign led = random_value[0];

endmodule