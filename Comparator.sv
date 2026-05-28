
module Comparator #(
    parameter SEQ_LENGTH = 100
)(
    input  logic clk_i,
    input  logic rst_i,

    input  logic [SEQ_LENGTH-1:0] seq_a_i,
    input  logic [SEQ_LENGTH-1:0] seq_b_i,
    input  logic enable_i,

    output logic [SEQ_LENGTH-1:0] result_o,
    output logic done_o
);

    // ---------------------------------------------------------
    // Edge detection for enable (prevents multiple evaluations)
    // ---------------------------------------------------------
    logic enable_d;

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            result_o <= '0;
            done_o   <= 1'b0;
            enable_d <= 1'b0;
        end else begin
            // track previous enable
            enable_d <= enable_i;

            // rising edge detect: start computation once
            if (enable_i && !enable_d) begin
                result_o <= ~(seq_a_i ^ seq_b_i); // bitwise match vector
                done_o   <= 1'b1;
            end else begin
                done_o <= 1'b0;
            end
        end
    end

endmodule