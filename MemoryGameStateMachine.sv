
module MemoryGameStateMachine #(
    parameter SCORE_W = 16,
    parameter SEQ_W = 100,
    parameter OVER_SAMPLING = 10
)(
    input logic clk_i,
    input logic reset_or_begin_i,
    input logic tick_fast,
    input logic tick_slow,
    input logic tick_countdown,
    input logic button_i,

    output logic [6:0] display0_o,
    output logic [6:0] display1_o,
    output logic [6:0] display2_o,
    output logic [6:0] display3_o,

    output logic led_o,
    output logic unsigned [SCORE_W-1:0] score
);

    // =========================================================
    // STATE MACHINE
    // =========================================================

    typedef enum logic [2:0] {
        IDLE,
        GENERATION,
        DISPLAY,
        COUNTDOWN,
        PLAYING,
        SCORING
    } state_e;

    typedef struct packed {
        state_e state;
        logic [SCORE_W-1:0] score;
        logic [SEQ_W-1:0] seq_gen;
        logic [SEQ_W-1:0] seq_in;
    } state_t;

    state_t state_out, state_in;

    // =========================================================
    // INTERNAL SIGNALS
    // =========================================================

    logic [SEQ_W-1:0] generated_sequence;
    logic seq_done;

    logic [SEQ_W-1:0] player_sequence;
    logic player_done;

    logic display_done;

    logic [SEQ_W-1:0] matches;
    logic [SCORE_W-1:0] calculated_score;

    logic [1:0] countdown_out;
    logic countdown_done;
    logic start_countdown;

    assign start_countdown = (state_out.state == COUNTDOWN);

    // =========================================================
    // LFSR
    // =========================================================

    LFSR_Sequence_Generator #(
        .SEQ_LENGTH(SEQ_W),
        .LFSR_WIDTH(16)
    ) lfsr_inst (
        .clk_i(clk_i),
        .rst_i(reset_or_begin_i),
        .tick_i(tick_slow),
        .enable_i(state_out.state == GENERATION),
        .sequence_o(generated_sequence),
        .done_o(seq_done)
    );

    // =========================================================
    // BUTTON CAPTURE
    // =========================================================

    Button_Sequence_Capture #(
        .SEQ_LENGTH(SEQ_W)
    ) button_capture_inst (
        .clk_i(clk_i),
        .rst_i(reset_or_begin_i),
        .tick_i(tick_fast),
        .enable_i(state_out.state == PLAYING),
        .button_i(button_i),
        .sequence_o(player_sequence),
        .done_o(player_done)
    );

    // =========================================================
    // COUNTDOWN
    // =========================================================

    Countdown #(
        .START_VALUE(3)
    ) countdown_inst (
        .clk_i(clk_i),
        .rst_i(reset_or_begin_i),
        .start_i(start_countdown),
        .tick_i(tick_countdown),
        .value_o(countdown_out),
        .done_o(countdown_done)
    );

    // =========================================================
    // LED SEQUENCE DISPLAY
    // =========================================================

    LED_Sequence_Display #(
        .SEQ_LENGTH(SEQ_W)
    ) led_display_inst (
        .clk_i(clk_i),
        .rst_i(reset_or_begin_i),
        .tick_i(tick_fast),
        .enable_i(state_out.state == DISPLAY),
        .sequence_i(state_out.seq_gen),
        .led_o(led_o),
        .done_o(display_done)
    );

    // =========================================================
    // COMPARATOR + SCORE
    // =========================================================

    Comparator #(
        .SEQ_LENGTH(SEQ_W)
    ) comparator_inst (
        .seq_a_i(state_out.seq_gen),
        .seq_b_i(state_out.seq_in),
        .result_o(matches)
    );

    ScoreAdder #(
        .SEQ_LENGTH(SEQ_W),
        .SCORE_W(SCORE_W)
    ) adder_inst (
        .compare_i(matches),
        .score_o(calculated_score)
    );



    always_ff @(posedge clk_i) begin

        if (reset_or_begin_i) begin
            state_out.state   <= IDLE;
            state_out.score   <= '0;
            state_out.seq_gen <= '0;
            state_out.seq_in  <= '0;
        end
        else begin
            state_out <= state_in;
        end

        

    end

  

    always_comb begin

        // defaults 
        state_in = state_out;

        case (state_out.state)

        IDLE: begin
            if (reset_or_begin_i)
                state_in.state = GENERATION;
        end

        
        GENERATION: begin
            state_in.seq_gen = generated_sequence;

            if (seq_done)
                state_in.state = DISPLAY;
        end

       
        DISPLAY: begin
            if (display_done)
                state_in.state = COUNTDOWN;
        end

        COUNTDOWN: begin

            if (reset_or_begin_i)
                state_in.state = IDLE;

            else if (countdown_done)
                state_in.state = PLAYING;

        end

        
        PLAYING: begin

            state_in.seq_in = player_sequence;

            if (player_done)
                state_in.state = SCORING;

        end

        SCORING: begin

            state_in.score = calculated_score;

            state_in.state = IDLE;

        end

        default: begin
            state_in.state = IDLE;
        end

        endcase

    end

    assign score = state_out.score;

endmodule


"""
module MemoryGameStateMachine #(
    parameter SCORE_W = 16, // bit depth of the score
    parameter SEQ_W = 100, // how many bits we need for the random sequence
    parameter OVER_SAMPLING = 10 // how much faster the fast tick is compared to the slow tick

  )(  
    input logic clk_i,
    input logic reset_or_begin_i, // reset button and start button is the same
    input logic tick_fast, // fast tick
    input logic tick_slow, // slow tick
    input logic tick_countdown, // countdown tick
    input logic button_i, // signal from button to input the sequence
    
    output logic [6:0] display0_o,
    output logic [6:0] display1_o,
    output logic [6:0] display2_o,
    output logic [6:0] display3_o,



    output logic led_o,

    output logic unsigned [SCORE_W-1:0] score  // the score output
  );
  
  typedef enum logic [2:0] { // 5 states so i need 3 bits
    IDLE,   // wait for the player to start the game
    GENERATION,  // generate the random sequence, write it to RAM 
    DISPLAY, // display the previously generated sequence
    PLAYING,   // store the sequence which the player is pressing
    COUNTDOWN, // countdown 3 seconds and display this
    SCORING // compare the two sequences and calculate the score, display it when finished
  } state_e;

 typedef struct packed { // pack the states into one called state_t...
    state_e state;
    logic unsigned [SCORE_W-1:0] score;
    logic unsigned [SEQ_W-1:0] seq_gen;
    logic unsigned [SEQ_W-1:0] seq_in;
  } state_t;
    
  state_t state_out, state_in; // declare two variables (flip-flop in, flip-flop out) of type state_t i.e. the packed typedef



    // Signals connected to LFSR module
    logic [SEQ_W-1:0] generated_sequence;
    logic seq_done;

    // LFSR module instantiation

    LFSR_Sequence_Generator #(
        .SEQ_LENGTH(SEQ_W),
        .LFSR_WIDTH(16)
    ) lfsr_inst (
        .clk_i(clk_i),
        .rst_i(reset_or_begin_i),
        .tick_i(tick_slow),
        .enable_i(state_out.state == GENERATION),
        .sequence_o(generated_sequence),
        .done_o(seq_done)
    );

//instatiate the button in module
logic [SEQ_W-1:0] player_sequence;
logic player_done;
Button_Sequence_Capture #( 
    .SEQ_LENGTH(SEQ_W)
) button_capture_inst (
    .clk_i(clk_i),
    .rst_i(reset_or_begin_i),
    .tick_i(tick_fast),
    .enable_i(state_out.state == PLAYING),
    .button_i(button_i),
    .sequence_o(player_sequence),
    .done_o(player_done)
);


// instantiate the countdown 
//logic [1:0] countdown_out;  // enough for 0–3
logic [1:0] start_countdown ;
logic [1:0] countdown_out;
logic countdown_done;
assign start_countdown = (state_out.state == COUNTDOWN);

Countdown #(
    .START_VALUE(3)
) countdown_inst (
    .clk_i(clk_i),
    .rst_i(reset_or_begin_i),
    .start_i(start_countdown),
    .tick_i(tick_countdown),
    .value_o(display0_o),
    .done_o(countdown_done)
);

logic display_done; // 1 bit, 1 if done

LED_Sequence_Display #(
    .SEQ_LENGTH(SEQ_W)
) led_display_inst (
    .clk_i(clk_i),
    .rst_i(reset_or_begin_i),

    .tick_i(tick_fast),
    .enable_i(state_out.state == DISPLAY),

    .sequence_i(state_out.seq_gen),

    .led_o(led_o),
    .done_o(display_done)
);


logic [SEQ_W-1:0] matches;

Comparator #(
    .SEQ_LENGTH(SEQ_W)
) comparator_inst (
    .seq_a_i(state_out.seq_gen),
    .seq_b_i(state_out.seq_in),

    .result_o(matches)
);


logic [SCORE_W-1:0] calculated_score;
ScoreAdder #(
    .SEQ_LENGTH(SEQ_W),
    .SCORE_W(SCORE_W)
) adder_inst (
    .compare_i(matches),
    .score_o(calculated_score)
);

  always_ff @(posedge clk_i) begin

    if (reset_or_begin_i && (state_out.state != IDLE)) begin
        state_out.state <= IDLE;
        state_out.score <= SCORE_W'(0);
        state_out.seq_gen <= SEQ_W'(0);
        state_out.seq_in <= SEQ_W'(0);
    end

    else if (reset_or_begin_i && (state_out.state == IDLE)) begin
        state_out.state <= GENERATION;
    end

    else begin
        state_out <= state_in;
    end

    if (rreset_or_begin_i) begin
        countdown_out <= 0;
    end
    else if (state_out.state == COUNTDOWN && tick_countdown) begin
        countdown_out <= countdown_out + 1;
    end
    else if (state_out.state != COUNTDOWN) begin
        countdown_out <= 0;
    end

  end
  
  // next state logic
  always_comb begin
    // defaults:
    state_in.state   = state_out.state;
    state_in.score= state_out.score;
    state_in.seq_gen= state_out.seq_gen;
    state_in.seq_in= state_out.seq_in;


    case(state_out.state)
      IDLE: begin
        if (reset_or_begin_i) begin //reset
            state_in.state = GENERATION;
            state_in.score = SCORE_W'(0);
        end
      end
		
    GENERATION: begin

    if (reset_or_begin_i) begin
        state_in.state = IDLE;
    end

    else begin
        state_in.seq_gen = generated_sequence;
        if (seq_done) begin
            state_in.state = COUNTDOWN;
        end
    end

    end
      
  DISPLAY: begin

    if (display_done)
        state_in.state = COUNTDOWN;

  end


  PLAYING: begin
    if (reset_or_begin_i) begin
        state_in.state = IDLE;
        end
    else begin
      state_in.seq_in = player_sequence;
    if (player_done)
        state_in.state = SCORING;
    end
  end

   COUNTDOWN: begin

    if (reset_or_begin_i) begin
        state_in.state = IDLE;
    end

    else if (countdown_out == 2'd3 &&
         display_done == 0) begin

    state_in.state = DISPLAY;

    end

    else if (countdown_out == 2'd3 &&
         display_done == 1) begin

    state_in.state = PLAYING;

    end

    end
    
    SCORING: begin

       if (reset_or_begin_i) begin
        state_in.state = IDLE;
      end
        
      state_in.score = calculated_score;

  end
      
  
  default: state_in.state = IDLE; // it's always a good idea to add this!
    
    
    endcase
  
  end
  // the output
  assign score = state_out.score;

endmodule

"""
