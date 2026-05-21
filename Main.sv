module Main #(
  parameter DIVIDER_LEN = 5000000,
  parameter SCORE_W_W = 16,
  parameter DIGITS_N = 5,
  parameter DIGITS_BCD_W = 4,
  parameter OVERSAMPLING = 5,
  parameter SEQ_LENGTH = 100
)(
  input  logic        MAX10_CLK1_50,
  input  logic [1:0]  KEY,
  output logic [9:0]  LEDR,
  input  logic [9:0]  SW,
  output logic [7:0]  HEX0,
  output logic [7:0]  HEX1,
  output logic [7:0]  HEX2,
  output logic [7:0]  HEX3,
  output logic [7:0]  HEX4
);

  // =========================================================
  // CLOCK + RESET
  // =========================================================

  logic clk;
  logic reset;

  assign clk = MAX10_CLK1_50;

  ResetGenerator resetGenerator (
    .clk_i(clk),
    .reset_o(reset)
  );

  // =========================================================
  // TICKS
  // =========================================================

  logic tick_fast;
  logic tick_slow;
  logic tick_countdown;

  TickGen #(.DIVIDER(DIVIDER_LEN), .REG_W(24)) tick_fast_gen (
    .clk_i(clk),
    .reset_i(reset),
    .tick_o(tick_fast)
  );

  TickGen #(.DIVIDER(OVERSAMPLING*DIVIDER_LEN), .REG_W(24)) tick_slow_gen (
    .clk_i(clk),
    .reset_i(reset),
    .tick_o(tick_slow)
  );

  TickGen #(.DIVIDER(10*DIVIDER_LEN), .REG_W(24)) tick_countdown_gen (
    .clk_i(clk),
    .reset_i(reset),
    .tick_o(tick_countdown)
  );

  // =========================================================
  // BUTTONS (debounce + oneshot)
  // =========================================================

  logic [1:0] button_clean;

  genvar i;
  generate
    for (i = 0; i < 2; i++) begin : BTN

      logic debounced;

      Debouncer #(.COUNT_LEN(DIVIDER_LEN)) db (
        .clk_i(clk),
        .reset_i(reset),
        .bouncing_i(!KEY[i]),
        .debounced_o(debounced)
      );

      Oneshot os (
        .clk_i(clk),
        .reset_i(reset),
        .in_i(debounced),
        .pulse_o(button_clean[i])
      );

    end
  endgenerate

  // =========================================================
  // SCORE DISPLAY (BinBCD + 7seg)
  // =========================================================

  logic [SCORE_W_W-1:0] score;
  logic [DIGITS_N-1:0][3:0] bcd;

  BinBCD #(
    .BINARY_W(SCORE_W_W),
    .DIGITS_N(DIGITS_N),
    .DIGITS_BCD_W(DIGITS_BCD_W)
  ) binBcd (
    .clk_i(clk),
    .reset_i(reset),
    .start_i(tick_fast),
    .binary_i(score),
    .bcd_o(bcd)
  );

  SevenSegment digit0(bcd[0], HEX0[6:0]);
  assign HEX0[7] = 1'b1;

  SevenSegment digit1(bcd[1], HEX1[6:0]);
  assign HEX1[7] = 1'b1;

  SevenSegment digit2(bcd[2], HEX2[6:0]);
  assign HEX2[7] = 1'b0;

  SevenSegment digit3(bcd[3], HEX3[6:0]);
  assign HEX3[7] = 1'b1;

  SevenSegment digit4(bcd[4], HEX4[6:0]);
  assign HEX4[7] = 1'b1;

  // =========================================================
  // FSM
  // =========================================================

  MemoryGameStateMachine #(
    .SCORE_W(SCORE_W_W),
    .SEQ_W(SEQ_LENGTH),
    .OVER_SAMPLING(OVERSAMPLING)
  ) memoryStateMachine (
    .clk_i(clk),
    .reset_or_begin_i(button_clean[0]),
    .button_i(button_clean[1]),

    .tick_fast(tick_fast),
    .tick_slow(tick_slow),
    .tick_countdown(tick_countdown),

    .display0_o(),
    .display1_o(),
    .display2_o(),
    .display3_o(),

    .led_o(LEDR[0]),
    .score(score)
  );

endmodule





"""


module Main#(
  parameter DIVIDER_LEN = 5000000;
  parameter SCORE_W_W = 16;
  parameter DIGITS_N = 5;
  parameter DIGITS_BCD_W = 4;
  parameter OVERSAMPLING = 5;
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

  logic unsigned [1:0] stm_in_debounced;
  logic unsigned [1:0] stm_in; //button pressed
  
  //logic unsigned [TIMER_W-1:0] timer;
/ logic unsigned [SCORE_W-1:0] score;

  logic unsigned [DIGITS_BCD_W -1:0] bcd [DIGITS_N-1:0];

  // Signal assignment
  assign clk = MAX10_CLK1_50;
  
  // output sequence over LED:
  //assign LEDR[9:0] = [0]; 

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
  TickGen #(.DIVIDER(OVERSAMPLING*DIVIDER_LEN),.REG_W(24)) tickGen_slow (
    .clk_i  (clk),
    .reset_i(reset),
    .tick_o (tick_slow)
  );


    // generate the tick for random generated sequence (one pulse every 1 s)
  TickGen #(.DIVIDER(10*DIVIDER_LEN),.REG_W(24)) tickGen_countdown (
    .clk_i  (clk),
    .reset_i(reset),
    .tick_o (tick_countdown)
  );

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

  // let's also use the 7-segment display:
  BinBCD #(.BINARY_W(TIMER_W), .DIGITS_N(DIGITS_N), .DIGITS_BCD_W(DIGITS_BCD_W)) binBcd(
    .clk_i(clk),
    .reset_i(reset),
    .start_i(tick_fast),
    .binary_i(score),
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


  // TODO: the state machine for the game:

MemoryGameStateMachine #(
        .SCORE_W(16), // or whatever length we need
        .SEQ_LENGTH(100)
        .OVER_SAMPLING(OVERSAMPLING)
) memoryStateMachine (
        .clk_i(clk_i),
        .reset_or_begin_i(stm_in[0]),
        .button_i(stm_in[1]),
        .display0_o(digit0),
        .display1_o(digit1),
        .display2_o(digit2),
        .display3_o(digit3),
        .led_o(LEDR[0]), 
        .tick_fast(tick_fast),
        .tick_slow(tick_slow),
        .tick_countdown(tick_countdown),
        .score(score)
    );

    //------------------------------------------------------------
    // Connect output
    //------------------------------------------------------------


endmodule

"""