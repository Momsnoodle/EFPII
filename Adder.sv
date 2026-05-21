module ScoreAdder #(
    parameter N = 100
)(
    input  logic [N-1:0] compare_i,
    input  logic enable_i,


    output logic [$clog2(N+1)-1:0] score_o,

    output logic done_o
);

integer i;

always_comb begin
    score_o = 0;
    if (enable_i) begin
        for (i = 0; i < N; i++) begin
            score_o = score_o + compare_i[i];
        end
    end
end

endmodule