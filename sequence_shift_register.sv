module sequence_shift_register #(
    parameter int WIDTH = 16
)(
    input  logic clk_i,
    input  logic reset_i,
    input  logic enable_i,
    input  logic bit_in,
    output logic [WIDTH-1:0] sequence_out
);

    always_ff @(posedge clk_i or posedge reset_i) begin
        if (reset_i) begin
            sequence_out <= '0;
        end else if (enable_i) begin
            sequence_out <= {sequence_out[WIDTH-2:0], bit_in};
		end
    end

endmodule