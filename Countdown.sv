module Countdown #(
    parameter SCORE_W = 10
)(
    input  logic               clk_i,
    input  logic               rst_i,
    input  logic               start_i,
    input  logic [SCORE_W-1:0] start_value_i, // Receives 3 or 5 from the FSM
    input  logic               tick_i,
    output logic [SCORE_W-1:0] value_o,       // Driven directly inside always_ff
    output logic               done_o
);

    // =========================================================
    // COUNTER CORE LOGIC
    // =========================================================
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            value_o <= '0;
            done_o  <= 1'b0;
        end 
        // When the FSM asserts start_i, instantly load the target value (3 or 5)
        else if (start_i) begin
            value_o <= start_value_i; 
            done_o  <= 1'b0;
        end 
        // On every countdown tick pulse, decrement the counter down to 0
        else if (tick_i && value_o > '0) begin
            if (value_o == {{SCORE_W-1{1'b0}}, 1'b1}) begin
                value_o <= '0;
                done_o  <= 1'b1; // Alert the FSM that the countdown finished
            end else begin
                // Using 1'b1 instead of an integer 1 prevents 32-bit truncation warnings
                value_o <= value_o - 1'b1; 
            end
        end
    end


endmodule