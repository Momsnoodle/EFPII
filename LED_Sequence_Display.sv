module LED_Sequence_Display #(
    parameter SEQ_LENGTH = 100
)(
    input  logic clk_i,
    input  logic rst_i,

    // playback speed tick
    input  logic tick_i,

    // enable playback
    input  logic enable_i,

    // sequence to display
    input  logic [SEQ_LENGTH-1:0] sequence_i,

    // LED output
    output logic led_o,

    // playback finished
    output logic done_o
);

    //------------------------------------------------------------
    // Playback index
    //------------------------------------------------------------

    logic [$clog2(SEQ_LENGTH):0] index_q;

    //------------------------------------------------------------
    // Playback logic
    //------------------------------------------------------------

    always_ff @(posedge clk_i) begin

        if (rst_i) begin

            index_q <= '0;
            done_o  <= 1'b0; // 1 bit binary set to 0
            led_o   <= 1'b0;

        end

        else if (enable_i && tick_i && !done_o) begin

            //----------------------------------------------------
            // Display current sequence bit
            //----------------------------------------------------

            led_o <= sequence_i[SEQ_LENGTH-1-index_q];

            //----------------------------------------------------
            // Advance playback
            //----------------------------------------------------

            if (index_q == SEQ_LENGTH-1) begin

                done_o <= 1'b1;

            end

            else begin

                index_q <= index_q + 1;

            end

        end

        //--------------------------------------------------------
        // Reset playback when disabled
        //--------------------------------------------------------

        else if (!enable_i) begin

            index_q <= '0;
            done_o  <= 1'b0;
            led_o   <= 1'b0;

        end

    end

endmodule