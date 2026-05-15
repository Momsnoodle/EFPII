/*
 This is a one-shot unit: Once the input becomes '1', the output is
 '1' for exactly one clock cycle.
 
 Pol Welter, 2022-03-14
*/

module Oneshot(
    input logic clk_i,
    input logic reset_i,
    input logic in_i,
    output logic pulse_o
  );
  
  //Your code comes here
  logic state_q;
  logic state_d;
  logic state_dd;


  always @(posedge clk_i) begin
    if (reset_i) begin
      state_q <= 0;
    end else begin
      state_q <= in_i ? 1 : 0; // If in_i is 1, move to state 1; otherwise, stay in state 0
    end
  end
  
  always @(posedge clk_i) begin
    if (reset_i) begin
      state_d <= 0;
    end else begin
      state_d <= state_q ? 1 : 0; // If in_i is 1, move to state 1; otherwise, stay in state 0
    end
  end

  always @(posedge clk_i) begin
    if (reset_i) begin
      state_dd <= 0;
    end else begin
      state_dd <= state_d ? 1 : 0; // If in_i is 1, move to state 1; otherwise, stay in state 0
    end
  end

  always_comb begin
    pulse_o = state_d && !state_dd; // Output is 1 when we transition from state 0 to state 1
  end

endmodule



