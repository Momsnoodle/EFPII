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
  
  logic [2:0] sync_reg_q;
  always_ff @(posedge clk_i) begin
    if (reset_i)
      sync_reg_q <= 3'b000;
    else begin
      sync_reg_q[2] <= in_i;            // FF1 (metastability possible)
      sync_reg_q[1] <= sync_reg_q[2];   // FF2 (synchronizer)
      sync_reg_q[0] <= sync_reg_q[1];   // FF3 (edge detection delay)
    end
  end
  
  assign pulse_o = sync_reg_q[1] & !sync_reg_q[0];
endmodule
