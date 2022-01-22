/*
File     : picoblaze_demo_top.v (based on an earlier divider_top.v) 
Author   : Gandhi Puvvada
Revision  : 1.1, 2.0 (Nexys-3), 3.0 (Nexys-4)
Date : Feb 15, 2008, 10/14/08, 2/12/2012, 4/7/2017, 3/1/2020
*/

/*
A verlog top module for demonstrating the design flow associated with a picoblaze-based design.

The picoblaze processor reads the 8 switches through an input port and writes the same to the leds though an output port 
Though we are not using interrupts, the following connections from picoblaze to the top file are kept for future use:
	.interrupt 		(interrupt),
	.interrupt_ack 	(interrupt_ack),

Though SSDs are not used, we used the code from test_nexys3_verilog.v to simply display the switches value 
on 2 of the 4 digits and their complement on the other 2 of the 4 digits.
 
*/
/*
 Make sure to use the picoblaze_demo_top.ucf file containing pin info.
 
*/
module picoblaze_demo_top		(   
		// MemOE, MemWR, RamCS, FlashCS, QuadSpiFlashCS, // Disable the three memory chips <== Nexys-3
		MemOE, MemWR, RamCS, QuadSpiFlashCS, // Disable the two memory chips <== Nexys-4
        ClkPort,                           // the 100 MHz incoming clock signal
		
		BtnL, BtnU, BtnD, BtnR,            // the Left, Up, Down, and the Right buttons 		BtnL, BtnR,
		BtnC,                              // the center button (this is our reset in most of our designs)
		Sw7, Sw6, Sw5, Sw4, Sw3, Sw2, Sw1, Sw0, // 8 switches
		Ld7, Ld6, Ld5, Ld4, Ld3, Ld2, Ld1, Ld0, // 8 LEDs
		An3, An2, An1, An0,			       // 4 anodes
		An7, An6, An5, An4,			       // 4 other anodes to be disabled permanently
		Ca, Cb, Cc, Cd, Ce, Cf, Cg,        // 7 cathodes
		Dp
	  );
	 
								
	/*  INPUTS */
	// Clock & Reset I/O
	input		ClkPort;	
	// Project Specific Inputs
	input		BtnL, BtnU, BtnD, BtnR, BtnC;	
	input		Sw7, Sw6, Sw5, Sw4, Sw3, Sw2, Sw1, Sw0;
	
	
	/*  OUTPUTS */
	// Control signals on Memory chips 	(to disable them)
	// output 	MemOE, MemWR, RamCS, FlashCS, QuadSpiFlashCS; // <== Nexys-3
	output 	MemOE, MemWR, RamCS,  QuadSpiFlashCS; // <== Nexys-4
	// Project Specific Outputs
	// LEDs
	output 	Ld0, Ld1, Ld2, Ld3, Ld4, Ld5, Ld6, Ld7;
	// SSD Outputs
	output 	Cg, Cf, Ce, Cd, Cc, Cb, Ca, Dp;
	output 	An0, An1, An2, An3;	
	output 	An4, An5, An6, An7;	// 4 other anodes to be disabled permanently
//	output   JA0, JA1, JA2, JA3, JB0, JB1, JB2, JB3; 
	
	/*  LOCAL SIGNALS */
	wire		Reset, ClkPort;
	wire		board_clk, sys_clk;
	wire [1:0] 	ssdscan_clk;
	

// to produce divided clock
	reg [26:0]	DIV_CLK;
// SSD (Seven-Segment Display)
	reg [3:0]	SSD;
	wire [3:0]	SSD3, SSD2, SSD1, SSD0;
	reg [7:0]  	SSD_CATHODES;

	reg [7:0] led_reg; // This is a physical register forming the output port for the picoblaze
	
// to produce clocks taken
	reg [7:0] Clk_cnt;

// Signals used to connect KCPSM6

	wire [11:0] address;
	wire [17:0]	instruction;
	wire        bram_enable;
	reg  [7:0]  in_port;
	wire [7:0]  out_port;
	wire [7:0]  port_id;
	wire        write_strobe;
	wire        k_write_strobe;
	wire        read_strobe;
	reg         interrupt;   
	wire        interrupt_ack;
	wire        kcpsm6_sleep;  
	wire        kcpsm6_reset;
	wire        rdl;	
	
//------------	
// Disable the three memories so that they do not interfere with the rest of the design.
	// assign {MemOE, MemWR, RamCS, FlashCS, QuadSpiFlashCS} = 5'b11111;  // Nexys-3
// Disable the two memories so that they do not interfere with the rest of the design.
	assign {MemOE, MemWR, RamCS, QuadSpiFlashCS} = 4'b1111;  // Nexys-4
	
  /////////////////////////////////////////////////////////////////////////////////////////
  // Instantiate KCPSM6 and connect to program ROM
  /////////////////////////////////////////////////////////////////////////////////////////
  //
  // The generics can be defined as required. In this case the 'hwbuild' value is used to 
  // define a version using the ASCII code for the desired letter and the interrupt vector
  // has been set to 3C0 to provide 64 instructions for an Interrupt Service Routine (ISR)
  // before reaching the end of a 1K memory 
  //


  kcpsm6 #(
	.interrupt_vector	(12'h3FF),
	.scratch_pad_memory_size(64),
	.hwbuild		(8'h41))            // 41 hex is ASCII Character "A"
  processor (
	.address 		(address),
	.instruction 	(instruction),
	.bram_enable 	(bram_enable),
	.port_id 		(port_id),
	.write_strobe 	(write_strobe),
	.k_write_strobe (k_write_strobe),
	.out_port 		(out_port),
	.read_strobe 	(read_strobe),
	.in_port 		(in_port),
	.interrupt 		(interrupt),
	.interrupt_ack 	(interrupt_ack),
	.reset 			(kcpsm6_reset),
	.sleep			(kcpsm6_sleep),
	.clk 			(board_clk)); 

// Reset by press button (active Low) or JTAG Loader enabled Program Memory 

	assign kcpsm6_reset = rdl | ( BtnC) ;	

// Unused signals tied off until required.
// The following may produce a warning message during synthesis. If so ignore it.
 
	assign kcpsm6_sleep = 0;
// Development Program Memory 
//   JTAG Loader enabled for rapid code development. 
  
  prom_demo #(
	// .C_FAMILY		   ("S6"),  // Nexys-3
	.C_FAMILY		   ("7S"),      // Nexys-4
	.C_RAM_SIZE_KWORDS	(1),  
	.C_JTAG_LOADER_ENABLE	(1))
	program_rom (
	.rdl 			(rdl),
	.enable 		(bram_enable),
	.address 		(address),
	.instruction 	(instruction),
	.clk 			(board_clk));  
//------------
// CLOCK DIVISION

	// The clock division circuitry works like this:
	//
	// ClkPort ---> [BUFGP2] ---> board_clk
	// board_clk ---> [clock dividing counter] ---> DIV_CLK
	// DIV_CLK ---> [constant assignment] ---> sys_clk;
	
	BUFGP BUFGP1 (board_clk, ClkPort); 	

// As the ClkPort signal travels throughout our design,
// it is necessary to provide global routing to this signal. 
// The BUFGPs buffer these input ports and connect them to the global 
// routing resources in the FPGA.

	// BUFGP BUFGP2 (Reset, BtnC); In the case of Spartan 3E (on Nexys-2 board), we were using BUFGP to provide global routing for the reset signal. But Spartan 6 (on Nexys-3) does not allow this.
	assign Reset = BtnC;
//------------
	// Our clock is too fast (100MHz) for SSD scanning
	// create a series of slower "divided" clocks
	// each successive bit is 1/2 frequency
  always @(posedge board_clk, posedge Reset) 	
    begin							
        if (Reset)
		DIV_CLK <= 0;
        else
		DIV_CLK <= DIV_CLK + 1'b1;
    end
//------------	
	// pick a divided clock bit to assign to system clock
	// your decision should not be "too fast" or you will not see you state machine working
	assign	sys_clk = DIV_CLK[20]; // DIV_CLK[25] (~1.5Hz) = (100MHz / 2**26)
	// in future designs we will use the full speed clock

	//------------         

	/*
	From our prom_demo.psm file
	 CONSTANT pb_input, 				01		; port01 used for loading info of push buttons BtnL BtnR BtnU BtnD
	 CONSTANT led_output, 				01		; port01 used for outputting Push Button info to leds
	 
	 CONSTANT Switch_Data_Input, 		02  	; port02 used for loading info of Switches SW7-0
	 CONSTANT SSD_Output, 				02 		; port02 used for outputting Switch Info to 7 Segment Display
	
	*/
	 
always @ (*)
	
begin
	// Actually, we do not need this mux or the port_id here as we have only one input port
	case (port_id[1:0])
		// 2'b00 : in_port <= {5'b00000,slow_bits};
		// 2'b01 : in_port <= {BtnL, BtnL, BtnU, BtnU, BtnD, BtnD, BtnR, BtnR}; 	
		2'b10 : in_port <= {Sw7, Sw6, Sw5, Sw4, Sw3, Sw2, Sw1, Sw0};
		// 2'b11 : in_port <= {5'b00000, interrupt_slow_clk, interrupt_pb, interrupt_sw };
		default: in_port <= {Sw7, Sw6, Sw5, Sw4, Sw3, Sw2, Sw1, Sw0};
	endcase
end


assign {Ld7, Ld6, Ld5, Ld4, Ld3, Ld2, Ld1, Ld0}   =  led_reg;

always @(posedge board_clk) 	
begin	
	// 'write_strobe' is used to qualify all writes to general output ports using OUTPUT.
	if (write_strobe == 1'b1) 
	begin
		if(port_id[1:0] == 2'b01)begin
			led_reg  <= out_port;
		end	
	end

/* 	// 'k_write_strobe' is used to qualify all writes to general output ports using OUTPUTK.
	if (k_write_strobe == 1'b1) 
	begin
		// Write to output_port at port address 01
		if (port_id[0]  == 1'b1) 
		begin
			Done <= out_port[0];
			Qi <= out_port[1];
			Qc <= out_port[2];
			Qd <= out_port[3];
		end	
	end		 */
end

//------------

// SSD (Seven-Segment Display)
	// reg [3:0]	SSD;
	// wire [3:0]	SSD3, SSD2, SSD1, SSD0;
	
	//SSDs display the true and complement values of the switches  
assign SSD0 = {  Sw3,   Sw2,   Sw1,   Sw0};
assign SSD1 = {  Sw7,   Sw6,   Sw5,   Sw4};
assign SSD2 = { ~Sw3,  ~Sw2,  ~Sw1,  ~Sw0};
assign SSD3 = { ~Sw7,  ~Sw6,  ~Sw5,  ~Sw4};


	// need a scan clk for the seven-segment display 
	
	// 100 MHz / 2^18 = 381.5 cycles/sec ==> frequency of DIV_CLK[17]
	// 100 MHz / 2^19 = 190.7 cycles/sec ==> frequency of DIV_CLK[18]
	// 100 MHz / 2^20 =  95.4 cycles/sec ==> frequency of DIV_CLK[19]
	
	// 381.5 cycles/sec (2.62 ms per digit) [which means all 4 digits are lit once every 10.5 ms (reciprocal of 95.4 cycles/sec)] works well.
	
	//                  --|  |--|  |--|  |--|  |--|  |--|  |--|  |--|  |   
    //                    |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  | 
	//  DIV_CLK[17]       |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|
	//
	//               -----|     |-----|     |-----|     |-----|     |
    //                    |  0  |  1  |  0  |  1  |     |     |     |     
	//  DIV_CLK[18]       |_____|     |_____|     |_____|     |_____|
	//
	//         -----------|           |-----------|           |
    //                    |  0     0  |  1     1  |           |           
	//  DIV_CLK[19]       |___________|           |___________|
	//

	assign ssdscan_clk = DIV_CLK[19:18];
	assign An0	= !(~(ssdscan_clk[1]) && ~(ssdscan_clk[0]));  // when ssdscan_clk = 00
	assign An1	= !(~(ssdscan_clk[1]) &&  (ssdscan_clk[0]));  // when ssdscan_clk = 01
	assign An2	=  !((ssdscan_clk[1]) && ~(ssdscan_clk[0]));  // when ssdscan_clk = 10
	assign An3	=  !((ssdscan_clk[1]) &&  (ssdscan_clk[0]));  // when ssdscan_clk = 11
	
	assign {An7, An6, An5, An4} = 4'b1111; // 4 other anodes are disabled permanently
	
	always @ (ssdscan_clk, SSD0, SSD1, SSD2, SSD3)
	begin : SSD_SCAN_OUT
		case (ssdscan_clk) 
				  2'b00: SSD = SSD0;
				  2'b01: SSD = SSD1;
				  2'b10: SSD = SSD2;
				  2'b11: SSD = SSD3;
		endcase 
	end

	// Following is Hex-to-SSD conversion
	always @ (SSD) 
	begin : HEX_TO_SSD
		case (SSD) // in this solution file the dot points are made to glow by making Dp = 0
		    //                                                                abcdefg,Dp
			4'b0000: SSD_CATHODES = 8'b00000010; // 0
			4'b0001: SSD_CATHODES = 8'b10011110; // 1
			4'b0010: SSD_CATHODES = 8'b00100100; // 2
			4'b0011: SSD_CATHODES = 8'b00001100; // 3
			4'b0100: SSD_CATHODES = 8'b10011000; // 4
			4'b0101: SSD_CATHODES = 8'b01001000; // 5
			4'b0110: SSD_CATHODES = 8'b01000000; // 6
			4'b0111: SSD_CATHODES = 8'b00011110; // 7
			4'b1000: SSD_CATHODES = 8'b00000000; // 8
			4'b1001: SSD_CATHODES = 8'b00001000; // 9
			4'b1010: SSD_CATHODES = 8'b00010000; // A
			4'b1011: SSD_CATHODES = 8'b11000000; // B
			4'b1100: SSD_CATHODES = 8'b01100010; // C
			4'b1101: SSD_CATHODES = 8'b10000100; // D
			4'b1110: SSD_CATHODES = 8'b01100000; // E
			4'b1111: SSD_CATHODES = 8'b01110000; // F    
			default: SSD_CATHODES = 8'bXXXXXXXX; // default is not needed as we covered all cases
		endcase
	end	
	
	// reg [7:0]  SSD_CATHODES;
	assign {Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp} = {SSD_CATHODES};
	

endmodule
