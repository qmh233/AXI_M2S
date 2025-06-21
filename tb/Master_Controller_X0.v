//---------------------------------------------------------------
//             __    __    __    __    __    __    __    __
// CLK      __|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__
//             _________________
// MC_REQ   __|                 |_____________________________
//                         _____
// MC_ACK   ______________|     |_____________________________
//            __________________
// MC_ADDR  XX______________A___XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
//            __________________
// MC_WDATA XX______________DW__XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
//                         _____
// MC_RDATA XXXXXXXXXXXXXXX_DR__XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
// 
//---------------------------------------------------------------
`timescale 1ns/100ps  		// 时间精度（必须有）

// 并发写读数据
module Master_Controller #(
	parameter integer ADDR_WIDTH = 32,			// 地址位宽
	parameter integer DATA_WIDTH = 32,			// 数据位宽
	parameter integer CLK_PERIOD = 10,			// 时钟周期，时钟频率为100MHz
	parameter integer REGS_NUM   = 256,			// 存储器数量(4字节对齐)
	parameter BASEADDR = 32'h0000_0000			// 存储器起始地址
)(
	// 全局信号
	input wire 						clk,
	input wire 						rst_n,

	// 仿真输出信号
    output reg  					MC_WREQ,		// 写请求信号
 	input wire						MC_WACK,		// 写准备好
 	input  wire						MC_BACK,		// 响应准备好
    output reg [ADDR_WIDTH-1:0]		MC_WADDR,		// 写地址
    output reg [DATA_WIDTH-1:0]		MC_WDATA,		// 写数据
	input wire  		 			MC_WERROR,		// 写错误标志 
    output reg    					MC_RREQ,		// 读请求信号
 	input wire						MC_RACK,		// 读准备好
    output reg [ADDR_WIDTH-1:0]		MC_RADDR,		// 读地址
    input wire [DATA_WIDTH-1:0]		MC_RDATA,		// 读数据
	input wire  		 			MC_RERROR		// 读错误标志 
);

	// 局部变量
	reg [DATA_WIDTH-1:0]     		ret_data;
		

	// 写数据
	initial begin
		MC_WREQ = 1'b0;		MC_WADDR = 'h04;		MC_WDATA = 'h0;
		repeat(2) @(posedge clk);					// 延迟2个时钟周期等待复位完成

		MC_WRITE(BASEADDR+32'h00, 32'ha55a_5aa5);	repeat(2) @(posedge clk);
		MC_WRITE(BASEADDR+32'h04, 32'h1111_1111);	repeat(2) @(posedge clk);
		MC_WRITE(BASEADDR+32'h08, 32'h2222_2222);	repeat(2) @(posedge clk);
		MC_WRITE(BASEADDR+32'h0c, 32'h3333_3333);	repeat(2) @(posedge clk);
		MC_WRITE(BASEADDR+32'h10, 32'h4444_4444);	repeat(2) @(posedge clk);
		MC_WRITE(BASEADDR+32'h14, 32'h5555_5555);	repeat(2) @(posedge clk);
		MC_WRITE(BASEADDR+32'h18, 32'h6666_6666);	repeat(2) @(posedge clk);
		MC_WRITE(BASEADDR+32'h1c, 32'h7777_7777);	repeat(2) @(posedge clk);
		MC_WRITE(BASEADDR+32'h20, 32'h8888_8888);	repeat(2) @(posedge clk);
		MC_WRITE(BASEADDR+32'h24, 32'h9999_9999);	repeat(2) @(posedge clk);
		MC_WRITE(BASEADDR+32'h28, 32'haaaa_aaaa);	repeat(2) @(posedge clk);
		MC_WRITE(BASEADDR+32'h2c, 32'hbbbb_bbbb);	repeat(2) @(posedge clk);
		MC_WRITE(BASEADDR+32'h30, 32'hcccc_cccc);	repeat(2) @(posedge clk);
		MC_WRITE(BASEADDR+32'h34, 32'hdddd_dddd);	repeat(2) @(posedge clk);
		MC_WRITE(BASEADDR+32'h38, 32'heeee_eeee);	repeat(2) @(posedge clk);
		MC_WRITE(BASEADDR+32'h3c, 32'hffff_ffff);	repeat(2) @(posedge clk);
		
	end

	// 读数据
	initial begin
		MC_RREQ = 1'b0; 	MC_RADDR = 'h04;
		repeat(300) @(posedge clk);					// 延迟300个时钟周期等待复位完成

		MC_READ(BASEADDR+32'h00, ret_data);	repeat(2) @(posedge clk);
		MC_READ(BASEADDR+32'h04, ret_data);	repeat(2) @(posedge clk);
		MC_READ(BASEADDR+32'h08, ret_data);	repeat(2) @(posedge clk);
		MC_READ(BASEADDR+32'h0c, ret_data);	repeat(2) @(posedge clk);
		MC_READ(BASEADDR+32'h10, ret_data);	repeat(2) @(posedge clk);
		MC_READ(BASEADDR+32'h14, ret_data);	repeat(2) @(posedge clk);
		MC_READ(BASEADDR+32'h18, ret_data);	repeat(2) @(posedge clk);
		MC_READ(BASEADDR+32'h1c, ret_data);	repeat(2) @(posedge clk);
		MC_READ(BASEADDR+32'h20, ret_data);	repeat(2) @(posedge clk);
		MC_READ(BASEADDR+32'h24, ret_data);	repeat(2) @(posedge clk);
		MC_READ(BASEADDR+32'h28, ret_data);	repeat(2) @(posedge clk);
		MC_READ(BASEADDR+32'h2c, ret_data);	repeat(2) @(posedge clk);
		MC_READ(BASEADDR+32'h30, ret_data);	repeat(2) @(posedge clk);
		MC_READ(BASEADDR+32'h34, ret_data);	repeat(2) @(posedge clk);
		MC_READ(BASEADDR+32'h38, ret_data);	repeat(2) @(posedge clk);
		MC_READ(BASEADDR+32'h3c, ret_data);	repeat(2) @(posedge clk);

		repeat(10) @(posedge clk);	
		$finish;
	end


	//----------------------------------------------------------------------
	//----------------------------------------------------------------------
	task MC_WRITE;
	input [ADDR_WIDTH-1:0] t_addr;
	input [DATA_WIDTH-1:0] t_data;
	begin
		$display("MC_WRITE---addr: %00h; data: %00000000h", t_addr, t_data);
		MC_WREQ <= 1'b1;						// 请求传输
		MC_WADDR <= t_addr;						// 在时钟的上升沿之后输出数据
		MC_WDATA <= t_data;						// 在时钟的上升沿之后输出数据
		#1 wait(MC_WACK == 1);					// 等待写完成
		@(posedge clk);	
		#1 wait(MC_BACK == 1);					// 等待响应完成
		@(posedge clk);
		MC_WREQ <= 1'b0;
	end
	endtask

	task MC_READ;
	input [ADDR_WIDTH-1:0] t_addr;
	output [DATA_WIDTH-1:0] t_data;				// 注意返回时刻采样数据t_data并送给调用模块
	begin
		MC_RREQ <= 1'b1;						// 请求传输
		MC_RADDR <= t_addr;						// 在时钟的上升沿之后输出数据
		#1 wait(MC_RACK == 1);					// 等待读完成
		@(posedge clk);
		t_data <= MC_RDATA;
		MC_RREQ <= 1'b0;
		$display("MC_READ----addr: %00h; data: %00000000h", t_addr, MC_RDATA);
	end
	endtask


endmodule