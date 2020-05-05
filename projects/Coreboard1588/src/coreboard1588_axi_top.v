/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

// Note: AxPROT not supported (not connected)

module coreboard1588_axi_top #(
    parameter C_CLOCK_FREQUENCY = 125000000,
    parameter C_PPS_DELAY       = 1250     ,
    parameter C_ADDR_WIDTH      = 10       ,
    parameter C_DATA_WIDTH      = 32
) (
    // AXI4-Lite Slave
    //=================
    (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME aclk, ASSOCIATED_BUSIF S_AXI:UP_WR:UP_RD, ASSOCIATED_RESET aresetn" *)
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 aclk CLK" *)
    input  wire                      aclk            ,
    (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME aresetn, POLARITY ACTIVE_LOW" *)
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 aresetn RST" *)
    input  wire                      aresetn         ,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWADDR" *)
    input  wire [              31:0] s_axi_awaddr    ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWPROT" *)
    input  wire [               2:0] s_axi_awprot    ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWVALID" *)
    input  wire                      s_axi_awvalid   ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWREADY" *)
    output wire                      s_axi_awready   ,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WDATA" *)
    input  wire [  C_DATA_WIDTH-1:0] s_axi_wdata     ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WSTRB" *)
    input  wire [C_DATA_WIDTH/8-1:0] s_axi_wstrb     ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WVALID" *)
    input  wire                      s_axi_wvalid    ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WREADY" *)
    output wire                      s_axi_wready    ,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI BRESP" *)
    output wire [               1:0] s_axi_bresp     ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI BVALID" *)
    output wire                      s_axi_bvalid    ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI BREADY" *)
    input  wire                      s_axi_bready    ,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARADDR" *)
    input  wire [              31:0] s_axi_araddr    ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARPROT" *)
    input  wire [               2:0] s_axi_arprot    ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARVALID" *)
    input  wire                      s_axi_arvalid   ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARREADY" *)
    output wire                      s_axi_arready   ,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RDATA" *)
    output wire [  C_DATA_WIDTH-1:0] s_axi_rdata     ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RRESP" *)
    output wire [               1:0] s_axi_rresp     ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RVALID" *)
    output wire                      s_axi_rvalid    ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RREADY" *)
    input  wire                      s_axi_rready    ,
    // ADS868x I/F
    //============
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S00_AXIS TDATA" *)
    input  wire [              31:0] s00_axis_tdata  ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S00_AXIS TVALID" *)
    input  wire                      s00_axis_tvalid ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S00_AXIS TREADY" *)
    output wire                      s00_axis_tready ,
    // ADS124x I/F
    //============
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S01_AXIS TDATA" *)
    input  wire [              31:0] s01_axis_tdata  ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S01_AXIS TVALID" *)
    input  wire                      s01_axis_tvalid ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S01_AXIS TREADY" *)
    output wire                      s01_axis_tready ,
    // BRAM I/F
    //=========
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram CLK" *)
    output wire                      bram_clk        ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram RST" *)
    output wire                      bram_rst        ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram ADDR" *)
    output wire [              11:0] bram_addr       ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram EN" *)
    output wire                      bram_en         ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram DOUT" *)
    input  wire [              15:0] bram_dout       ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram DIN" *)
    output wire [              15:0] bram_din        ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram WE" *)
    output wire [               1:0] bram_we         ,
    // IRQ
    //====
    output wire                      ts_irq          ,
    // PPS
    //====
    input  wire                      pps_in          ,
    output wire                      pps_out         ,
    // Trigger input
    //==============
    input  wire                      FPGA_EXT_TRIGGER,
    input  wire                      FPGA_TRIGGER_EN
);

    wire [ 9:0] up_wr_addr;
    wire        up_wr_req ;
    wire [ 3:0] up_wr_be  ;
    wire [31:0] up_wr_din ;
    wire        up_wr_ack ;

    wire [ 9:0] up_rd_addr;
    wire        up_rd_req ;
    wire [31:0] up_rd_dout;
    wire        up_rd_ack ;

    wire pps_s;

    wire [31:0] rtc_second    ;
    wire [31:0] rtc_nanosecond;

    wire        ctrl_rtc_mode  ;
    wire [31:0] ctrl_second    ;
    wire [31:0] ctrl_nanosecond;
    wire        ctrl_timeset   ;
    wire        ctrl_timeget   ;

    wire [31:0] stat_second    ;
    wire [31:0] stat_nanosecond;

    wire        ctrl_trigger_enable    ;
    wire [ 1:0] ctrl_trigger_source    ;
    wire [31:0] ctrl_trigger_second    ;
    wire [31:0] ctrl_trigger_nanosecond;

    axi4l_ipif #(
        .C_ADDR_WIDTH(C_ADDR_WIDTH),
        .C_DATA_WIDTH(C_DATA_WIDTH)
    ) i_axi4l_ipif (
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


    coreboard1588_axi_regs #(
        .C_ADDR_WIDTH(C_ADDR_WIDTH),
        .C_DATA_WIDTH(C_DATA_WIDTH)
    ) i_coreboard1588_axi_regs (
        .clk                    (aclk                   ),
        .rst                    (!aresetn               ),
        //
        .up_wr_addr             (up_wr_addr             ),
        .up_wr_req              (up_wr_req              ),
        .up_wr_din              (up_wr_din              ),
        .up_wr_ack              (up_wr_ack              ),
        //
        .up_rd_addr             (up_rd_addr             ),
        .up_rd_req              (up_rd_req              ),
        .up_rd_dout             (up_rd_dout             ),
        .up_rd_ack              (up_rd_ack              ),
        // SCRATCH
        .ctrl_scratch           (                       ),
        // RTC
        .ctrl_rtc_mode          (ctrl_rtc_mode          ),
        .ctrl_second            (ctrl_second            ),
        .ctrl_nanosecond        (ctrl_nanosecond        ),
        .ctrl_timeset           (ctrl_timeset           ),
        .ctrl_timeget           (ctrl_timeget           ),
        //
        .stat_second            (stat_second            ),
        .stat_nanosecond        (stat_nanosecond        ),
        //
        .ctrl_trigger_enable    (ctrl_trigger_enable    ),
        .ctrl_trigger_source    (ctrl_trigger_source    ),
        .ctrl_trigger_second    (ctrl_trigger_second    ),
        .ctrl_trigger_nanosecond(ctrl_trigger_nanosecond)
    );


    pps_receiver #(
        .C_CLOCK_FREQUENCY(C_CLOCK_FREQUENCY),
        .C_PPS_DELAY      (C_PPS_DELAY      )
    ) i_pps_receiver (
        .clk    (aclk    ),
        .rst    (!aresetn),
        .pps_in (pps_in  ),
        .pps_out(pps_s   )
    );


    coreboard1588_axi_rtc i_coreboard1588_axi_rtc (
        .clk            (aclk           ),
        .rst            (!aresetn       ),
        //
        .pps_in         (pps_s          ),
        .pps_out        (pps_out        ),
        //
        .rtc_second     (rtc_second     ),
        .rtc_nanosecond (rtc_nanosecond ),
        //
        .ctrl_rtc_mode  (ctrl_rtc_mode  ),
        .ctrl_second    (ctrl_second    ),
        .ctrl_nanosecond(ctrl_nanosecond),
        .ctrl_timeset   (ctrl_timeset   ),
        .ctrl_timeget   (ctrl_timeget   ),
        //
        .stat_second    (stat_second    ),
        .stat_nanosecond(stat_nanosecond)
    );


    coreboard1588_axi_fmc i_coreboard1588_axi_fmc (
        .aclk                   (aclk                   ),
        .aresetn                (aresetn                ),
        //
        .s00_axis_tdata         (s00_axis_tdata         ),
        .s00_axis_tvalid        (s00_axis_tvalid        ),
        .s00_axis_tready        (s00_axis_tready        ),
        //
        .s01_axis_tdata         (s01_axis_tdata         ),
        .s01_axis_tvalid        (s01_axis_tvalid        ),
        .s01_axis_tready        (s01_axis_tready        ),
        //
        .rtc_second             (rtc_second             ),
        .rtc_nanosecond         (rtc_nanosecond         ),
        //
        .bram_clk               (bram_clk               ),
        .bram_rst               (bram_rst               ),
        .bram_addr              (bram_addr              ),
        .bram_en                (bram_en                ),
        .bram_dout              (bram_dout              ),
        .bram_din               (bram_din               ),
        .bram_we                (bram_we                ),
        //
        .ts_irq                 (ts_irq                 ),
        //
        .FPGA_EXT_TRIGGER       (FPGA_EXT_TRIGGER       ),
        .FPGA_TRIGGER_EN        (FPGA_TRIGGER_EN        ),
        //
        .ctrl_trigger_enable    (ctrl_trigger_enable    ),
        .ctrl_trigger_source    (ctrl_trigger_source    ),
        .ctrl_trigger_second    (ctrl_trigger_second    ),
        .ctrl_trigger_nanosecond(ctrl_trigger_nanosecond)
    );


endmodule

`default_nettype wire
