module Button_Input #(
    parameter integer DEBOUNCE_MAX = 100_000
)(
    input  logic clk_i,
    input  logic rst_i,

    // Raw pushbutton input
    input  logic button_i,

    // 1-clock pulse on valid press
    output logic pressed_o
);

    //------------------------------------------------------------
    // Synchronizer
    //------------------------------------------------------------

    logic button_sync_0;
    logic button_sync_1;

    always_ff @(posedge clk_i) begin
        button_sync_0 <= button_i;
        button_sync_1 <= button_sync_0;
    end

    //------------------------------------------------------------
    // Debounce counter
    //------------------------------------------------------------

    logic [$clog2(DEBOUNCE_MAX)-1:0] counter_q;

    logic button_stable_q;
    logic button_prev_q;

    always_ff @(posedge clk_i) begin

        if (rst_i) begin
            counter_q       <= '0;
            button_stable_q <= 1'b0;
            button_prev_q   <= 1'b0;
            pressed_o       <= 1'b0;
        end

        else begin

            //----------------------------------------------------
            // Default pulse low
            //----------------------------------------------------

            pressed_o <= 1'b0;

            //----------------------------------------------------
            // Debounce logic
            //----------------------------------------------------

            if (button_sync_1 != button_stable_q) begin

                counter_q <= counter_q + 1;

                if (counter_q == DEBOUNCE_MAX-1) begin
                    button_stable_q <= button_sync_1;
                    counter_q       <= '0;
                end

            end

            else begin
                counter_q <= '0;
            end

            //----------------------------------------------------
            // Rising edge detect
            //----------------------------------------------------

            button_prev_q <= button_stable_q;

            if (!button_prev_q && button_stable_q) begin
                pressed_o <= 1'b1;
            end

        end
    end

endmodule


module Button_Sequence_Capture_old #(
    parameter SEQ_LENGTH = 100
)(
    input  logic clk_i,
    input  logic rst_i,

    // Sampling tick
    input  logic tick_i,

    // Enable capture
    input  logic enable_i,

    // Raw button
    input  logic button_i,

    // Captured sequence
    output logic [SEQ_LENGTH-1:0] sequence_o,

    // Finished capture
    output logic done_o
);

    //------------------------------------------------------------
    // Counter
    //------------------------------------------------------------

    logic [$clog2(SEQ_LENGTH):0] bit_counter_q;

    //------------------------------------------------------------
    // Main logic
    //------------------------------------------------------------

    always_ff @(posedge clk_i) begin



        if (rst_i) begin

            sequence_o    <= '0;
            bit_counter_q <= '0;
            done_o        <= '0;

        end

        else if (tick_i && enable_i && !done_o) begin

            //----------------------------------------------------
            // Shift sampled button into sequence
            //----------------------------------------------------

            sequence_o <= {
                sequence_o[SEQ_LENGTH-2:0],
                button_i
            };

            //----------------------------------------------------
            // Count samples
            //----------------------------------------------------

            bit_counter_q <= bit_counter_q + 1;

            //----------------------------------------------------
            // Finish after SEQ_LENGTH samples
            //----------------------------------------------------

            if (bit_counter_q == SEQ_LENGTH-1) begin
                done_o <= 1'b1;
            end

        end
    end

endmodule




module Button_Sequence_Capture #(
    parameter SEQ_LENGTH = 100
)(
    input  logic clk_i,
    input  logic rst_i,

    input  logic tick_i,
    input  logic enable_i,

    input  logic button_i,

    output logic [SEQ_LENGTH-1:0] sequence_o,
    output logic done_o
);

    logic [$clog2(SEQ_LENGTH):0] bit_counter_q;

    // remembers whether button was pressed
    logic button_seen_q;

    always_ff @(posedge clk_i) begin

        if (rst_i) begin

            sequence_o    <= '0;
            bit_counter_q <= '0;
            done_o        <= 1'b0;
            button_seen_q <= 1'b0;

        end
        else if (enable_i && !done_o) begin

            //----------------------------------------------------
            // Accumulate button presses
            //----------------------------------------------------

            if (button_i) begin
                button_seen_q <= 1'b1; 
            end

            //----------------------------------------------------
            // Sample once per tick
            //----------------------------------------------------

            if (tick_i) begin

                sequence_o <= {
                    sequence_o[SEQ_LENGTH-2:0],
                    button_seen_q
                };

                // clear accumulator for next interval
                button_seen_q <= 1'b0;

                bit_counter_q <= bit_counter_q + 1;

                if (bit_counter_q == SEQ_LENGTH-1) begin
                    done_o <= 1'b1;
                end
            end
        end
    end

endmodule