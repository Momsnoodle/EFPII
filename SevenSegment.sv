/*
    7-segment decoder for a single digit
    designed for the Terasic DE10-Lite board
    
    Yves Acremann, 3.1.2021
    Pol Welter, 2022-03-15
*/ 

module SevenSegment(    
    input unsigned [3:0]    number_i,
    output logic [6:0]      LED_o
    );
    
    always_comb
    begin
        case(number_i)
            4'b0000: LED_o = 7'b1000000;
            4'b0001: LED_o = 7'b1111001;
            4'b0010: LED_o = 7'b0100100;
            4'b0011: LED_o = 7'b0110000;
            4'b0100: LED_o = 7'b0011001;
            4'b0101: LED_o = 7'b0010010;   
            4'b0110: LED_o = 7'b0000010;
            4'b0111: LED_o = 7'b1111000;    
            4'b1000: LED_o = 7'b0000000;
            4'b1001: LED_o = 7'b0010000;    
            4'b1010: LED_o = 7'b0100000;
            4'b1011: LED_o = 7'b0000011;
            4'b1100: LED_o = 7'b1000110;
            4'b1101: LED_o = 7'b0100001;
            4'b1110: LED_o = 7'b0000110;
            4'b1111: LED_o = 7'b0001110;    
            default: LED_o = 7'b1111111;
        endcase
    end    
endmodule
