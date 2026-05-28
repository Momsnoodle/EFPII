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