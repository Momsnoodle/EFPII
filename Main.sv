logic [99:0] generated_sequence;

LFSR_Sequence_Generator seq_gen (
    .clk_i(clk_i),
    .rst_i(rst_i),
    .tick_i(tick_10ms),
    .enable_i(generate_enable),

    .sequence_o(generated_sequence),
    .done_o(sequence_done)
);


