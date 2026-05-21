
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