/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 100 ps
`default_nettype none

module axi_rtc_top #(
    parameter integer AXI_ADDR_WIDTH  = 16       ,
    parameter integer AXI_DATA_WIDTH  = 32       ,
    parameter integer CLOCK_FREQUENCY = 125000000
) (
    // AXI4-Lite Slave I/F
    //====================
    input  var logic                          aclk         ,
    input  var logic                          aresetn      ,
    //
    input  var logic [    AXI_ADDR_WIDTH-1:0] s_axi_awaddr ,
    input  var logic [                   2:0] s_axi_awprot ,
    input  var logic                          s_axi_awvalid,
    output var logic                          s_axi_awready,
    //
    input  var logic [    AXI_DATA_WIDTH-1:0] s_axi_wdata  ,
    input  var logic [(AXI_DATA_WIDTH/8)-1:0] s_axi_wstrb  ,
    input  var logic                          s_axi_wvalid ,
    output var logic                          s_axi_wready ,
    //
    output var logic [                   1:0] s_axi_bresp  ,
    output var logic                          s_axi_bvalid ,
    input  var logic                          s_axi_bready ,
    //
    input  var logic [    AXI_ADDR_WIDTH-1:0] s_axi_araddr ,
    input  var logic [                   2:0] s_axi_arprot ,
    input  var logic                          s_axi_arvalid,
    output var logic                          s_axi_arready,
    //
    output var logic [    AXI_DATA_WIDTH-1:0] s_axi_rdata  ,
    output var logic [                   1:0] s_axi_rresp  ,
    output var logic                          s_axi_rvalid ,
    input  var logic                          s_axi_rready ,
    // RTC Interface
    //==============
    output var logic                          pps_out      ,
    output var logic [                  31:0] rtc_sec      ,
    output var logic [                  31:0] rtc_nsec
);


    logic                      up_wreq ;
    logic [AXI_ADDR_WIDTH-3:0] up_waddr;
    logic [              31:0] up_wdata;
    logic                      up_wack ;
    //
    logic                      up_rreq ;
    logic [AXI_ADDR_WIDTH-3:0] up_raddr;
    logic [              31:0] up_rdata;
    logic                      up_rack ;

    logic        ctrl_rtc_tick    ;
    logic        ctrl_timeset     ;
    logic [31:0] ctrl_timeset_sec ;
    logic [31:0] ctrl_timeset_nsec;

    logic [31:0] stat_rtc_sec ;
    logic [31:0] stat_rtc_nsec;


    (* keep_hierarchy="yes" *)
    up_axi #(.AXI_ADDRESS_WIDTH(AXI_ADDR_WIDTH)) i_up_axi (
        .up_clk        (aclk         ),
        .up_rstn       (aresetn      ),
        //
        .up_axi_awvalid(s_axi_awvalid),
        .up_axi_awaddr (s_axi_awaddr ),
        .up_axi_awready(s_axi_awready),
        //
        .up_axi_wvalid (s_axi_wvalid ),
        .up_axi_wdata  (s_axi_wdata  ),
        .up_axi_wstrb  (s_axi_wstrb  ),
        .up_axi_wready (s_axi_wready ),
        //
        .up_axi_bvalid (s_axi_bvalid ),
        .up_axi_bresp  (s_axi_bresp  ),
        .up_axi_bready (s_axi_bready ),
        //
        .up_axi_arvalid(s_axi_arvalid),
        .up_axi_araddr (s_axi_araddr ),
        .up_axi_arready(s_axi_arready),
        //
        .up_axi_rvalid (s_axi_rvalid ),
        .up_axi_rresp  (s_axi_rresp  ),
        .up_axi_rdata  (s_axi_rdata  ),
        .up_axi_rready (s_axi_rready ),
        //
        .up_wreq       (up_wreq      ),
        .up_waddr      (up_waddr     ),
        .up_wdata      (up_wdata     ),
        .up_wack       (up_wack      ),
        //
        .up_rreq       (up_rreq      ),
        .up_raddr      (up_raddr     ),
        .up_rdata      (up_rdata     ),
        .up_rack       (up_rack      )
    );


    (* keep_hierarchy="yes" *)
    axi_rtc_regs #(.ADDR_WIDTH(AXI_ADDR_WIDTH-2)) i_axi_rtc_regs (
        .up_clk           (aclk             ),
        .up_rstn          (aresetn          ),
        .up_wreq          (up_wreq          ),
        .up_waddr         (up_waddr         ),
        .up_wdata         (up_wdata         ),
        .up_wack          (up_wack          ),
        .up_rreq          (up_rreq          ),
        .up_raddr         (up_raddr         ),
        .up_rdata         (up_rdata         ),
        .up_rack          (up_rack          ),
        //
        .ctrl_rtc_tick    (ctrl_rtc_tick    ),
        .ctrl_timeset     (ctrl_timeset     ),
        .ctrl_timeset_sec (ctrl_timeset_sec ),
        .ctrl_timeset_nsec(ctrl_timeset_nsec),
        //
        .stat_rtc_sec     (stat_rtc_sec     ),
        .stat_rtc_nsec    (stat_rtc_nsec    )
    );


    (* keep_hierarchy="yes" *)
    axi_rtc_core #(.CLOCK_FREQUENCY(CLOCK_FREQUENCY)) i_axi_rtc_core (
        .clk              (aclk             ),
        .rst              (~aresetn         ),
        //
        .pps_out          (pps_out          ),
        //
        .rtc_sec          (rtc_sec          ),
        .rtc_nsec         (rtc_nsec         ),
        //
        .ctrl_rtc_tick    (ctrl_rtc_tick    ),
        .ctrl_timeset     (ctrl_timeset     ),
        .ctrl_timeset_sec (ctrl_timeset_sec ),
        .ctrl_timeset_nsec(ctrl_timeset_nsec),
        //
        .stat_rtc_sec     (stat_rtc_sec     ),
        .stat_rtc_nsec    (stat_rtc_nsec    )
    );


endmodule

`default_nettype wire
