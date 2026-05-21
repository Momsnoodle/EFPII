module Countdown #(
    parameter integer START_VALUE = 3
)(
    input  logic clk_i,
    input  logic rst_i,

    // enable counting
    input  logic start_i,

    // slow tick (e.g. 1 Hz)
    input  logic tick_i,

    // current displayed value
    output logic [$clog2(START_VALUE+1)-1:0] value_o,

    // high when finished
    output logic done_o
);

    logic [$clog2(START_VALUE+1)-1:0] counter_q;

    always_ff @(posedge clk_i) begin

        if (rst_i) begin
            counter_q <= START_VALUE;
            done_o    <= 0';
        end

        else if (start_i) begin

            if (!done_o && tick_i) begin

                if (counter_q == 0) begin
                    done_o <= 1'b1;
                end
                else begin
                    counter_q <= counter_q - 1;
                end

            end

        end

        else begin
            // reset when not active
            counter_q <= START_VALUE;
            done_o    <= 0'b0;
        end

    end

    assign value_o = counter_q;

endmodule