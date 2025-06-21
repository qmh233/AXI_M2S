module AXI_Lite_Master_IF #(
	parameter integer ADDR_WIDTH = 32,			// 地址位宽
	parameter integer DATA_WIDTH = 32			// 数据位宽
)(
	// 全局信号
	input wire 					ACLK,			// 时钟信号
	input wire					ARESETn,        // 复位信号
	// AXI-lite-master interface
    // 写地址通道                                
	output reg[ADDR_WIDTH-1:0]	AW_ADDR,        // 写地址
	output reg[7:0]				AW_LEN,			// 写数据长度
	output reg[2:0]				AW_SIZE,		// 写数据宽度
	output reg[1:0]				AW_BURST,		// 写数据传输方式
	output reg  				AW_VALID,       // AW握手信号
	input wire					AW_READY,       // AW握手信号
    // 写数据通道                                
	output reg[DATA_WIDTH-1:0]	W_DATA,         // 写数据
	output reg					W_LAST,			// 最后一个写数据
	output reg  				W_VALID,        // W握手信号
	input wire					W_READY,        // W握手信号
    // 写响应通道                                
	input wire[1:0] 			B_RESP,         // 写响应标志
	input wire					B_VALID,        // B握手信号
	output reg  				B_READY,        // B握手信号
    // 读地址通道                                
	output reg[ADDR_WIDTH-1:0]	AR_ADDR,        // 读地址
	output reg[7:0]             AR_LEN,			// 读数据长度
	output reg[2:0]             AR_SIZE,		// 读数据宽度
	output reg[1:0]             AR_BURST,		// 读数据传输方式
	output reg  				AR_VALID,       // AR握手信号
	input wire					AR_READY,       // AR握手信号
    // 读数据通道                                
	input wire[DATA_WIDTH-1:0]	R_DATA,         // 读数据
	input wire[1:0] 			R_RESP,         // R响应信号
	input wire					R_LAST,			// 最后一个读数据
	input wire			        R_VALID,        // R握手信号
	output reg  			    R_READY,        // R握手信号

	// 仿真输入信号
    input wire					MC_WREQ,		// 写请求信号
 	output wire					MC_WACK,		// 写准备好
 	output wire					MC_BACK,		// 响应准备好
    input wire[ADDR_WIDTH-1:0]	MC_WADDR,		// 写地址
    input wire[DATA_WIDTH-1:0]	MC_WDATA,		// 写数据
    output wire			 		MC_WERROR,		// 写错误标志 
    input wire					MC_RREQ,		// 读请求信号
 	output reg					MC_RACK,		// 读准备好
    input wire[ADDR_WIDTH-1:0]	MC_RADDR,		// 读地址
    output reg[DATA_WIDTH-1:0]	MC_RDATA,		// 读数据
    output wire	 				MC_RERROR		// 读错误标志 
);
	
	//---------------------<状态机参数>-------------------------------------
	localparam STWA_IDLE	= 3'b001;			// 写地址空闲
	localparam STWA_ADDR	= 3'b010;			// 写地址
	localparam STWA_WAIT	= 3'b100;			// 写地址等待(地址数据同步)
	reg [2:0]               stwa_cur;
	reg [2:0]               stwa_next;

	//---------------------<状态机参数>-------------------------------------
	localparam STW_IDLE		= 4'b0001;			// 写操作空闲
	localparam STW_DATA		= 4'b0010;			// 写操作数据
	localparam STW_WAIT		= 4'b0100;			// 写操作等待(地址数据同步)
	localparam STW_RESP		= 4'b1000;			// 写操作响应
	reg [3:0]               stw_cur;
	reg [3:0]               stw_next;

	//---------------------<状态机参数>-------------------------------------
	localparam STR_IDLE		= 4'b0001;			// 读操作空闲
	localparam STR_ADDR		= 4'b0010;			// 读操作地址
	localparam STR_DATA		= 4'b0100;			// 读操作数据（响应）
	localparam STR_END		= 4'b1000;			// 读结束
	reg [3:0]               str_cur;
	reg [3:0]               str_next;
 
	//---------------------<局部变量定义>-------------------------------------
	reg 					w_addr_over;	// 写地址结束


	//############################# 写操作 #################################
	//----------------------------------------------------------------------
	//--   写地址状态机第1段（状态迁移）
	//----------------------------------------------------------------------
	always @(posedge ACLK or negedge ARESETn)begin
		if(!ARESETn)begin
			stwa_cur <= STWA_IDLE;
		end
		else begin     
			stwa_cur <= stwa_next;
		end
	end

	//----------------------------------------------------------------------
	//--   写地址状态机第2段（输入对状态的影响）
	//----------------------------------------------------------------------
	always @(*)begin
		stwa_next = stwa_cur;					// 下面有不完全赋值，这样可以避免LATCH
		case(stwa_cur)
			STWA_IDLE: begin						// 写地址空闲
				if(MC_WREQ)
					stwa_next = STWA_ADDR;
			end
			STWA_ADDR: begin						// 写地址通道
				if(AW_READY) 
					stwa_next = STWA_WAIT;
			end
			STWA_WAIT: begin						// 写地址同步
				if(B_VALID & B_READY)
					stwa_next = STWA_IDLE;
			end
			default:stwa_next = STWA_IDLE;
		endcase
	end

	//----------------------------------------------------------------------
	//--   写地址状态机第3段（状态对输出的影响）
	//----------------------------------------------------------------------
	// AXI信号产生
	always @(posedge ACLK or negedge ARESETn)begin
		if(!ARESETn)begin
			AW_SIZE <= 3'b010;					// 数据宽度为32bit
			AW_BURST <= 2'b01;					// 写数据传输方式INCR
			AW_LEN <= 8'b0;						// 写数据长度为1，Length = AxLEN + 1
			AW_ADDR <= 'h04;
			AW_VALID <= 1'b0;
		end
		else begin
			case(stwa_next)
				STWA_IDLE: begin
					AW_VALID <= 1'b0;
				end
				STWA_ADDR: begin
					AW_ADDR <= MC_WADDR;
					AW_VALID <= 1'b1;
				end
				STWA_WAIT: begin
					AW_VALID <= 1'b0;
				end
			endcase
		end
	end
	
	// 地址数据同步信号产生
	always @(posedge ACLK or negedge ARESETn)begin
		if(!ARESETn)begin
			w_addr_over <= 1'b0;				// 地址数据同步
		end
		else begin
			case(stwa_next)
				STWA_IDLE: begin
					w_addr_over <= 1'b0;		// 地址数据同步
				end
				STWA_ADDR: begin
					w_addr_over <= 1'b1;		// 地址数据同步
				end
			endcase
		end
	end
	
	//----------------------------------------------------------------------
	//--   写数据响应状态机第1段（状态迁移）
	//----------------------------------------------------------------------
	always @(posedge ACLK or negedge ARESETn)begin
		if(!ARESETn)begin
			stw_cur <= STW_IDLE;
		end
		else begin     
			stw_cur <= stw_next;
		end
	end

	//----------------------------------------------------------------------
	//--   写数据响应状态机第2段（输入对状态的影响）
	//----------------------------------------------------------------------
	always @(*)begin
		stw_next = stw_cur;					// 下面有不完全赋值，这样可以避免LATCH
		case(stw_cur)
			STW_IDLE: begin						// 写空闲
				if(MC_WREQ)
					stw_next = STW_DATA;
			end
			STW_DATA: begin						// 写地址/数据通道
				if(W_READY)
					stw_next = STW_WAIT;
			end
			STW_WAIT: begin						// 写数据同步
				if(w_addr_over)
					stw_next = STW_RESP;
			end
			STW_RESP: begin						// 写响应通道
				if(B_VALID)
					stw_next = STW_IDLE;
			end
			default:stw_next = STW_IDLE;
		endcase
	end

	//----------------------------------------------------------------------
	//--   写数据响应状态机第3段（状态对输出的影响）
	//----------------------------------------------------------------------
	// AXI信号产生
	always @(posedge ACLK or negedge ARESETn)begin
		if(!ARESETn)begin
			W_DATA <= 'h0;
			W_LAST <= 1'b1;
			W_VALID <= 1'b0;
			B_READY <= 1'b0;
		end
		else begin
			case(stw_next)
				STW_IDLE: begin
					W_VALID <= 1'b0;
					B_READY <= 1'b0;
				end
				STW_DATA: begin
					W_DATA <= MC_WDATA; 
					W_VALID <= 1'b1;
					B_READY <= 1'b0;
				end
				STW_WAIT: begin
					W_VALID <= 1'b0;
					B_READY <= 1'b0;
				end
				STW_RESP: begin
					W_VALID <= 1'b0;
					B_READY <= 1'b1;
				end
			endcase
		end
	end

	// MC信号产生
	assign MC_WACK = W_VALID & W_READY;
	assign MC_BACK = B_VALID & B_READY;
	assign MC_WERROR = B_RESP[1];			// 写出错
	

	//############################# 读操作 #################################
	//----------------------------------------------------------------------
	//--   状态机第1段（状态迁移）
	//----------------------------------------------------------------------
	always @(posedge ACLK or negedge ARESETn)begin
		if(!ARESETn)begin
			str_cur <= STR_IDLE;
		end
		else begin     
			str_cur <= str_next;
		end
	end

	//----------------------------------------------------------------------
	//--   状态机第2段（输入对状态的影响）
	//----------------------------------------------------------------------
	always @(*)begin
		str_next = str_cur;
		case(str_cur)
			STR_IDLE: begin						// 读空闲
				if(MC_RREQ)
					str_next = STR_ADDR;
			end
			STR_ADDR: begin						// 读地址通道
				if(AR_READY)
					str_next = STR_DATA;
			end
			STR_DATA: begin						// 读数据通道
				if(R_VALID)
					str_next = STR_END;
			end
			STR_END: begin						// 结束
				str_next = STR_IDLE;
			end
			default:str_next = STR_IDLE;
		endcase
	end

	//----------------------------------------------------------------------
	//--   状态机第3段（状态对输出的影响）
	//----------------------------------------------------------------------
	// AXI信号产生
	always @(posedge ACLK or negedge ARESETn)begin
		if(!ARESETn)begin
			AR_SIZE <= 3'b010;					// 数据宽度为32bit
			AR_BURST <= 2'b01;					// 读数据传输方式INCR
			AR_LEN <= 8'b0;						// 读数据长度为1，Length = AxLEN + 1
			AR_ADDR <= 'h04;
			AR_VALID <= 1'b0;
			R_READY <= 1'b0;
		end
		else begin
			case(str_next)
				STR_IDLE: begin
					AR_VALID <= 1'b0;
					R_READY <= 1'b0;
				end
				STR_ADDR: begin
					AR_ADDR <= MC_RADDR;
					AR_VALID <= 1'b1;
					R_READY <= 1'b0;
				end
				STR_DATA: begin
					AR_VALID <= 1'b0;
					R_READY <= 1'b1;
				end
				STR_END: begin
					AR_VALID <= 1'b0;
					R_READY <= 1'b0;
				end
			endcase
		end
	end

	// MC信号产生
	always @(posedge ACLK or negedge ARESETn)begin
		if(!ARESETn)begin
			MC_RDATA <= 'h0;
			MC_RACK <= 1'd0;
		end
		else begin
			case(str_next)
				STR_IDLE: begin
					MC_RACK <= 1'b0;
				end
				STR_END: begin
					MC_RDATA <= R_DATA;			// 采样数据
					MC_RACK <= R_VALID & R_READY;// 读准备好
				end
			endcase
		end
	end

	assign MC_RERROR = R_RESP[1];				// 读出错

endmodule