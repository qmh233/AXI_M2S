////////////////////////////////////////////////////////////////////
////															////
////  Generic Dual-Port Synchronous RAM							////
////															////
////////////////////////////////////////////////////////////////////
`timescale 1ns / 100ps

module DualPort_SRAM(
	// Generic synchronous dual-port RAM interface
	rclk, rrst, rce, oe, raddr, dout,
	wclk, wrst, wce, we, waddr, din
);
	// Default address and data buses width
	parameter ADDR_WIDTH = 5;  		// number of bits in address-bus
	parameter DATA_WIDTH = 16; 		// number of bits in data-bus

	// Generic synchronous double-port RAM interface
	// read port
	input  rclk;  					// read clock, rising edge trigger
	input  rrst;  					// read port reset, active high
	input  rce;						// read port chip enable, active high
	input  oe;						// output enable, active high
	input  [ADDR_WIDTH-1:0] raddr; 	// read address
	output [DATA_WIDTH-1:0] dout; 	// data output

	// write port
	input	 wclk;  				// write clock, rising edge trigger
	input	 wrst;  				// write port reset, active high
	input	 wce;					// write port chip enable, active high
	input	 we; 					// write enable, active high
	input [ADDR_WIDTH-1:0] waddr; 	// write address
	input [DATA_WIDTH-1:0] din; 	// data input

	// Generic dual-port synchronous RAM model
	//

	// Generic RAM's registers and wires
	//
	reg	[DATA_WIDTH-1:0]	mem [(1<<ADDR_WIDTH)-1:0];	// RAM content
	reg	[DATA_WIDTH-1:0]	dout_reg;			// RAM data output register

	// Data output drivers
	assign dout = (rce & oe) ? dout_reg : {DATA_WIDTH{1'bz}};

	// read operation
	always @(posedge rclk)
		if (rce)
 			dout_reg <= #1 (we && (waddr==raddr)) ? {DATA_WIDTH{1'b x}} : mem[raddr];

	// write operation
	always @(posedge wclk)
		if (wce && we)
			mem[waddr] <= #1 din;


	// Task prints range of memory
	// *** Remember that tasks are non reentrant, don't call this task in parallel for multiple instantiations. 
	task print_ram;
	input [ADDR_WIDTH-1:0] start;
	input [ADDR_WIDTH-1:0] finish;
	integer rnum;
  	begin
 		for (rnum=start;rnum<=finish;rnum=rnum+1)
			$display("Addr %h = %h",rnum,mem[rnum]);
  	end
	endtask

endmodule
