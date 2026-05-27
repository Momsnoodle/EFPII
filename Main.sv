module Main #(
  parameter DIVIDER_LEN = 5000000,
  parameter SCORE_W = 10, // such that 2**SCORE_W > SEQ_LENGTH
  parameter DIGITS_N = 5, // what is this supposed to be ???
  parameter DIGITS_BCD_W = 4, // what is this supposed to be ???
  parameter OVERSAMPLING = 5,
  parameter OVERSAMPLING_COUNTDOWN = 10,
  parameter SEQ_W = 5 // defines the length of the game --> SEQ_LENGTH * tick_slow = game_time
)(
  input  logic        MAX10_CLK1_50,
  input  logic [1:0]  KEY,
  output logic [9:0]  LEDR,
  input  logic [9:0]  SW, // first switch is the start game switch !!!
  output logic [7:0]  HEX5,
  output logic [7:0]  HEX0,
  output logic [7:0]  HEX1,
  output logic [7:0]  HEX2,
  output logic [7:0]  HEX3,
  output logic [7:0]  HEX4
);

  // =========================================================
  // CLOCK 
  // =========================================================

  logic clk;
  logic reset;
  logic led_o;
  logic led_o_test;

  assign clk = MAX10_CLK1_50;
  //assign led_test = 1;
  //assign LEDR[0] = led_o; 
  //assign LEDR[1] = led_test;

//always_ff @(posedge clk) begin // this will let it blink --> the tick is only on for one clk every --> for me to check if someting is running
 //   if (tick_countdown) begin
  //      LEDR[1] <= ~LEDR[1]; // will hold the state after one tick until the next tick will turn it off!
  //  end
//end

  // =========================================================
  // TICKS
  // =========================================================

  logic tick_fast; //one ClK on with a repetition given by the tick divider
  logic tick_slow;
  logic tick_countdown;
  
  logic tick_fast_stay; //will stay on for one full cycle of the tick and then turn off for one full cycle
  logic tick_slow_stay;
  logic tick_countdown_stay;
  
  TickGen #(.DIVIDER(DIVIDER_LEN), .REG_W(32)) tick_fast_gen (
    .clk_i(clk),
    .reset_i(button_clean[0]),
    .tick_o(tick_fast)
  );

  TickGen #(.DIVIDER(OVERSAMPLING*DIVIDER_LEN), .REG_W(32)) tick_slow_gen (
    .clk_i(clk),
    .reset_i(button_clean[0]),
    .tick_o(tick_slow)
  );

  TickGen #(.DIVIDER(OVERSAMPLING_COUNTDOWN*DIVIDER_LEN), .REG_W(32)) tick_countdown_gen (
    .clk_i(clk),
    .reset_i(button_clean[0]),
    .tick_o(tick_countdown)
  );



//Control the game sequence work properly...
always_ff @(posedge clk) begin // this will let it blink --> the tick is only on for one clk every --> for me to check if someting is running
    if (tick_countdown) begin
        tick_countdown_stay <= ~tick_countdown_stay; // will hold the state after one tick until the next tick will turn it off!
    end

     if (tick_countdown_stay) begin
        LEDR[2] <= 1; // will hold the state after one tick until the next tick will turn it off!
    end
    else begin
        LEDR[2] <= 0; // will hold the state after one tick until the next tick will turn it off!
    end

    if(seq_done && !display_done)begin // will turn on LED5 once the sequence has been generated, works
    LEDR[5]<= 1;
    end
    else begin
      LEDR[5]<= 0;
    end
    if(start_countdown)begin //works too
    LEDR[7]<= 1;
    end
    else begin
      LEDR[7]<= 0;
    end

    if(start_countdown)begin //works too
    LEDR[7]<= 1;
    end
    else begin
      LEDR[7]<= 0;
    end
    if(display_done)begin
    LEDR[6]<= 1;
    end
    else begin
      LEDR[6]<= 0;
    end

    if(state != 0)begin // checks if the game actually starts and goes from IDLE into GENERATION
      LEDR[9]<= 1;
    end
    else begin
      LEDR[9]<= 0;
    end

     if(led_o)begin // checks if the game actually starts and goes from IDLE into GENERATION
      LEDR[0]<= 1;
    end
    else begin
      LEDR[0]<= 0;
    end

end
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
        .reset_i(button_clean[0]),
        .bouncing_i(!KEY[i]),
        .debounced_o(debounced)
      );

      Oneshot os (
        .clk_i(clk),
        .reset_i(button_clean[0]),
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
  logic start_countdown;
  logic [2:0] state;
  logic seq_done;
  logic display_done;
  logic countdown_done;

  BinBCD #(
    .BINARY_W(SCORE_W),
    .DIGITS_N(DIGITS_N),
    .DIGITS_BCD_W(DIGITS_BCD_W)
  ) binBcd_score (
    .clk_i(clk),
    .reset_i(button_clean[0]),
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
    .reset_i(button_clean[0]),
    .start_i(tick_fast),
    .binary_i(countdown_value),
    .bcd_o(bcd_countdown),
    .enable_i(start_countdown) // display it only if this is on
  );


  SevenSegment digit0_countdown(bcd_countdown[0], HEX5[6:0]);
  assign HEX5[7] = 1'b1;

  SevenSegment digit0(bcd_score[0], HEX0[6:0]);
  assign HEX0[7] = 1'b1; // assign them but never change them actually

  SevenSegment digit1(bcd_score[1], HEX1[6:0]);
  assign HEX1[7] = 1'b1;

  SevenSegment digit2(bcd_score[2], HEX2[6:0]);
  assign HEX2[7] = 1'b0;

  SevenSegment digit3(bcd_score[3], HEX3[6:0]);
  assign HEX3[7] = 1'b1;

  SevenSegment digit4(bcd_score[4], HEX4[6:0]);
  assign HEX4[7] = 1 ;



  // =========================================================
  // FSM
  // =========================================================

  MemoryGameStateMachine #(
    .SCORE_W(SCORE_W),
    .SEQ_W(SEQ_W),
    .OVER_SAMPLING(OVERSAMPLING)
  ) memoryStateMachine (
    .clk_i(clk),
    .reset_i(button_clean[0]),
    .start_i(SW[0]),
    .button_i(button_clean[1]),

    .tick_fast(tick_fast),
    .tick_slow(tick_slow),
    .tick_countdown(tick_countdown),
    .led_o(led_o),
    .led_o_test(led_o_test),
    .score(score),
    .countdown_value(countdown_value),
    .start_countdown(start_countdown),
    .state_output(state),
    .seq_done(seq_done),
    .display_done(display_done),
    .countdown_done(countdown_done)
  );

endmodule


