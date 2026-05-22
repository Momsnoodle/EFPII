module ScoreAdder #(
    parameter SEQ_LENGTH = 100,
    parameter SCORE_W = 10
)(
    input  logic clk_i,
    input  logic rst_i,

    input  logic [SEQ_LENGTH-1:0] compare_i,
    input  logic enable_i,

    output logic [SCORE_W-1:0] score_o,
    output logic done_o
);

integer i;
logic [SCORE_W-1:0] sum_next;

//
// Combinational population count
//
always_comb begin
    sum_next = '0;

    for (i = 0; i < SEQ_LENGTH; i = i + 1) begin
        if (compare_i[i]) begin
            sum_next = sum_next + 1'b1;
        end
    end
end

//
// Sequential output register
//
always_ff @(posedge clk_i) begin

    if (rst_i) begin
        score_o <= '0;
        done_o  <= 1'b0;
    end

    else if (enable_i) begin
        score_o <= sum_next;
        done_o  <= 1'b1;
    end

    else begin
        done_o <= 1'b0;
    end

end

endmodule



module ScoreAdder_COMB #(
    parameter SEQ_LENGTH = 100
)(
    input  logic [SEQ_LENGTH-1:0] compare_i,
    input  logic enable_i,
    input  logic rst_i,

    output logic [9:0] score_o,
    output logic done_o
);

integer i;

always_comb begin

    // default assignments
    score_o = 10'd0;
    done_o  = 1'b0;

    if (!rst_i && enable_i) begin

        done_o = 1'b1;

        for (i = 0; i < SEQ_LENGTH; i = i + 1) begin
            if (compare_i[i]) begin
                score_o = score_o + 10'd1;
            end
        end

    end
end

endmodule


module ScoreAdder_OOOOLD #(
    parameter SEQ_LENGTH = 100
)(
    input  logic [SEQ_LENGTH-1:0] compare_i,
    input  logic enable_i,

    output logic [9:0] score_o,
    output logic done_o
);

integer i;

always_comb begin

    score_o = '0;
    done_o  = 1'b0;

    if (enable_i) begin

        for (i = 0; i < SEQ_LENGTH; i++) begin
            score_o = score_o + compare_i[i];
        end

        done_o = 1'b1;
    end
end

endmodule

module ScoreAdder_old1 #(
    parameter SEQ_LENGTH = 100
)(
    input  logic [SEQ_LENGTH-1:0] compare_i,
    input  logic enable_i,

    output logic [9:0] score_o,
    output logic done_o
);

integer i;
logic [9:0] sum;

always_comb begin

    //----------------------------------------------------------
    // DEFAULTS
    //----------------------------------------------------------

    sum     = '0;
    score_o = '0;
    done_o  = 1'b0;

    //----------------------------------------------------------
    // COUNT MATCHES
    //----------------------------------------------------------

    if (enable_i) begin

        for (i = 0; i < SEQ_LENGTH; i++) begin
            if (compare_i[i]) begin
                sum = sum + 1;
            end
        end

        score_o = sum;
        done_o  = 1'b1;
    end
end

endmodule


module ScoreAdder_old #(
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

