module BinBCD #(
  parameter BINARY_W= 16,
  parameter DIGITS_N = 5,  
  parameter DIGITS_BCD_W = 4 
  )(
  input         clk_i,
  input         reset_i,
  input         start_i,
  input unsigned [BINARY_W-1:0] binary_i,
  input logic enable_i,
  
  //output unsigned [DIGITS_BCD_W-1:0] bcd_o  ????

  output logic [DIGITS_BCD_W-1:0] bcd_o [DIGITS_N-1:0]
  );

  logic unsigned [DIGITS_N*DIGITS_BCD_W+ BINARY_W-1 : 0] scratch_q, scratch_next_d, scratch_add;
  typedef enum logic [1:0] {
    WAIT_START,
    SHIFT,
    ADD,
    WAIT_START_LOW
  } state_e;
  
  state_e state_q, state_next_d;
  
  // We add an additional register at the output such that it only
  // changes once the conversion is done.
  logic unsigned [DIGITS_N*DIGITS_BCD_W-1:0] output_reg_q, output_reg_next_d;
  logic unsigned [4:0] bit_counter_q, bit_counter_next_d;
  
  // The registers:
  always_ff @(posedge clk_i) begin
    if (reset_i) begin
      scratch_q     <= 0;
      state_q       <= WAIT_START;
      bit_counter_q <= 0;
      output_reg_q   <= 0;
    end else begin
      scratch_q     <= scratch_next_d;
      state_q       <= state_next_d;
      bit_counter_q <= bit_counter_next_d;
      output_reg_q   <= output_reg_next_d;
    end
  end // always_ff
  
  
  // the next state logic:
  always_comb begin
    // default: do nothing.
    state_next_d       = state_q;
    bit_counter_next_d = bit_counter_q;
    scratch_next_d     = scratch_q;
    output_reg_next_d  = output_reg_q;
    
    if (enable_i) begin
    // initialize the scratch pad and wait for start
    if (state_q == WAIT_START) begin
      scratch_next_d[BINARY_W-1:0] = binary_i[BINARY_W-1:0];
      scratch_next_d[BINARY_W -1 + DIGITS_BCD_W*DIGITS_N:BINARY_W] = 0;
      bit_counter_next_d = 0;
      if (start_i) state_next_d = SHIFT;
    end
    
    
    // do a bit shift to the left and go to end it we are done. Otherwise: go to 'ADD'
    if (state_q == SHIFT) begin
      bit_counter_next_d = bit_counter_q + 1;
      scratch_next_d[DIGITS_BCD_W*DIGITS_N+BINARY_W-1:1] = scratch_q[DIGITS_BCD_W*DIGITS_N+BINARY_W-2:0];
      scratch_next_d[0] = 0;
      state_next_d = ADD;
      
      // check if we are done:
      if (bit_counter_q == 15) state_next_d = WAIT_START_LOW;
    end
     
      
    // add 3 to all digits > 4. Afterwards: go to 'SHIFT'.
    // This needs to be done below; this is ugly in SystemVerilog:
    // We can not use generate inside a always_comb block!
    if (state_q == ADD) begin
      // use the result of the block below:
      scratch_next_d = scratch_add;
      state_next_d = SHIFT;
    end
      
    // when done : Update the output register and wait for the start signal to become '0'
    if (state_q == WAIT_START_LOW) begin
      output_reg_next_d[DIGITS_BCD_W*DIGITS_N-1 : 0] = scratch_q[DIGITS_N*DIGITS_BCD_W+BINARY_W-1 : BINARY_W];
      if (!start_i) state_next_d = WAIT_START;
    end

    end
    
  end // always_comb
  
  
  // add the decoder for the add stage:
  // add 3 to all digits > 4.
  // This new block is caused by an ugly feature of SystemVerilog:
  // we can not use generate inside an always_comb block!
  genvar i;
  generate
    for (i = 0;  i < DIGITS_N; i++) begin: loop // somehow Quartus wants to have a label here!
      always_comb begin
        if (scratch_q[DIGITS_BCD_W*DIGITS_N+BINARY_W-1-i*DIGITS_BCD_W : DIGITS_BCD_W*DIGITS_N+BINARY_W-1-(i+1)*DIGITS_BCD_W+1] > DIGITS_BCD_W) begin
          scratch_add[DIGITS_BCD_W*DIGITS_N+BINARY_W-1-i*DIGITS_BCD_W : DIGITS_BCD_W*DIGITS_N+BINARY_W-1-(i+1)*DIGITS_BCD_W+1]
            = scratch_q[DIGITS_BCD_W*DIGITS_N+BINARY_W-1-i*DIGITS_BCD_W : DIGITS_BCD_W*DIGITS_N+BINARY_W-1-(i+1)*DIGITS_BCD_W+1] + 3;
        end else begin
          scratch_add[DIGITS_BCD_W*DIGITS_N+BINARY_W-1-i*DIGITS_BCD_W : DIGITS_BCD_W*DIGITS_N+BINARY_W-1-(i+1)*DIGITS_BCD_W+1] 
            = scratch_q[DIGITS_BCD_W*DIGITS_N+BINARY_W-1-i*DIGITS_BCD_W: DIGITS_BCD_W*DIGITS_N+BINARY_W-1-(i+1)*DIGITS_BCD_W+1];
        end 
      end // always_comb

    // connect the output to the output register
      assign bcd_o[i][DIGITS_BCD_W -1 : 0] = output_reg_q[ DIGITS_BCD_W*i+DIGITS_BCD_W-1 :  DIGITS_BCD_W*i];
    end // for
  endgenerate
  assign scratch_add[BINARY_W-1:0] = scratch_q[BINARY_W-1:0]; // assign the remaining bits
  
endmodule