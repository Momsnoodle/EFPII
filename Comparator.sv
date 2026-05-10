
module Comparator #(
    parameter N = 8
)(
    input  logic [N-1:0] a_i,
    input  logic [N-1:0] b_i,
    output logic [N-1:0] result_o
);

assign result_o = ~(a_i ^ b_i);

endmodule