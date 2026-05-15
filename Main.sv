module Main#(
  parameter DIVIDER_LEN = 5000000;
  parameter TIMER_W = 16;
  parameter DIGITS_N = 5;
  parameter DIGITS_BCD_W = 4;



)(
  input        MAX10_CLK1_50,  // 50 HMz clock
  input  [1:0] KEY,            // Buttons
  output [9:0] LEDR,           // LEDs
  input  [9:0] SW,             // Switches
  output [7:0] HEX0,           // 7-segment display
  output [7:0] HEX1,           // 7-segment display
  output [7:0] HEX2,           // 7-segment display
  output [7:0] HEX3,           // 7-segment display
  output [7:0] HEX4            // 7-segment display
);

  // Signal definition
  logic tick_fast;
  logic tick_slow;
  logic clk;
  logic reset;

  // stm_in_debounced[0]:  start_stop_debounced
  // stm_in_debounced[1]:  clear_hold_debounced
  logic unsigned [1:0] stm_in_debounced;
  
  //stm_in[0]  start-stop button strobe
  //stm_in[1]  clear-hold button strobe
  logic unsigned [1:0] stm_in; 
  
  logic unsigned [TIMER_W-1:0] timer;
  logic unsigned [DIGITS_BCD_W -1:0] bcd [DIGITS_N-1:0];

  // Signal assignment
  assign clk = MAX10_CLK1_50;
  // output clock over LEDs:
  assign LEDR[9:0] = timer[9:0];

  // Generate a reset pulse on power-up
  ResetGenerator resetGenerator (
    .clk_i  (clk),
    .reset_o(reset)
  );

  // generate the tick for input sequence (one pulse every 100 ms)
  TickGen #(.DIVIDER(DIVIDER_LEN),.REG_W(24)) tickGen_fast (
    .clk_i  (clk),
    .reset_i(reset),
    .tick_o (tick_fast)
  );

  // generate the tick for random generated sequence (one pulse every 500 ms)
  TickGen #(.DIVIDER(5*DIVIDER_LEN),.REG_W(24)) tickGen_slow (
    .clk_i  (clk),
    .reset_i(reset),
    .tick_o (tick_slow)
  );

  // logic [99:0] generated_sequence;

  // LFSR_Sequence_Generator seq_gen (
  //     .clk_i(clk_i),
  //     .rst_i(rst_i),
  //     .tick_i(tick_10ms),
  //     .enable_i(generate_enable),

  //     .sequence_o(generated_sequence),
  //     .done_o(sequence_done)
  // );


  genvar i; 
  generate
    for(i=0; i < 2; i++) begin: generate_debouncer_oneshot

      Debouncer #(.COUNT_LEN(DIVIDER_LEN)) debounce(
        .clk_i(clk),
        .reset_i(reset),
        .bouncing_i(!KEY[i]),  // buttons are active-low
        .debounced_o(stm_in_debounced[i])
      );

      Oneshot oneshot(
        .clk_i(clk),
        .reset_i(reset),
        .in_i(stm_in_debounced[i]),
        .pulse_o(stm_in[i])
      );
      // TODO: if the current button is the play button and the current state is the play state, save the button state in a register
    end

  endgenerate


  // TODO: the state machine for the game:


  // let's also use the 7-segment display:
  BinBCD #(.BINARY_W(TIMER_W), .DIGITS_N(DIGITS_N), .DIGITS_BCD_W(DIGITS_BCD_W)) binBcd(
    .clk_i(clk),
    .reset_i(reset),
    .start_i(tick_2),
    .binary_i(timer),
    .bcd_o(bcd)
  );

  // 7-segment display
  // drive the correct LEDs:
  SevenSegment digit0(bcd[0], HEX0[6:0]);
  assign HEX0[7] = 1; // turn dot off
  
  SevenSegment digit1(bcd[1], HEX1[6:0]);
  assign HEX1[7] = 1;
  
  SevenSegment digit2(bcd[2], HEX2[6:0]);
  assign HEX2[7] = 0; // turn dot on
  
  SevenSegment digit3(bcd[3], HEX3[6:0]);
  assign HEX3[7] = 1;
  
  SevenSegment digit4(bcd[4], HEX4[6:0]);
  assign HEX4[7] = 1;

endmodule


