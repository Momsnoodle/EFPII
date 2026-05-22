



module ScoreAdder #(
    parameter SEQ_LENGTH = 100
)(
    input  logic [SEQ_LENGTH-1:0] compare_i,
    input  logic         enable_i,
    input  logic         rst_i,

    output logic [9:0] score_o,
    output logic         done_o
);

integer i;
logic [9:0] sum;

always_comb begin
    sum = '0;

    if (!rst_i && enable_i) begin
        for (i = 0; i < SEQ_LENGTH; i++) begin
           if (compare_i[i])begin
            sum = sum + 1; // add one to it
           end
        end
    end

    score_o = sum;

    // simple handshake
    done_o = enable_i;
end

endmodule

