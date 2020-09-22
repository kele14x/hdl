/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

// AXI Trigger Subsystem
module axi_ts #(parameter AXI_ADDR_WIDTH = 12) (
    input  wire                      aclk         ,
    input  wire                      aresetn      ,
    //
    input  wire [AXI_ADDR_WIDTH-1:0] s_axi_awaddr ,
    input  wire [               2:0] s_axi_awprot ,
    input  wire                      s_axi_awvalid,
    output wire                      s_axi_awready,
    //
    input  wire [              31:0] s_axi_wdata  ,
    input  wire [               3:0] s_axi_wstrb  ,
    input  wire                      s_axi_wvalid ,
    output wire                      s_axi_wready ,
    //
    output wire [               1:0] s_axi_bresp  ,
    output wire                      s_axi_bvalid ,
    input  wire                      s_axi_bready ,
    //
    input  wire [AXI_ADDR_WIDTH-1:0] s_axi_araddr ,
    input  wire [               2:0] s_axi_arprot ,
    input  wire                      s_axi_arvalid,
    output wire                      s_axi_arready,
    //
    output wire [              31:0] s_axi_rdata  ,
    output wire [               1:0] s_axi_rresp  ,
    output wire                      s_axi_rvalid ,
    input  wire                      s_axi_rready ,
    //
    input  wire [              31:0] rtc_sec      ,
    input  wire [              31:0] rtc_nsec     ,
    //
    input  wire [               7:0] ext_trigger  ,
    //
    output wire                      measure_start,
    input  wire                      measure_ready,
    input  wire                      measure_idle ,
    input  wire                      measure_done
);


    axi_ts_top #(.AXI_ADDR_WIDTH(AXI_ADDR_WIDTH)) i_axi_ts_top (
        .aclk         (aclk         ),
        .aresetn      (aresetn      ),
        //
        .s_axi_awaddr (s_axi_awaddr ),
        .s_axi_awprot (s_axi_awprot ),
        .s_axi_awvalid(s_axi_awvalid),
        .s_axi_awready(s_axi_awready),
        //
        .s_axi_wdata  (s_axi_wdata  ),
        .s_axi_wstrb  (s_axi_wstrb  ),
        .s_axi_wvalid (s_axi_wvalid ),
        .s_axi_wready (s_axi_wready ),
        //
        .s_axi_bresp  (s_axi_bresp  ),
        .s_axi_bvalid (s_axi_bvalid ),
        .s_axi_bready (s_axi_bready ),
        //
        .s_axi_araddr (s_axi_araddr ),
        .s_axi_arprot (s_axi_arprot ),
        .s_axi_arvalid(s_axi_arvalid),
        .s_axi_arready(s_axi_arready),
        //
        .s_axi_rdata  (s_axi_rdata  ),
        .s_axi_rresp  (s_axi_rresp  ),
        .s_axi_rvalid (s_axi_rvalid ),
        .s_axi_rready (s_axi_rready ),
        //
        .rtc_sec      (rtc_sec      ),
        .rtc_nsec     (rtc_nsec     ),
        //
        .ext_trigger  (ext_trigger  ),
        //
        .measure_start(measure_start),
        .measure_ready(measure_ready),
        .measure_idle (measure_idle ),
        .measure_done (measure_done )
    );

endmodule

`default_nettype wire
