`timescale 1ns/100ps  		// 时间精度（必须有）

module testbench;
	parameter integer ADDR_WIDTH = 32;	// 地址宽度
	parameter integer DATA_WIDTH = 32;	// 数据位宽
	parameter integer CLK_PERIOD = 10;	// 时钟周期，时钟频率为100MHz
	parameter integer RST_LENGTH = 1;	// 复位时钟数，1个时钟周期
	parameter integer ADDRWIDTH_SRAM = 16;			// SRAM地址宽度
	parameter integer REGS_NUM_SRAM  = 256;			// SRAM大小(4字节对齐)
	parameter BASEADDR_SRAM = 32'h2000_0000;		// SRAM起始地址

	// 全局信号
	wire 					clk;		// 时钟信号
	wire 					rst_n;		// 复位信号
	wire 					ASEL;		// 片选信号
	
	// AXI LITE INTERFACE
	// 写地址
	wire[ADDR_WIDTH-1:0]	AW_ADDR;
	wire[7:0]				AW_LEN;
	wire[2:0]				AW_SIZE;
	wire[1:0]				AW_BURST;
	wire 					AW_VALID;
	wire 					AW_READY;
	// 写数据
	wire[DATA_WIDTH-1:0]  	W_DATA;
	wire					W_LAST;
	wire 					W_VALID;
	wire 					W_READY;
	// 写响应
	wire[1:0] 				B_RESP;
	wire 					B_VALID;
	wire 					B_READY;
	// 读地址
	wire[ADDR_WIDTH-1:0]	AR_ADDR;
	wire[7:0]               AR_LEN;
	wire[2:0]               AR_SIZE;
	wire[1:0]               AR_BURST;
	wire 					AR_VALID;
	wire 					AR_READY;
	// 读数据
	wire[DATA_WIDTH-1:0] 	R_DATA;
	wire[1:0] 				R_RESP;
	wire					R_LAST;
	wire 					R_VALID;
	wire 					R_READY;
	
	// 主设备测试信号
	wire 					MC_WREQ;	// 写请求信号
 	wire 					MC_WACK;	// 写准备好
 	wire					MC_BACK;	// 响应准备好
	wire [ADDR_WIDTH-1:0] 	MC_WADDR;	// 写地址
	wire [DATA_WIDTH-1:0] 	MC_WDATA;	// 写数据
	wire	 				MC_WERROR;	// 写错误标志
	wire   					MC_RREQ;	// 读请求信号
 	wire 					MC_RACK;	// 读准备好
	wire [ADDR_WIDTH-1:0] 	MC_RADDR;	// 读地址
	wire[DATA_WIDTH-1:0] 	MC_RDATA;	// 读数据
	wire	 				MC_RERROR;	// 读错误标志

	// 从设备测试信号
	wire					RF_WREQ;	// 请求
	wire					RF_WACK;	// 应答
	wire[ADDR_WIDTH-1:0] 	RF_WADDR;	// 写地址缓存
	wire[DATA_WIDTH-1:0] 	RF_WDATA;	// 写寄存器缓存
	wire					RF_WERROR;	// 错误标志
	wire					RF_RREQ;	// 请求
	wire					RF_RACK;	// 应答
	wire[ADDR_WIDTH-1:0] 	RF_RADDR;	// 读地址缓存
	wire[DATA_WIDTH-1:0] 	RF_RDATA;	// 读寄存器缓存
	wire	 				RF_RERROR;	// 错误标志

	//----------------------------------------------------------------------
	//----------------------------------------------------------------------
	/*iverilog */
	initial
	begin            
		$dumpfile("wave.vcd");        		// 生成的vcd文件名称
		$dumpvars(0, testbench);   	  		// testbench模块名称
	end
	/*iverilog */

	assign ASEL = ((AW_ADDR[31:16] == BASEADDR_SRAM[31:16])
				  |(AR_ADDR[31:16] == BASEADDR_SRAM[31:16]));     // 0x20000000，SRAM，译码器

	//----------------------------------------------------------------------
	//----------------------------------------------------------------------
	// 时钟与复位信号发生器
	Clock_Reset
		#(.CLK_PERIOD(CLK_PERIOD), .RST_LENGTH(RST_LENGTH))
		Clock_Reset0(
			.clk		(clk),
			.rst_n		(rst_n),
			.clk2		(  ),
			.rst2_n		(  )
		);

	// 测试主控制器
	Master_Controller
		#(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .CLK_PERIOD(CLK_PERIOD),
		  .REGS_NUM(REGS_NUM_SRAM), .BASEADDR(BASEADDR_SRAM))
		Master_Controller0(
			.clk		(clk),
			.rst_n		(rst_n),
			
			.MC_WREQ	(MC_WREQ),			// 写请求信号
			.MC_WACK	(MC_WACK),			// 写准备好
			.MC_BACK	(MC_BACK),			// 响应准备好
			.MC_WADDR	(MC_WADDR),			// 写地址
			.MC_WDATA	(MC_WDATA),			// 写数据
			.MC_WERROR	(MC_WERROR),		// 写错误标志
			.MC_RREQ	(MC_RREQ),			// 读请求信号
			.MC_RACK	(MC_RACK),			// 读准备好
			.MC_RADDR	(MC_RADDR),			// 读地址
			.MC_RDATA	(MC_RDATA),			// 读数据
			.MC_RERROR	(MC_RERROR)			// 读错误标志
		);

	// AXI主接口
	AXI_Lite_Master_IF 
		#(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH))
		AXI_MASTER_IF0(
			.ACLK		(clk),		
			.ARESETn	(rst_n),		
			
			.AW_ADDR	(AW_ADDR),
			.AW_LEN		(AW_LEN),
			.AW_SIZE	(AW_SIZE),
			.AW_BURST	(AW_BURST),
			.AW_VALID	(AW_VALID),
			.AW_READY	(AW_READY),
			
			.W_DATA		(W_DATA),
			.W_LAST		(W_LAST),
			.W_VALID	(W_VALID),
			.W_READY	(W_READY),
			
			.B_RESP		(B_RESP),
			.B_VALID	(B_VALID),
			.B_READY	(B_READY),
			
			.AR_ADDR	(AR_ADDR),
			.AR_LEN		(AR_LEN),
			.AR_SIZE	(AR_SIZE),
			.AR_BURST	(AR_BURST),
			.AR_VALID	(AR_VALID),
			.AR_READY	(AR_READY),
			
			.R_DATA		(R_DATA),
			.R_RESP		(R_RESP),
			.R_LAST		(R_LAST),
			.R_VALID	(R_VALID),
			.R_READY	(R_READY),
			
			.MC_WREQ	(MC_WREQ),			// 写请求信号
			.MC_WACK	(MC_WACK),			// 写准备好
			.MC_BACK	(MC_BACK),			// 响应准备好
			.MC_WADDR	(MC_WADDR),			// 写地址
			.MC_WDATA	(MC_WDATA),			// 写数据
			.MC_WERROR	(MC_WERROR),		// 写错误标志
			.MC_RREQ	(MC_RREQ),			// 读请求信号
			.MC_RACK	(MC_RACK),			// 读准备好
			.MC_RADDR	(MC_RADDR),			// 读地址
			.MC_RDATA	(MC_RDATA),			// 读数据
			.MC_RERROR	(MC_RERROR)			// 读错误标志
		);

	// AXI从接口
	AXI_Lite_Slave_IF 
		#(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH))
		AXI_SLAVE_IF0(
			.ACLK		(clk),		
			.ARESETn	(rst_n),
			.ASEL		(ASEL),	
			
			.AW_ADDR	(AW_ADDR),
			.AW_LEN		(AW_LEN),
			.AW_SIZE	(AW_SIZE),
			.AW_BURST	(AW_BURST),
			.AW_VALID	(AW_VALID),
			.AW_READY	(AW_READY),
			
			.W_DATA		(W_DATA),
			.W_LAST		(W_LAST),
			.W_VALID	(W_VALID),
			.W_READY	(W_READY),
			
			.B_RESP		(B_RESP),
			.B_VALID	(B_VALID),
			.B_READY	(B_READY),
			
			.AR_ADDR	(AR_ADDR),
			.AR_LEN		(AR_LEN),
			.AR_SIZE	(AR_SIZE),
			.AR_BURST	(AR_BURST),
			.AR_VALID	(AR_VALID),
			.AR_READY	(AR_READY),
			
			.R_DATA		(R_DATA),
			.R_RESP		(R_RESP),
			.R_LAST		(R_LAST),
			.R_VALID	(R_VALID),
			.R_READY	(R_READY),
			
			.RF_WREQ	(RF_WREQ),
			.RF_WACK	(RF_WACK),
			.RF_WADDR	(RF_WADDR),
			.RF_WDATA	(RF_WDATA),
			.RF_WERROR	(RF_WERROR),
			.RF_RREQ	(RF_RREQ),
			.RF_RACK	(RF_RACK),
			.RF_RADDR	(RF_RADDR),
			.RF_RDATA	(RF_RDATA),
			.RF_RERROR	(RF_RERROR)
		);

	// 测试从寄存器文件
	Slave_RegFile 
		#(.ADDR_WIDTH(ADDRWIDTH_SRAM), .DATA_WIDTH(DATA_WIDTH),
		  .W_WAIT_CYCLE(4'h0), .R_WAIT_CYCLE(4'h0), .REGS_NUM(REGS_NUM_SRAM))
		Slave_RegFile0(
			.clk		(clk),
			.rst_n		(rst_n),
			
			.RF_WREQ	(RF_WREQ),
			.RF_WACK	(RF_WACK),
			.RF_WADDR	(RF_WADDR[ADDRWIDTH_SRAM-1:0]),
			.RF_WDATA	(RF_WDATA),
			.RF_WERROR	(RF_WERROR),
			.RF_RREQ	(RF_RREQ),
			.RF_RACK	(RF_RACK),
			.RF_RADDR	(RF_RADDR[ADDRWIDTH_SRAM-1:0]),
			.RF_RDATA	(RF_RDATA),
			.RF_RERROR	(RF_RERROR)
		);

endmodule
