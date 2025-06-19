// AXI4的主机，支持16位的burst传输，数据位宽为32、地址位宽也是32
module axi4_master #(
    parameter ID_WIDTH      = 4,
    parameter ADDR_WIDTH    = 32,
    parameter DATA_WIDTH    = 32,
    parameter BURST_LEN     = 16
)
(
    input logic                         ACLK,
    input logic                         ARESETN,

    // 写地址通道
    output logic [ID_WIDTH-1:0]         M_AXI_AWID,
    output logic [ADDR_WIDTH-1:0]       M_AXI_AWADDR,
    output logic [7:0]                  M_AXI_AWLEN,
    output logic [2:0]                  M_AXI_AWSIZE,
    output logic [1:0]                  M_AXI_AWBURST,
    output logic                        M_AXI_AWVALID,
    input  logic                        M_AXI_AWREADY,

    // 写数据通道
    output logic [DATA_WIDTH-1:0]       M_AXI_WDATA,
    output logic [(DATA_WIDTH/8)-1:0]   M_AXI_WSTRB,
    output logic                        M_AXI_WLAST,
    output logic                        M_AXI_WVALID,
    input  logic                        M_AXI_WREADY,

    // 写响应通道
    input logic [1:0]                   M_AXI_BRESP,
    input logic                         M_AXI_BVALID,
    input logic                         M_AXI_BREADY,

    // 读地址通道
    output logic [ID_WIDTH-1:0]         M_AXI_ARID,
    output logic [ADDR_WIDTH-1:0]       M_AXI_ARADDR,
    output logic [7:0]                  M_AXI_ARLEN,
    output logic [2:0]                  M_AXI_ARSIZE,
    output logic [1:0]                  M_AXI_ARBURST,
    output logic                        M_AXI_ARVALID,
    input  logic                        M_AXI_ARREADY,

    // 读数据通道
    input logic [ID_WIDTH-1:0]          M_AXI_RID,
    input logic [DATA_WIDTH-1:0]        M_AXI_RDATA,
    input logic [1:0]                   M_AXI_RRESP,
    input logic                         M_AXI_RLAST,
    input logic                         M_AXI_RVALID,
    output logic                        M_AXI_RREADY,

    // 控制接口
    input logic                         start_write,
    input logic                         start_read,
    input logic [ADDR_WIDTH-1:0]        target_addr,
    input logic [7:0]                   burst_len,
    input logic [DATA_WIDTH-1:0]        write_data [0:BURST_LEN-1],
    output logic [DATA_WIDTH-1:0]       read_data  [0:BURST_LEN-1],
    output logic                        done
);

// Write Task:
// FSM: IDLE -> SEND_AW -> SEND_W -> WAIT_B -> DONE



endmodule