/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

// Note: AxPROT not supported (not connected)

module axi4l_ipif #(
    parameter C_ADDR_WIDTH = 12,
    parameter C_DATA_WIDTH = 32
) (
    // AXI4-Lite Slave
    //=================
    (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME aclk, ASSOCIATED_BUSIF S_AXI:UP_WR:UP_RD, ASSOCIATED_RESET aresetn, FREQ_HZ 100000000, PHASE 0.000" *)
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 aclk CLK" *)
    input  wire                      aclk         ,
    (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME aresetn, POLARITY ACTIVE_LOW" *)
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 aresetn RST" *)
    input  wire                      aresetn      ,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWADDR" *)
    input  wire [              31:0] s_axi_awaddr ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWPROT" *)
    input  wire [               2:0] s_axi_awprot ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWVALID" *)
    input  wire                      s_axi_awvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWREADY" *)
    output wire                      s_axi_awready,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WDATA" *)
    input  wire [  C_DATA_WIDTH-1:0] s_axi_wdata  ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WSTRB" *)
    input  wire [C_DATA_WIDTH/8-1:0] s_axi_wstrb  ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WVALID" *)
    input  wire                      s_axi_wvalid ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WREADY" *)
    output wire                      s_axi_wready ,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI BRESP" *)
    output wire [               1:0] s_axi_bresp  ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI BVALID" *)
    output wire                      s_axi_bvalid ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI BREADY" *)
    input  wire                      s_axi_bready ,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARADDR" *)
    input  wire [              31:0] s_axi_araddr ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARPROT" *)
    input  wire [               2:0] s_axi_arprot ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARVALID" *)
    input  wire                      s_axi_arvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARREADY" *)
    output wire                      s_axi_arready,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RDATA" *)
    output wire [  C_DATA_WIDTH-1:0] s_axi_rdata  ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RRESP" *)
    output wire [               1:0] s_axi_rresp  ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RVALID" *)
    output wire                      s_axi_rvalid ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RREADY" *)
    input  wire                      s_axi_rready ,
    // Write i/f
    //-----------
    (* X_INTERFACE_INFO = "jzhl:signal:up_ipif:1.0 UP_WR addr" *)
    output wire [  C_ADDR_WIDTH-3:0] up_wr_addr      ,
    (* X_INTERFACE_INFO = "jzhl:signal:up_ipif:1.0 UP_WR req" *)
    output wire                      up_wr_req       ,
    (* X_INTERFACE_INFO = "jzhl:signal:up_ipif:1.0 UP_WR be" *)
    output wire [               3:0] up_wr_be        ,
    (* X_INTERFACE_INFO = "jzhl:signal:up_ipif:1.0 UP_WR din" *)
    output wire [  C_DATA_WIDTH-1:0] up_wr_din       ,
    (* X_INTERFACE_INFO = "jzhl:signal:up_ipif:1.0 UP_WR ack" *)
    input  wire                      up_wr_ack       ,
    // Read i/f
    //----------
    (* X_INTERFACE_INFO = "jzhl:signal:up_ipif:1.0 UP_RD addr" *)
    output wire [  C_ADDR_WIDTH-3:0] up_rd_addr      ,
    (* X_INTERFACE_INFO = "jzhl:signal:up_ipif:1.0 UP_RD req" *)
    output wire                      up_rd_req       ,
    (* X_INTERFACE_INFO = "jzhl:signal:up_ipif:1.0 UP_RD dout" *)
    input  wire [  C_DATA_WIDTH-1:0] up_rd_dout      ,
    (* X_INTERFACE_INFO = "jzhl:signal:up_ipif:1.0 UP_RD ack" *)
    input  wire                      up_rd_ack
);

    axi4l_ipif_top #(
        .C_ADDR_WIDTH(C_ADDR_WIDTH),
        .C_DATA_WIDTH(C_DATA_WIDTH)
    ) inst (
        .aclk         (aclk         ),
        .aresetn      (aresetn      ),
        //
        .s_axi_awaddr (s_axi_awaddr ),
        .s_axi_awprot (s_axi_awprot ),
        .s_axi_awvalid(s_axi_awvalid),
        .s_axi_awready(s_axi_awready),
        .s_axi_wdata  (s_axi_wdata  ),
        .s_axi_wstrb  (s_axi_wstrb  ),
        .s_axi_wvalid (s_axi_wvalid ),
        .s_axi_wready (s_axi_wready ),
        .s_axi_bresp  (s_axi_bresp  ),
        .s_axi_bvalid (s_axi_bvalid ),
        .s_axi_bready (s_axi_bready ),
        .s_axi_araddr (s_axi_araddr ),
        .s_axi_arprot (s_axi_arprot ),
        .s_axi_arvalid(s_axi_arvalid),
        .s_axi_arready(s_axi_arready),
        .s_axi_rdata  (s_axi_rdata  ),
        .s_axi_rresp  (s_axi_rresp  ),
        .s_axi_rvalid (s_axi_rvalid ),
        .s_axi_rready (s_axi_rready ),
        //
        .up_wr_addr   (up_wr_addr   ),
        .up_wr_req    (up_wr_req    ),
        .up_wr_be     (up_wr_be     ),
        .up_wr_din    (up_wr_din    ),
        .up_wr_ack    (up_wr_ack    ),
        //
        .up_rd_addr   (up_rd_addr   ),
        .up_rd_req    (up_rd_req    ),
        .up_rd_dout   (up_rd_dout   ),
        .up_rd_ack    (up_rd_ack    )
    );

endmodule

`default_nettype wire
