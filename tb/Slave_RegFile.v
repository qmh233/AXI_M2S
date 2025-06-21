//---------------------------------------------------------------
//             __    __    __    __    __    __    __    __
// CLK      __|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__
//             _________________
// RF_REQ   __|                 |_____________________________
//                         _____
// RF_ACK   ______________|     |_____________________________
//            __________________
// RF_ADDR  XX______________A___XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
//            __________________
// RF_WDATA XX______________DW__XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
//                         _____
// RF_RDATA XXXXXXXXXXXXXXX_DR__XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
// 
//---------------------------------------------------------------

module Slave_RegFile #(
	parameter integer ADDR_WIDTH = 16,		// 地址宽度
	parameter integer DATA_WIDTH = 32,		// 数据位宽
	parameter integer W_WAIT_CYCLE = 4'h1,	// 写数据等待周期（注意：0 =< 该数 < 16）
	parameter integer R_WAIT_CYCLE = 4'h1,	// 读数据等待周期（注意：0 =< 该数 < 16）
	parameter integer REGS_NUM   = 256		// 存储器数量(4字节对齐)
)(
	//全局变量
	input wire	 					clk,		
	input wire 						rst_n,		
	//写地址通道
	input wire						RF_WREQ,	// 请求
	output wire						RF_WACK,	// 应答
	input wire [ADDR_WIDTH-1:0] 	RF_WADDR,	// 写地址
	input wire [DATA_WIDTH-1:0] 	RF_WDATA,	// 写数据
	output reg						RF_WERROR,	// 错误标志
	input wire						RF_RREQ,	// 请求
	output wire						RF_RACK,	// 应答
	input wire [ADDR_WIDTH-1:0] 	RF_RADDR,	// 读地址
	output reg [DATA_WIDTH-1:0] 	RF_RDATA,	// 读数据
	output reg						RF_RERROR	// 错误标志
);

	//---------------------<局部变量定义>-------------------------------------
	reg [DATA_WIDTH-1:0] 			DATA_REGS[0:REGS_NUM-1];// 存储器数组(4字节对齐)
	wire [ADDR_WIDTH-1:0] 			w_addr_index;
	wire [ADDR_WIDTH-1:0] 			r_addr_index;

	//---------------------<局部变量定义>-------------------------------------
	reg  [3:0]  w_wait_cnt;						// 写数据等待计数器，最多15个等待周期
	reg  [3:0]  r_wait_cnt;						// 读数据等待计数器，最多15个等待周期
	reg			RF_WACK_reg, RF_RACK_reg;

	// 访存等待周期
		always @(posedge clk or negedge rst_n) begin
			if(rst_n==1'b0)begin
				w_wait_cnt <= W_WAIT_CYCLE;
			end
			if (RF_WREQ) begin
				if (w_wait_cnt == 0) begin
					w_wait_cnt <= W_WAIT_CYCLE;
				end
				else if(w_wait_cnt > 0) begin
					w_wait_cnt <= w_wait_cnt - 1;
				end
			end
		end
		assign RF_WACK = RF_WREQ && (w_wait_cnt == 0);

		always @(posedge clk or negedge rst_n) begin
			if(rst_n==1'b0) begin
				r_wait_cnt <= R_WAIT_CYCLE;
			end
			if(RF_RREQ) begin
				if(r_wait_cnt == 0) begin
					r_wait_cnt <= R_WAIT_CYCLE;
				end
				else if(r_wait_cnt > 0) begin
					r_wait_cnt <= r_wait_cnt - 1;
				end
			end
		end
		assign RF_RACK = RF_RREQ && (r_wait_cnt == 0);

	//############################# 写存储器 #################################
	assign w_addr_index = RF_WADDR >> 2; 			// 计算地址索引
	always @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			RF_WERROR <= 1'b0;
		end
		else if (RF_WACK) begin
			if (w_addr_index < REGS_NUM) begin
				DATA_REGS[w_addr_index] <= RF_WDATA;
				RF_WERROR <= 1'b0;
			end
			else
				RF_WERROR <= 1'b1;
		end
	end

	//############################# 读存储器 #################################
	assign r_addr_index = RF_RADDR >> 2; 			// 计算地址索引
	always @(*) begin
		if (!rst_n) begin
			RF_RDATA = 'h0;
			RF_RERROR = 1'b0;
		end
		else if (RF_RACK) begin
			if (r_addr_index < REGS_NUM) begin
				RF_RDATA = DATA_REGS[r_addr_index];
				RF_RERROR = 1'b0;
			end
			else
				RF_RERROR = 1'b1;
		end
	end

endmodule
