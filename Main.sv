module Main #(
  parameter DIVIDER_LEN = 5000000,
  parameter SCORE_W = 10, // such that 2**SCORE_W > SEQ_LENGTH
  parameter DIGITS_N = 5, // what is this supposed to be ???
  parameter DIGITS_BCD_W = 4, // what is this supposed to be ???
  parameter OVERSAMPLING = 5,
  parameter OVERSAMPLING_COUNTDOWN = 10,
  parameter SEQ_W = 100 // defines the length of the game --> SEQ_LENGTH * tick_slow = game_time
)(
  input  logic        MAX10_CLK1_50,
  input  logic [1:0]  KEY,
  output logic [9:0]  LEDR,
  input  logic [9:0]  SW,
  output logic [7:0]  HEX5,
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

  logic [2:0] current_state_num;

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

  TickGen #(.DIVIDER(DIVIDER_LEN), .REG_W(32)) tick_fast_gen (
    .clk_i(clk),
    .reset_i(reset),
    .tick_o(tick_fast)
  );

  TickGen #(.DIVIDER(OVERSAMPLING*DIVIDER_LEN), .REG_W(32)) tick_slow_gen (
    .clk_i(clk),
    .reset_i(reset),
    .tick_o(tick_slow)
  );

  TickGen #(.DIVIDER(OVERSAMPLING_COUNTDOWN*DIVIDER_LEN), .REG_W(32)) tick_countdown_gen (
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

  logic [SCORE_W-1:0] score;
  logic [DIGITS_BCD_W-1:0] bcd_score [DIGITS_N-1:0];
  logic [DIGITS_BCD_W-1:0] bcd_countdown [DIGITS_N-1:0];
  logic [SCORE_W-1:0] countdown_value; // good states are always 00,01,10, but 11 is too much
  logic enable_countdown;


  BinBCD #(
    .BINARY_W(SCORE_W),
    .DIGITS_N(DIGITS_N),
    .DIGITS_BCD_W(DIGITS_BCD_W)
  ) binBcd_score (
    .clk_i(clk),
    .reset_i(reset),
    .start_i(tick_fast),
    .binary_i(score),
    .bcd_o(bcd_score),
    .enable_i(score != '0) // display it only if this is on
  );


BinBCD #(
    .BINARY_W(SCORE_W),
    .DIGITS_N(DIGITS_N),
    .DIGITS_BCD_W(DIGITS_BCD_W)
) binBcd_countdown (
    .clk_i(clk),
    .reset_i(reset),
    .start_i(tick_fast),
    .binary_i(countdown_value),
    .bcd_o(bcd_countdown),
    .enable_i(enable_countdown) // display it only if this is on
  );


  SevenSegment digit0_countdown(bcd_countdown[0], HEX5[6:0]);
  assign HEX5[7] = 1'b1;

  SevenSegment digit0(bcd_score[0], HEX0[6:0]);
  assign HEX0[7] = 1'b1;

  SevenSegment digit1(bcd_score[1], HEX1[6:0]);
  assign HEX1[7] = 1'b1;

  SevenSegment digit2(bcd_score[2], HEX2[6:0]);
  assign HEX2[7] = 1'b0;

  SevenSegment digit3(bcd_score[3], HEX3[6:0]);
  assign HEX3[7] = 1'b1;

  SevenSegment digit4(bcd_score[4], HEX4[6:0]);
  assign HEX4[7] = 1'b1;

  // =========================================================
  // FSM
  // =========================================================

  logic game_led;
  // =========================================================
    // STATE MACHINE INSTANTIATION
    // =========================================================
    MemoryGameStateMachine #(
        .SCORE_W(10),
        .SEQ_W(100)
    ) memoryStateMachine (
        .clk_i(clk),
        
        // If your FSM reset is active-LOW (ends in _n_i), invert your active-high pulse:
        .system_rst_n_i(~button_clean[1]), 
        
        // If your FSM reset is active-HIGH, just pass it directly:
        // .system_rst_i(button_clean[1]), 

        .game_start_i(button_clean[0]),   // Hook up your clean KEY[0] pulse here!
        .button_i(SW[0]), 
        .tick_fast(tick_fast),         
        .tick_slow(tick_slow),
        .tick_countdown(tick_countdown),
        .led_o(game_led), 
        .score(current_score),         
        .countdown_value(current_countdown),
        .start_countdown(start_countdown_trigger),

        .state_number_o(current_state_num) // NEW: Connect the diagnostic wire
    );


  // MemoryGameStateMachine #(
  //   .SCORE_W(SCORE_W),
  //   .SEQ_W(SEQ_W),
  //   .OVER_SAMPLING(OVERSAMPLING)
  // ) memoryStateMachine (
  //   .clk_i(clk),
  //   .reset_or_begin_i(button_clean[0]),
  //   .button_i(button_clean[1]),

  //   .tick_fast(tick_fast),
  //   .tick_slow(tick_slow),
  //   .tick_countdown(tick_countdown),

  //   //.display0_o(digit0),
  //   //.display1_o(digit1),
  //  // .display2_o(digit2),
  //  // .display3_o(digit3),

  //   //.display0_o(digit0_value), // 7 bits long
  //   //.display1_o(digit1_value),
  //   //.display2_o(digit2_value),
  //   //.display3_o(digit3_value),
    
  //   .led_o(LEDR[0]),
  //   .score(score),
  //   .countdown_value(countdown_value),
  //   .start_countdown(enable_countdown)
  // );
  // =========================================================
  // DIAGNOSTIC STATE DASHBOARD
  // =========================================================
  // Create an internal bus just for the diagnostic states
  logic [8:0] diagnostic_leds;

  always_comb begin
      // Default all 9 diagnostic tracks to 0
      diagnostic_leds = 9'b0; 
      
      // Turn on exactly one tracking bit matching our state number (0 to 7)
      diagnostic_leds[current_state_num] = 1'b1;
  end

  // Concatenate: bits 9 down to 1 get the diagnostics, bit 0 gets the gameplay pulse!
  assign LEDR = {diagnostic_leds, game_led};

endmodule


