
module MemoryGameStateMachine #(
    parameter SCORE_W = 10, // Score between 0 and SEQ_W, change
    parameter SEQ_W = 100,
    parameter OVER_SAMPLING = 10
)(
    input logic clk_i,

    input logic reset_or_begin_i,
    input logic button_i,

    input logic tick_fast,
    input logic tick_slow,
    input logic tick_countdown,
   

    //output logic [6:0] display0_o,
    //output logic [6:0] display1_o,
    //output logic [6:0] display2_o,
    //output logic [6:0] display3_o,

    output logic led_o,
    output logic unsigned [SCORE_W-1:0] score,
    output logic unsigned [SCORE_W-1:0] countdown_value,
    output logic start_countdown

);

    // =========================================================
    // STATE MACHINE
    // =========================================================

    typedef enum logic [2:0] { // initialize 6 states, need 3 bits
        IDLE,
        GENERATION,
        DISPLAY,
        COUNTDOWN,
        PLAYING,
        SCORING,
        ENDGAME
    } state_e;

    typedef struct packed { // make a packed state variable with the logic states, the score and the seqences (stored in registers then)
        state_e state;
        logic [SCORE_W-1:0] score;
        logic [SEQ_W-1:0] seq_gen;
        logic [SEQ_W-1:0] seq_in;
    } state_t;

    state_t state_out, state_in; // same as state_q, state_d convention

    // =========================================================
    // INTERNAL SIGNALS
    // =========================================================

    logic [SEQ_W-1:0] generated_sequence;
    logic seq_done;

    logic [SEQ_W-1:0] player_sequence;
    logic player_done;

    logic display_done;

    logic [SEQ_W-1:0] num_correct;
    logic compare_done;
    logic [SCORE_W-1:0] calculated_score;

    logic [1:0] countdown_out; //2 bit for 3,2,1,0
    logic countdown_done;
    //logic start_countdown;

    logic score_done;


    assign start_countdown = (state_out.state == COUNTDOWN); //1 if COUNTDOWN, 0 ELSE
    

    // Instantiate the modules with the proper input 

    // =========================================================
    // LFSR, generate the random sequence
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
    // BUTTON CAPTURE, captures the input of the button_i i.e. the player sequence
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
    // COUNTDOWN, displays a countdown 3...2...1... before the display and the player input
    // =========================================================

    Countdown #(
        .START_VALUE(2'b10)
    ) countdown_inst (
        .clk_i(clk_i),
        .rst_i(reset_or_begin_i),
        .start_i(start_countdown),
        .tick_i(tick_countdown),
        .value_o(countdown_out), // the current countdown value
        .done_o(countdown_done)
    );

    // =========================================================
    // LED SEQUENCE DISPLAY, displays the generated seqence via the LED
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
    // COMPARATOR + SCORE, compares the sequences, generates a sequence with the matches and adds this up to generate a score. MAX SCORE == SEQ_W
    // =========================================================

    Comparator #(
        .SEQ_LENGTH(SEQ_W)
    ) comparator_inst (
        .clk_i(clk_i),
        .rst_i(reset_or_begin_i),
        .enable_i(state_out.state == SCORING),
        .seq_a_i(state_out.seq_gen),
        .seq_b_i(state_out.seq_in),
        .result_o(num_correct),
        .done_o(compare_done)
    );

    

    ScoreAdder #(
    .SEQ_LENGTH(SEQ_W),
    .SCORE_W(SCORE_W)
    ) adder_inst (
    .clk_i(clk_i),
    .rst_i(reset_or_begin_i),
    .compare_i(num_correct),
    .enable_i(state_out.state == SCORING && compare_done),
    .score_o(calculated_score),
    .done_o(score_done)
    );

    always_ff @(posedge clk_i) begin

        if (reset_or_begin_i && state_in.state != IDLE) begin //set all things to 0 
            state_out.state   <= IDLE;
            state_out.score   <= '0;
            state_out.seq_gen <= '0;
            state_out.seq_in  <= '0;
            

            ///SHOULD DO THIS INSIDE OF THE SUBMODULES!!! --> BY SENDING THE RESET
            //player_done <= '0;
            //display_done <= '0;
            //compare_done <= '0;
            //score_done <= '0;
            //calculated_score <= '0;
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
            if (reset_or_begin_i)begin // start the game
                state_in.state = GENERATION;
            end
        end

        
        GENERATION: begin
            state_in.seq_gen = generated_sequence; //always running will be random therefore 
            if (seq_done) begin
                state_in.state = DISPLAY;
            end
        end

       
        DISPLAY: begin // will already start the display since the enable signal of the LED_Sequence_Display is on
             if (reset_or_begin_i) begin
                state_in.state = IDLE;
             end
            else if (display_done) begin
                state_in.state = COUNTDOWN;
            end
        end

        COUNTDOWN: begin
            if (reset_or_begin_i) begin
                state_in.state = IDLE;
            end
            
            else if (countdown_done) begin
                state_in.state = PLAYING;
            end

        end

        
        PLAYING: begin // will turn on enable_i of Button_Sequence_Capture
           if (reset_or_begin_i) begin
                state_in.state = IDLE;
           end
           else if (player_done) begin
                state_in.state = SCORING;
           end
           state_in.seq_in = player_sequence; // fill the generated sequence into the packed state

        end

        SCORING: begin
            if (reset_or_begin_i) begin
                state_in.state = IDLE;
            end
            else if (score_done) begin
              state_in.state = ENDGAME;
            end
            state_in.score = calculated_score;
            
        end

        ENDGAME: begin // will stay here forever unless one resets the game.
            if (reset_or_begin_i) begin
                state_in.state = IDLE;
            end
            //score = state_out.score;
            
        end
    
        default: begin
            state_in.state = IDLE;
        end

        endcase

    end

    assign score = state_out.score;  //1 if COUNTDOWN, 0 ELSE
    assign countdown_value = countdown_out;


endmodule


