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
    input  wire                      aclk         ,
    input  wire                      aresetn      ,
    //
    input  wire [              31:0] s_axi_awaddr ,
    input  wire [               2:0] s_axi_awprot ,
    input  wire                      s_axi_awvalid,
    output wire                      s_axi_awready,
    //
    input  wire [  C_DATA_WIDTH-1:0] s_axi_wdata  ,
    input  wire [C_DATA_WIDTH/8-1:0] s_axi_wstrb  ,
    input  wire                      s_axi_wvalid ,
    output wire                      s_axi_wready ,
    //
    output wire [               1:0] s_axi_bresp  ,
    output wire                      s_axi_bvalid ,
    input  wire                      s_axi_bready ,
    //
    input  wire [              31:0] s_axi_araddr ,
    input  wire [               2:0] s_axi_arprot ,
    input  wire                      s_axi_arvalid,
    output wire                      s_axi_arready,
    //
    output wire [  C_DATA_WIDTH-1:0] s_axi_rdata  ,
    output wire [               1:0] s_axi_rresp  ,
    output wire                      s_axi_rvalid ,
    input  wire                      s_axi_rready ,
    // Write i/f
    //-----------
    output wire [  C_ADDR_WIDTH-3:0] wr_addr      ,
    output wire                      wr_req       ,
    output wire [               3:0] wr_be        ,
    output wire [  C_DATA_WIDTH-1:0] wr_data      ,
    input  wire                      wr_ack       ,
    // Read i/f
    //----------
    output wire [  C_ADDR_WIDTH-3:0] rd_addr      ,
    output wire                      rd_req       ,
    input  wire [  C_DATA_WIDTH-1:0] rd_data      ,
    input  wire                      rd_ack
);

    axi4l_ipif_top #(
        .C_ADDR_WIDTH(C_ADDR_WIDTH),
        .C_DATA_WIDTH(C_DATA_WIDTH)
    ) inst (
        .aclk         (aclk         ),
        .aresetn      (aresetn      ),
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
        .wr_addr      (wr_addr      ),
        .wr_req       (wr_req       ),
        .wr_be        (wr_be        ),
        .wr_data      (wr_data      ),
        .wr_ack       (wr_ack       ),
        .rd_addr      (rd_addr      ),
        .rd_req       (rd_req       ),
        .rd_data      (rd_data      ),
        .rd_ack       (rd_ack       )
    );

endmodule

`default_nettype wire
