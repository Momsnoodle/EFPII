module Main#(




)(
  input        MAX10_CLK1_50,  // 50 HMz clock
  input  [1:0] KEY,            // Buttons
  inout  [9:0] ARDUINO_IO,     // Header pins
  output [9:0] LEDR,           // LEDs
  input  [9:0] SW,             // Switches
  output [7:0] HEX0,           // 7-segment display
  output [7:0] HEX1,           // 7-segment display
  output [7:0] HEX2,           // 7-segment display
  output [7:0] HEX3,           // 7-segment display
  output [7:0] HEX4            // 7-segment display
);


logic [99:0] generated_sequence;

LFSR_Sequence_Generator seq_gen (
    .clk_i(clk_i),
    .rst_i(rst_i),
    .tick_i(tick_10ms),
    .enable_i(generate_enable),

    .sequence_o(generated_sequence),
    .done_o(sequence_done)
);


