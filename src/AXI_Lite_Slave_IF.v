module AXI_Lite_Slave_IF #(
	parameter integer ADDR_WIDTH = 32,		// 地址宽度
	parameter integer DATA_WIDTH = 32		// 数据位宽
)(
	// 全局信号
	input 	wire 					ACLK,
	input 	wire 					ARESETn,
	input 	wire 					ASEL,
	// 写地址通道
	input 	wire[ADDR_WIDTH-1:0]	AW_ADDR,
	input   wire[7:0]				AW_LEN,
	input   wire[2:0]				AW_SIZE,
	input   wire[1:0]				AW_BURST,
  	input 	wire 					AW_VALID,
	output 	wire 					AW_READY,
	// 写数据通道
	input 	wire[DATA_WIDTH-1:0]  	W_DATA,
	input   wire					W_LAST,
	input 	wire 					W_VALID,
	output 	wire 					W_READY,
	// 写响应通道
	output 	reg[1:0] 				B_RESP,
	output 	reg 					B_VALID,
	input 	wire 					B_READY,
	// 读地址通道
	input 	wire[ADDR_WIDTH-1:0]	AR_ADDR,
	input   wire[7:0]               AR_LEN,
	input   wire[2:0]               AR_SIZE,
	input   wire[1:0]               AR_BURST,
	input 	wire 					AR_VALID,
	output 	wire 					AR_READY,
	// 读数据通道
	output 	reg[DATA_WIDTH-1:0] 	R_DATA,
	output 	reg[1:0] 				R_RESP,
	output  reg						R_LAST,
	output 	reg 					R_VALID,
	input 	wire 					R_READY,

	// 从设备测试信号
	output reg						RF_WREQ,		// 请求
	input wire						RF_WACK,		// 应答
	output reg[ADDR_WIDTH-1:0] 		RF_WADDR,		// 写地址缓存
	output reg[DATA_WIDTH-1:0] 		RF_WDATA,		// 写寄存器缓存
	input wire						RF_WERROR,		// 错误标志
	output reg						RF_RREQ,		// 请求
	input wire						RF_RACK,		// 应答
	output reg[ADDR_WIDTH-1:0] 		RF_RADDR,		// 读地址缓存
	input wire[DATA_WIDTH-1:0]		RF_RDATA,		// 读寄存器缓存
	input wire						RF_RERROR		// 错误标志
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
	reg 					w_addr_over;		// 写地址结束


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
				if(ASEL & AW_VALID)
					stwa_next = STWA_ADDR;
			end
			STWA_ADDR: begin						// 写地址通道
				stwa_next = STWA_WAIT;
			end
			STWA_WAIT: begin						// 写地址同步
				if(B_READY & B_VALID)
					stwa_next = STWA_IDLE;
			end
			default:stwa_next = STWA_IDLE;
		endcase
	end

	//----------------------------------------------------------------------
	//--    写地址状态机第3段（状态对输出的影响）
	//----------------------------------------------------------------------
	// AXI信号产生
	assign AW_READY = (stwa_cur == STWA_ADDR) ? 1'b1 : 1'b0;	// 从设备地址准备好

	// 地址数据同步信号产生
	always @(posedge ACLK or negedge ARESETn)begin
		if(!ARESETn)begin
			w_addr_over <= 1'b0;					// 地址数据同步
		end
		else begin
			case(stwa_next)
				STWA_IDLE: begin
					w_addr_over <= 1'b0;			// 地址数据同步
				end
				STWA_ADDR: begin
					w_addr_over <= 1'b1;			// 地址数据同步
				end
			endcase
		end
	end

	// RF地址信号产生
	always @(posedge ACLK or negedge ARESETn)begin
		if(!ARESETn)begin
			RF_WADDR <= 'h04;
		end
		else if(stwa_next == STWA_ADDR)begin
			RF_WADDR <= AW_ADDR;					// 采样地址
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
			STW_IDLE: begin							// 写数据空闲
				if(ASEL & W_VALID)
					stw_next = STW_DATA;
			end
			STW_DATA: begin							// 写数据通道
				if(RF_WACK)
					stw_next = STW_WAIT;
			end
			STW_WAIT: begin							// 写数据同步
				if(w_addr_over)
					stw_next = STW_RESP;
			end
			STW_RESP: begin							// 写响应通道
				if(B_READY)
					stw_next = STW_IDLE;
			end
			default:stw_next = STW_IDLE;
		endcase
	end

	//----------------------------------------------------------------------
	//--    写数据响应状态机第3段（状态对输出的影响）
	//----------------------------------------------------------------------
	// AXI信号产生
	assign W_READY = RF_WREQ & RF_WACK;
	
	always @(posedge ACLK or negedge ARESETn)begin
		if(!ARESETn)begin
			B_RESP	<= 2'b00;
			B_VALID <= 1'b0;
		end
		else begin
			case(stw_next)
				STW_IDLE: begin
					B_RESP	<= 2'b00;
					B_VALID <= 1'b0;
				end
				STW_DATA: begin
					B_RESP	<= 2'b00;
					B_VALID <= 1'b0;
				end
				STW_WAIT: begin
					B_RESP	<= 2'b00;
					B_VALID <= 1'b0;
				end
				STW_RESP: begin
					B_RESP[1] <= RF_WERROR;
					B_VALID <= 1'b1;
				end
			endcase
		end
	end

	// RF数据信号产生
	always @(posedge ACLK or negedge ARESETn)begin
		if(!ARESETn)begin
			RF_WREQ <= 1'b0;
			RF_WDATA <= 'h0;
		end
		else begin
			case(stw_next)
				STW_IDLE: begin
					RF_WREQ <= 1'b0;
				end
				STW_DATA: begin
					RF_WDATA <= W_DATA;				// 采样写数据
					RF_WREQ <= 1'b1;
				end
				STW_WAIT: begin
					RF_WREQ <= 1'b0;
				end
			endcase
		end
	end


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
			/*
			……补全代码
			*/
			STR_IDLE: begin							// 读空闲
				if(ASEL & AR_VALID)
					str_next = STR_ADDR;
			end
			STR_ADDR: begin							// 读地址通道
				if(RF_RACK)
					str_next = STR_DATA;
			end
			STR_DATA: begin							// 读数据通道
				if(R_READY)
					str_next = STR_END;
			end
			STR_END: begin							// 读结束段
				str_next = STR_IDLE;
			end
			default:str_next = STR_IDLE;
		endcase
	end

	//----------------------------------------------------------------------
	//--   状态机第3段（状态对输出的影响）
	//----------------------------------------------------------------------
	// AXI信号产生
	assign AR_READY = (str_next == STR_ADDR) & AR_VALID;		// 从设备地址准备好

	always @(posedge ACLK or negedge ARESETn)begin
		if(!ARESETn)begin
			R_VALID <= 1'b0;
			R_DATA <=  'h0;
			R_LAST <= 1'b1;			
			R_RESP <= 2'b00;
		end
		else begin
			case(str_next)
				STR_IDLE: begin
					R_VALID <= 1'b0;
					R_RESP <= 2'b00;
				end
				STR_DATA: begin						// 读数据通道
					R_VALID <= 1'b1;
				end
				STR_END: begin
					R_VALID <= 1'b0;
					R_DATA <= RF_RDATA;				// 采样数据
					R_RESP[1] <= RF_RERROR;
				end
			endcase
		end
	end

	// RF信号产生
	always @(posedge ACLK or negedge ARESETn)begin
		if(!ARESETn)begin
			RF_RREQ <= 1'b0;
			RF_RADDR <= 'h04;
		end
		else begin
			case(str_next)
				STR_IDLE: begin
					RF_RREQ <= 1'b0;
				end
				STR_ADDR: begin
					RF_RREQ <= 1'b1;
					RF_RADDR <= AR_ADDR;			// 采样读地址
				end
				STR_END: begin
					RF_RREQ <= 1'b0;
				end
			endcase
		end
	end

endmodule
