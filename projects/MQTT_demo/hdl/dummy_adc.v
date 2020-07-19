/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

module dummy_adc #(parameter C_ADDR_WIDTH = 12) (
    (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME aclk, ASSOCIATED_BUSIF S_AXI:S_AXIS, ASSOCIATED_RESET aresetn" *)
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 aclk CLK" *)
    input  wire        aclk         ,
    (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME aresetn, POLARITY ACTIVE_LOW" *)
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 aresetn RST" *)
    input  wire        aresetn      ,
    // AXI4-Lite Slave
    //=================
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWADDR" *)
    input  wire [31:0] s_axi_awaddr ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWPROT" *)
    input  wire [ 2:0] s_axi_awprot ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWVALID" *)
    input  wire        s_axi_awvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWREADY" *)
    output wire        s_axi_awready,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WDATA" *)
    input  wire [31:0] s_axi_wdata  ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WSTRB" *)
    input  wire [ 3:0] s_axi_wstrb  ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WVALID" *)
    input  wire        s_axi_wvalid ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WREADY" *)
    output wire        s_axi_wready ,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI BRESP" *)
    output wire [ 1:0] s_axi_bresp  ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI BVALID" *)
    output wire        s_axi_bvalid ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI BREADY" *)
    input  wire        s_axi_bready ,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARADDR" *)
    input  wire [31:0] s_axi_araddr ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARPROT" *)
    input  wire [ 2:0] s_axi_arprot ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARVALID" *)
    input  wire        s_axi_arvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARREADY" *)
    output wire        s_axi_arready,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RDATA" *)
    output wire [31:0] s_axi_rdata  ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RRESP" *)
    output wire [ 1:0] s_axi_rresp  ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RVALID" *)
    output wire        s_axi_rvalid ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RREADY" *)
    input  wire        s_axi_rready ,
    //
    (* X_INTERFACE_INFO = "xilinx.com:signal:interrupt:1.0 interrupt INTERRUPT" *)
    (* X_INTERFACE_PARAMETER = "SENSITIVITY EDGE_RISING" *)
    output wire        interrupt    ,
    // AXIS
    //========
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS TDATA" *)
    input  wire [31:0] s_axis_tdata ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS TVALID" *)
    input  wire        s_axis_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS TREADY" *)
    output wire        s_axis_tready
);


    wire [C_ADDR_WIDTH-3:0] up_wr_addr;
    wire                    up_wr_req ;
    wire [             3:0] up_wr_be  ;
    wire [            31:0] up_wr_din ;
    wire                    up_wr_ack ;

    wire [C_ADDR_WIDTH-3:0] up_rd_addr;
    wire                    up_rd_req ;
    wire [            31:0] up_rd_dout;
    wire                    up_rd_ack ;

    wire [31:0] ctrl_scratch;

    wire [31:0] ctrl_ts ;
    wire [31:0] stat_adc;


    axi4l_ipif #(.C_ADDR_WIDTH(C_ADDR_WIDTH)) i_axi4l_ipif (
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


    dummy_adc_regs #(.C_ADDR_WIDTH(C_ADDR_WIDTH-2)) i_dummy_adc_regs (
        .clk         (aclk        ),
        .rst         (~aresetn    ),
        //
        .up_wr_addr  (up_wr_addr  ),
        .up_wr_req   (up_wr_req   ),
        .up_wr_din   (up_wr_din   ),
        .up_wr_ack   (up_wr_ack   ),
        //
        .up_rd_addr  (up_rd_addr  ),
        .up_rd_req   (up_rd_req   ),
        .up_rd_dout  (up_rd_dout  ),
        .up_rd_ack   (up_rd_ack   ),
        //
        .ctrl_scratch(ctrl_scratch),
        //
        .ctrl_ts     (ctrl_ts     ),
        .stat_adc    (stat_adc    )
    );


    dummy_adc_core i_dummy_adc_core (
        .aclk         (aclk         ),
        .aresetn      (aresetn      ),
        //
        .s_axis_tdata (s_axis_tdata ),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        //
        .interrupt    (interrupt    ),
        //
        .ctrl_ts      (ctrl_ts      ),
        .stat_adc     (stat_adc     )
    );

endmodule

`default_nettype wire
