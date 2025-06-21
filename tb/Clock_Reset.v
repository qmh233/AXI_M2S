`timescale 1ns/100ps  		// 时间精度（必须有）

module Clock_Reset #(
	parameter integer CLK_PERIOD = 10,			// 时钟周期，时钟频率为100MHz
	parameter integer RST_LENGTH = 2,			// 复位时钟数，2个时钟周期
	parameter integer CLK2_PERIOD = 20,			// 时钟周期，时钟频率为50MHz
	parameter integer RST2_LENGTH = 10			// 复位时钟数，10个时钟周期
)(
	// 全局信号
	output reg 					clk,
	output reg					rst_n,
	output reg 					clk2,
	output reg					rst2_n
);


	// 时钟与复位信号
	initial begin
		clk = 1'b1;
		forever #(CLK_PERIOD/2) clk = ~clk; // clk = 100MHz
	end
	
	initial begin
		#1 rst_n = 1'b0;	#(CLK_PERIOD*RST_LENGTH);	// 注意#1
		rst_n = 1'b1;
	end

	// 时钟与复位信号2
	initial begin
		clk2 = 1'b1;
		forever #(CLK2_PERIOD/2) clk2 = ~clk2; // clk2 = 50MHz
	end

	initial begin
		#1 rst2_n = 1'b0;	#(CLK2_PERIOD*RST2_LENGTH);	// 注意#1
		rst2_n = 1'b1;
	end

endmodule