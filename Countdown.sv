
module Countdown #(
    parameter SCORE_W = 10
)(
    input  logic               clk_i,
    input  logic               rst_i,
    input  logic               start_i,
    input  logic [SCORE_W-1:0] start_value_i,
    input  logic               tick_i,

    output logic [SCORE_W-1:0] value_o,
    output logic               done_o
);

    logic running_q;

    always_ff @(posedge clk_i) begin

        if (rst_i) begin
            value_o   <= 0;
            done_o    <= 0;
            running_q <= 0;
        end

        else begin

            done_o <= 0;

            // START (only once)
            if (start_i && !running_q) begin
                value_o   <= start_value_i;
                running_q <= 1;
            end

            // COUNTDOWN
            else if (running_q && tick_i) begin

                if (value_o == 0) begin
                    done_o    <= 1;
                    running_q <= 0;
                end
                else begin
                    value_o <= value_o - 1;
                end
            end
        end
    end

endmodule
