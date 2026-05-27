
module MemoryGameStateMachine #(
    parameter SCORE_W = 10, // Score between 0 and SEQ_W, change
    parameter SEQ_W = 100,
    parameter OVER_SAMPLING = 10
)(
    input  logic               clk_i,
    input  logic               system_rst_n_i, // NEW: Active-low global reset 
    input  logic               game_start_i,   // NEW: Clean edge pulse to start game
    input  logic               button_i,
    input  logic               tick_fast,
    input  logic               tick_slow,
    input  logic               tick_countdown,
    output logic               led_o,
    output logic [SCORE_W-1:0] score,
    output logic [SCORE_W-1:0] countdown_value,
    output logic               start_countdown,
    output logic [2:0]         state_number_o

);

    // =========================================================
    // STATE MACHINE
    // =========================================================

   // =========================================================
    // STATE MACHINE TYPE DEFINITIONS
    // =========================================================
    typedef enum logic [2:0] { 
        IDLE,
        PRE_COUNTDOWN,  // New: 3, 2, 1 before the sequence shows
        GENERATION,
        DISPLAY,
        POST_COUNTDOWN, // New: 5, 4, 3, 2, 1 during player input
        PLAYING,
        SCORING,
        ENDGAME
    } state_e;

    typedef struct packed { 
        state_e state;
        logic [SCORE_W-1:0] score;
        logic [SEQ_W-1:0] seq_gen;
        logic [SEQ_W-1:0] seq_in;
    } state_t;

    state_t state_out, state_in;
    
    // Internal signal to pass the starting count dynamically
    logic [SCORE_W-1:0] countdown_start_value;

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

    logic [SCORE_W-1:0] countdown_out; //2 bit for 3,2,1,0
    logic countdown_done;
    //logic start_countdown;

    logic score_done;


    // NEW CORRECTED LINE
    assign start_countdown = (state_out.state == PRE_COUNTDOWN || state_out.state == POST_COUNTDOWN);
    

    // Instantiate the modules with the proper input 

    // =========================================================
    // LFSR, generate the random sequence
    // =========================================================

    LFSR_Sequence_Generator #(
        .SEQ_LENGTH(SEQ_W),
        .LFSR_WIDTH(16),
        .MULTIPLIER(OVER_SAMPLING)
    ) lfsr_inst (
        .clk_i(clk_i),
        .rst_i(!system_rst_n_i),
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
        .rst_i(!system_rst_n_i),
        .tick_i(tick_fast),
        .enable_i(state_out.state == PLAYING),
        .button_i(button_i),
        .sequence_o(player_sequence),
        .done_o(player_done)
    );

    // =========================================================
    // COUNTDOWN, displays a countdown 3...2...1... before the display and the player input
    // =========================================================

    // Countdown Module with dynamic start value input
    Countdown #(
        .SCORE_W(SCORE_W)
    ) countdown_inst (
        .clk_i(clk_i),
        .rst_i(!system_rst_n_i),
        .start_i(start_countdown), 
        .start_value_i(countdown_start_value), // Dynamic input (3 or 5)
        .tick_i(tick_countdown),
        .value_o(countdown_out), 
        .done_o(countdown_done)
    );

    // =========================================================
    // LED SEQUENCE DISPLAY, displays the generated seqence via the LED
    // =========================================================

    LED_Sequence_Display #(
        .SEQ_LENGTH(SEQ_W)
    ) led_display_inst (
        .clk_i(clk_i),
        .rst_i(!system_rst_n_i),
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
        .rst_i(!system_rst_n_i),
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
    .rst_i(!system_rst_n_i),
    .compare_i(num_correct),
    .enable_i(state_out.state == SCORING && compare_done),
    .score_o(calculated_score),
    .done_o(score_done)
    );


    always_ff @(posedge clk_i) begin
        if (!system_rst_n_i) begin // If reset goes low, force FSM back to IDLE
            state_out.state <= IDLE;
            state_out.score <= '0;
            state_out.seq_gen <= '0;
            state_out.seq_in <= '0;
        end else begin
            state_out <= state_in;
        end
    end

    always_comb begin
        // Default assignments
        state_in = state_out;
        countdown_start_value = '0; 

        case (state_out.state)

            IDLE: begin
                if (game_start_i) begin // Use the new dedicated game start trigger
                    state_in.state = PRE_COUNTDOWN; // Or GENERATION depending on your FSM setup
                end
            end
            
            PRE_COUNTDOWN: begin
                countdown_start_value = 'd3; // Set initial countdown to 3 seconds
                if (countdown_done) begin
                    state_in.state = GENERATION;
                end
            end
            
            GENERATION: begin
                state_in.seq_gen = generated_sequence; 
                if (seq_done) begin
                    state_in.state = DISPLAY;
                end
            end
           
            DISPLAY: begin 
                if (display_done) begin
                    state_in.state = POST_COUNTDOWN; // Go to the 5s input countdown
                end
            end

            POST_COUNTDOWN: begin
                countdown_start_value = 'd5; // Set player input countdown to 5 seconds
                if (countdown_done) begin
                    // If 5 seconds run out before player completes input, force end game/scoring
                    state_in.state = SCORING; 
                end else if (player_done) begin
                    state_in.state  = SCORING;
                    state_in.seq_in = player_sequence;
                end
            end

            SCORING: begin
                if (score_done) begin
                    state_in.state = ENDGAME;
                end
                state_in.score = calculated_score;
            end

            ENDGAME: begin
                if (game_start_i) begin
                    state_in.state = IDLE;
                end
            end
        
            default: begin
                state_in.state = IDLE;
            end
        endcase
    end

    assign score = state_out.score;  //1 if COUNTDOWN, 0 ELSE
    assign countdown_value = countdown_out;

    // NEW: Automatically converts the enum state into its 0-7 numeric value
    assign state_number_o = state_out.state;


endmodule


