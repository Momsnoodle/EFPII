
module LFSR_Sequence_Generator #(
    parameter SEQ_LENGTH = 100,
    parameter LFSR_WIDTH = 16,
    parameter MULTIPLIER = 10 // tick fast divided tick slow
)(
    input  logic clk_i,
    input  logic rst_i,
    input  logic tick_i,

    // Start generation
    input  logic enable_i,

    // Generated random sequence
    output logic [SEQ_LENGTH-1:0] sequence_o,

    // Indicates sequence generation finished
    output logic done_o
);

    //============================================================
    // Internal signals
    //============================================================

    // LFSR register
    logic [LFSR_WIDTH-1:0] lfsr_q;

    // Feedback bit
    logic feedback;

    // Counts generated bits
    logic [$clog2(SEQ_LENGTH):0] bit_counter_q;

    logic [$clog2(MULTIPLIER + 1)-1:0] mult_cnt;

    //============================================================
    // Feedback taps
    // Primitive polynomial:
    // x^16 + x^14 + x^13 + x^11 + 1
    //============================================================

    assign feedback =
        lfsr_q[15] ^
        lfsr_q[13] ^
        lfsr_q[12] ^
        lfsr_q[10];

    //============================================================
    // Main logic
    //============================================================

always_ff @(posedge clk_i) begin

    if (rst_i) begin

        lfsr_q        <= 16'hACE1;
        sequence_o    <= '0;
        bit_counter_q <= '0;
        done_o        <= 1'b0;
        mult_cnt      <= '0;

    end

    else if (tick_i && enable_i && !done_o) begin

        if (mult_cnt == MULTIPLIER-1) begin

            sequence_o <= {
                sequence_o[SEQ_LENGTH-2:0],
                feedback
            };

            lfsr_q <= {
                lfsr_q[LFSR_WIDTH-2:0],
                feedback
            };

            mult_cnt <= '0;

            if (bit_counter_q == SEQ_LENGTH-1) begin
                done_o <= 1'b1;
            end
            else begin
                bit_counter_q <= bit_counter_q + 1;
            end

        end
        else begin

            mult_cnt <= mult_cnt + 1;

        end
    end
end

endmodule

