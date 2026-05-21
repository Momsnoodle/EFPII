
module Comparator #(
    parameter N = 100
)(
    input  logic [N-1:0] seq_a_i, //generated sequence stored
    input  logic [N-1:0] seq_b_i, //input sequence from player
    output logic [N-1:0] result_o // resulting sequence
);

assign result_o = ~(a_i ^ b_i);

endmodule