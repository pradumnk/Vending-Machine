module vending_machine_topmodule(CLOCK_50, KEY, SW, LEDG, HEX0, HEX1, HEX2, HEX3, LEDR);
  input CLOCK_50;
  input [2:0] KEY;
  input [7:0] SW;
  output [7:0] LEDG;
  output [6:0] HEX0, HEX1, HEX2, HEX3;
  output [3:0] LEDR;
  

  wire [11:0] money;
  wire clk;
  wire btnC,btnR,btnL;
  wire btnCclk,btnLclr,btnRclr;

  // Let us ignore debounce for a while .... assume that the coin-drop mechanism does not need debounce
  //debounce dbnC(clk,btnC,btnCclr);
  //debounce dbnR(clk,btnR,btnRclr);
  //debounce dbnL(clk,btnL,btnLclr);

  wire [3:0] thos,huns,tens,ones;
  assign btnC = KEY[2];
  assign btnR = KEY[0];
  assign btnL = KEY[1];
  //assign clk = CLOCK_50;
  
  clkdown use1 (CLOCK_50, clk);
  vending_machine vm( .clk(clk), .coin1(btnR), .coin2(btnL), .select(SW[3:0]), .buy(btnC),
                      .load(SW[7:4]), .money(money), .products(LEDG[3:0]), .outofstock(LEDG[7:4]));
    // notice the port mapping using named-association ( rather than position-based-association )
    //   the "dot" notation , as in ,  "  .port_name ( signal_name ) "  says connect the signal to the port 
    // btnR is connected to coin1 port, btnL to coin2 port, btnC is connected to "buy" port
    // 4 LSBs of sw[7:0] are connected to 4 bits of "select" port ( which selects which item to buy )
    // 4 MSBs of sw[7:0] are connected to 4 bits of "load" port ( indicating which items are to be re-stocked )
    // 12-bit wide "money" signal is connected to "money" port of this instance of vending_machine  module
    // the 4 LSBs of led[7:0] are for indicating which item 
    // the 4 MSBs of led[7:0] are for which item are out of stock

  binarytoBCD bcd1(money,thos,huns,tens,ones);
    // EXERCISE : explain the role of the signals connected to ports of the above instance of module binarytoBCD.
  
  decoder_7seg inst0 (ones, HEX0);
  decoder_7seg inst1 (tens, HEX1);
  decoder_7seg inst2 (huns, HEX2);
  decoder_7seg inst3 (thos, HEX3);
  //sevenseg_driver seg1( .clk(clk), .clr(1'b0), .in1(thos), .in2(huns), .in3(tens), .in4(ones), .seg(HEX0), .an(LEDR));
    // EXERCISE : explain the role of the signals connected to ports of the above instance of module sevenseg_driver.
      
      // output port "seg[6:0]" shows the 7 bit 7-segment code for one of the 4 digit at a time ....
           // it is for "debug" facility
         //  the 7 leds of 7-segment are usually referred to as a,b,c,d,e,f ( clockwise from top-horizontal-led ) 
             // and then followed by "g" ( the middle-horizontal-led )
         // seg[6] means led-g , seg[5] means led-f .... seg[0] means led-a
      // output port "an[3:0]" indicates in active-low manner, which of the 4-seven-segment is being shown on seg[6:0]
           // it is for "debug" facility
         // an[i]=0 means 7-segment code for the i^th digit is being shown on seg[6:0]
endmodule


module vending_machine(clk,coin1,coin2,select,buy,load,money,products,outofstock);
  // EXERCISE : explain the logic of vending machine 

  input clk;
  input coin1; //25 cents
  input coin2; //1 dollar (100 cents)
  input [3:0] select;
  input buy;
  input [3:0] load;
  output reg [11:0] money=0;
  output reg [3:0] products=0;
  output reg [3:0] outofstock=0;

  reg coin1_prev,coin2_prev;
  reg buy_prev;

  reg [3:0] stock1=4'b1111;
  reg [3:0] stock2=4'b1111;
  reg [3:0] stock3=4'b1111;
  reg [3:0] stock4=4'b1111;

  always @ (posedge clk) begin
    coin1_prev <= coin1; coin2_prev <= coin2; buy_prev <= buy;

    if (coin1_prev == 1'b0 && coin1 == 1'b1) money <= money + 12'd25;
    else if (coin2_prev == 1'b0 && coin2 == 1'b1) money <= money + 12'd100;
    else if (buy_prev == 1'b0 && buy == 1'b1)  begin
      case (select)
        4'b0001: 
          if (money >= 12'd25 && stock1 > 0) begin
	    products[0] <= 1'b1; stock1 <= stock1 - 1'b1; money <= money - 12'd25;
	  end
        4'b0010:
          if (money >= 12'd75 && stock2 > 0) begin
            products[1] <= 1'b1; stock2 <= stock2 - 1'b1; money <= money - 12'd75;
          end
        4'b0100:
          if (money >= 12'd150 && stock3 > 0) begin
            products[2] <= 1'b1; stock3 <= stock3 - 1'b1; money <= money - 12'd150;
          end
        4'b1000:
          if (money >= 12'd200 && stock4 > 0) begin
            products[3] <= 1'b1; stock4 <= stock4 - 1'b1; money <= money - 12'd200;
          end
      endcase
    end

    else if (buy_prev == 1'b1 && buy == 1'b0) begin
      products[0] <= 1'b0; products[1] <= 1'b0; products[2] <= 1'b0;    products[3] <= 1'b0;
    end

    else begin
		
      if (stock1 == 4'b0) outofstock[0] <= 1'b1; else outofstock[0] <= 1'b0;
      if (stock2 == 4'b0) outofstock[1] <= 1'b1; else outofstock[1] <= 1'b0;
      if (stock3 == 4'b0) outofstock[2] <= 1'b1; else outofstock[2] <= 1'b0;
      if (stock4 == 4'b0) outofstock[3] <= 1'b1; else outofstock[3] <= 1'b0;

      case (load)
        4'b0001: stock1 <= 4'b1111;
        4'b0010: stock2 <= 4'b1111;
        4'b0100: stock3 <= 4'b1111;
        4'b1000: stock4 <= 4'b1111;
      endcase
    end
  end

endmodule


  // IGNORE debounce for this homework-1 of Lec-1
module debounce(clk,btn,btn_clr);

  input clk;
  input btn;
  output reg btn_clr;

  parameter delay = 650000; //6.5ms delay
  integer count=0;

  reg xnew=0;

  always @(posedge clk) begin
    if (btn != xnew) begin 
      xnew <= btn; count <= 0; 
    end
    else if (count == delay) btn_clr <= xnew;
    else count <= count + 1;
  end 

endmodule


module binarytoBCD(binary,thos,huns,tens,ones);
  // EXERCISE : explain the functionality of binarytoBCD.  Model it using VHDL.

  input [11:0] binary;
  output reg [3:0] thos, huns, tens, ones;

  reg [11:0] bcd_data=0;

  always @ (binary) begin
    bcd_data = binary;
    thos = bcd_data / 1000;
    bcd_data = bcd_data % 1000;
    huns = bcd_data / 100;
    bcd_data = bcd_data % 100;
    tens = bcd_data / 10;
    ones = bcd_data % 10;
  end

endmodule


module sevenseg_driver(clk,clr,in1,in2,in3,in4,seg,an);

  input clk;
  input clr;
  input [3:0] in1, in2, in3, in4;
  output reg [6:0] seg = 7'b0;
  output reg [3:0] an = 4'b0;

  wire [6:0] seg1, seg2, seg3, seg4;
  reg [12:0] segclk = 12'b0;

  localparam LEFT = 2'b00, MIDLEFT = 2'b01, MIDRIGHT = 2'b10, RIGHT = 2'b11;
  reg [1:0] state=LEFT;

  decoder_7seg disp1(in1,seg1);
  decoder_7seg disp2(in2,seg2);
  decoder_7seg disp3(in3,seg3);
  decoder_7seg disp4(in4,seg4);
    
  always @ (posedge clk) segclk <= segclk + 1'b1;

  //always @(posedge segclk[12] or posedge clr) begin
  always @(posedge segclk[2] or posedge clr) begin
    if (clr == 1) begin
      seg <= 7'b0000000;
      an <= 4'b0000;
      state <= LEFT;
    end
    else begin
      case(state)
        LEFT: begin seg <= seg1; an <= 4'b0111; state <= MIDLEFT; end
        MIDLEFT: begin seg <= seg2; an <= 4'b1011; state <= MIDRIGHT; end
        MIDRIGHT: begin seg <= seg3; an <= 4'b1101; state <= RIGHT; end
        RIGHT: begin seg <= seg4; an <= 4'b1110; state <= LEFT; end
      endcase
    end
  end
endmodule



module clkdown (clk, op_clk);
input clk;
output reg op_clk=0;
reg [10:0] temp=11'd0;

always @(posedge clk)
begin
if(temp==11'd4194303)
temp <= 11'd0;
else
temp <= temp +1'd1;
end

always@(posedge temp[10]) op_clk = ~op_clk;

endmodule



module decoder_7seg(in1,out1);

  input [3:0] in1;
  output reg [6:0] out1;

  always @ (in1)
    case (in1)
      4'b0000 : out1=7'b1000000; //0
      4'b0001 : out1=7'b1111001; //1
      4'b0010 : out1=7'b0100100; //2
      4'b0011 : out1=7'b0110000; //3
      4'b0100 : out1=7'b0011001; //4
      4'b0101 : out1=7'b0010010; //5
      4'b0110 : out1=7'b0000010; //6
      4'b0111 : out1=7'b1111000; //7
      4'b1000 : out1=7'b0000000; //8
      4'b1001 : out1=7'b0010000; //9
      4'b1010 : out1=7'b0001000; //A
      4'b1011 : out1=7'b0000011; //B
      4'b1100 : out1=7'b1000110; //C
      4'b1101 : out1=7'b0100001; //D
      4'b1110 : out1=7'b0000110; //E
      4'b1111 : out1=7'b0001110; //F
    endcase
      
endmodule