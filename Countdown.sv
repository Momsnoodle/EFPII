module Countdown_old #(
    parameter START_VALUE = 10'b0000000010, // 2 in binary
    parameter SCORE_W = 10
)(
    input  logic clk_i,
    input  logic rst_i,

    // enable counting
    input  logic start_i,

    // slow tick (e.g. 1 Hz)
    input  logic tick_i,

    // current displayed value
    output logic [SCORE_W-1:0] value_o, 

    // high when finished
    output logic done_o

);

    logic [SCORE_W-1:0] counter_q;

    always_ff @(posedge clk_i) begin

        if (rst_i) begin
            counter_q <= START_VALUE;
            done_o   <= 1'b0;
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
            done_o    <= 1'b0;
        end

    end

    assign value_o = counter_q;

endmodule



module Countdown_older #(
    parameter SCORE_W = 10
)(
    input  logic               clk_i,
    input  logic               rst_i,
    input  logic               start_i,
    input  logic [SCORE_W-1:0] start_value_i, // Receives 3 or 5 from the FSM
    input  logic               tick_i,
    output logic [SCORE_W-1:0] value_o,       // Driven directly inside always_ff
    output logic               done_o
);

    logic start_prev;
    // =========================================================
    // COUNTER CORE LOGIC
    // =========================================================
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            value_o <= '0;
            done_o  <= 1'b0;
        end 
        // When the FSM asserts start_i, instantly load the target value (3 or 5)
        else if (start_i && !start_prev) begin
            start_prev <= 1; 
            value_o <= start_value_i; 
            done_o  <= 1'b0;
        end 
        // On every countdown tick pulse, decrement the counter down to 0
        else if (tick_i && value_o > '0) begin
            if (value_o == {{SCORE_W-1{1'b0}}, 1'b1}) begin
                value_o <= '0;
                done_o  <= 1'b1; // Alert the FSM that the countdown finished
            end else begin
                // Using 1'b1 instead of an integer 1 prevents 32-bit truncation warnings
                value_o <= value_o - 1'b1; 
            end
        end
    end


endmodule

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

module Countdown_GPT #(
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

    // previous value of start_i
    logic start_prev_q;

    always_ff @(posedge clk_i) begin

        if (rst_i) begin

            value_o      <= '0;
            done_o       <= 1'b0;
            start_prev_q <= 1'b0;

        end
        else begin

            // store previous start state
            start_prev_q <= start_i;

            // default
            done_o <= 1'b0;

            // detect rising edge of start_i
            if (start_i && !start_prev_q) begin

                value_o <= start_value_i;

            end

            // countdown logic
            else if (tick_i && value_o > 0) begin

                if (value_o == 1) begin

                    value_o <= 0;
                    done_o  <= 1'b1;

                end
                else begin

                    value_o <= value_o - 1'b1;

                end
            end
        end
    end

endmodule