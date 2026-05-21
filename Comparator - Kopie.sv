"""
module Comparator #(
    parameter N = 100
)(
    input  logic [N-1:0] seq_a_i, //generated sequence stored
    input  logic [N-1:0] seq_b_i, //input sequence from player
    input  logic enable_i,

    output logic [N-1:0] result_o // resulting sequence
    output logic done_o
);

if (enable_i) begin
    assign result_o = ~(a_i ^ b_i);


    done_o <= 1'b1;
end
endmodule
"""

module Comparator_immediate #( //immediate version with many registers
    parameter N = 100
)(
    input  logic [N-1:0] seq_a_i,
    input  logic [N-1:0] seq_b_i,
    input  logic         enable_i,

    output logic [N-1:0] result_o,
    output logic         done_o
);

assign result_o = enable_i ? ~(seq_a_i ^ seq_b_i) : '0;
assign done_o   = enable_i;

endmodule


module Comparator #( // sequential version with clk
    parameter N = 100
)(
    input  logic clk_i,
    input  logic rst_i,

    input  logic [N-1:0] seq_a_i,
    input  logic [N-1:0] seq_b_i,
    input  logic         enable_i,

    output logic [N-1:0] result_o,
    output logic         done_o
);

always_ff @(posedge clk_i) begin
    if (rst_i) begin
        result_o <= '0;
        done_o   <= 0;
    end else if (enable_i) begin
        result_o <= ~(seq_a_i ^ seq_b_i);
        done_o   <= 1;
    end else begin
        done_o <= 0;
    end
end

endmodule