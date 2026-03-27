`timescale 1 ns / 1 ps
//
`default_nettype none

module tb_fh;

  // AXI-Lite I/F
  //-------------
  logic        s_axi_aclk;
  logic        s_axi_aresetn;
  //
  logic [31:0] s_axi_awaddr;
  logic [ 2:0] s_axi_awprot;
  logic        s_axi_awvalid;
  logic        s_axi_awready;
  //
  logic [31:0] s_axi_wdata;
  logic [ 3:0] s_axi_wstrb;
  logic        s_axi_wvalid;
  logic        s_axi_wready;
  //
  logic [ 1:0] s_axi_bresp;
  logic        s_axi_bvalid;
  logic        s_axi_bready;
  //
  logic [31:0] s_axi_araddr;
  logic [ 2:0] s_axi_arprot;
  logic        s_axi_arvalid;
  logic        s_axi_arready;
  //
  logic [31:0] s_axi_rdata;
  logic [ 1:0] s_axi_rresp;
  logic        s_axi_rvalid;
  logic        s_axi_rready;
  // Ethernet I/F
  //-------------
  // Rx Ethernet ports
  logic        rx_eth_clk;
  logic        rx_eth_rst;
  //
  logic [63:0] s_axis_rx_tdata;
  logic [ 7:0] s_axis_rx_tkeep;
  logic        s_axis_rx_tvalid;
  logic        s_axis_rx_tlast;
  logic        s_axis_rx_tuser;
  // Tx Ethernet ports
  logic        tx_eth_clk;
  logic        tx_eth_rst;
  //
  logic [63:0] m_axis_tx_tdata;
  logic [ 7:0] m_axis_tx_tkeep;
  logic        m_axis_tx_tlast;
  logic        m_axis_tx_tuser;
  logic        m_axis_tx_tvalid;
  logic        m_axis_tx_tready;
  // PTP ports
  logic [79:0] rx_ptp_timestamp;
  logic        rx_ptp_timestamp_valid;
  //
  logic [ 1:0] tx_ptp_1588op;
  logic [15:0] tx_ptp_tag_field;
  //
  logic [79:0] tx_ptp_timestamp;
  logic [15:0] tx_ptp_timestamp_tag;
  logic        tx_ptp_timestamp_valid;
  // PTP Control Interface
  logic [79:0] ctl_rx_systemtimer;
  logic [79:0] ctl_tx_systemtimer;
  // Time Interface
  //-------------------
  logic        timer_clk;
  logic        timer_rst;
  //
  logic        pps_in;
  //
  logic [47:0] tod_sec;
  logic [31:0] tod_ns;
  // Internal interface
  //-------------------
  logic        clk;
  logic        rst;
  // Receive interface
  logic [63:0] m_axis_tdata;
  logic [ 7:0] m_axis_tkeep;
  logic        m_axis_tlast;
  logic        m_axis_tvalid;
  logic        m_axis_tready;
  //
  logic [31:0] m_message_tdata;
  logic [ 3:0] m_message_tkeep;
  logic        m_message_tlast;
  logic        m_message_tvalid;
  logic        m_message_tready;
  // Transmit interface
  logic [63:0] s_axis_tdata;
  logic [ 7:0] s_axis_tkeep;
  logic        s_axis_tlast;
  logic        s_axis_tvalid;
  logic        s_axis_tready;
  //
  logic [31:0] s_message_tdata;
  logic [ 3:0] s_message_tkeep;
  logic        s_message_tlast;
  logic        s_message_tvalid;
  logic        s_message_tready;

  `include "tb_axi4l.svh"

  // Clock & Reset

  initial begin
    s_axi_aclk = 0;
    forever #5 s_axi_aclk = ~s_axi_aclk;
  end

  initial begin
    s_axi_aresetn = 0;
    repeat (10) @(posedge s_axi_aclk);
    s_axi_aresetn <= 1;
  end

  initial begin
    rx_eth_clk = 0;
    forever #(3.2) rx_eth_clk = ~rx_eth_clk;
  end

  initial begin
    rx_eth_rst = 1;
    repeat (10) @(posedge rx_eth_clk);
    rx_eth_rst <= 0;
  end

  initial begin
    tx_eth_clk = 0;
    forever #(3.2) tx_eth_clk = ~tx_eth_clk;
  end

  initial begin
    tx_eth_rst = 1;
    repeat (10) @(posedge tx_eth_clk);
    tx_eth_rst <= 0;
  end

  initial begin
    timer_clk = 0;
    forever #(1.25) timer_clk = ~timer_clk;
  end

  initial begin
    timer_rst = 1;
    repeat (10) @(posedge timer_clk);
    timer_rst <= 0;
  end

  initial begin
    clk = 0;
    forever #(1.667) clk = ~clk;
  end

  initial begin
    rst = 1;
    repeat (10) @(posedge clk);
    rst <= 0;
  end

  // Stimulus

  initial begin
    logic [31:0] data;
    $display("*** Simulation starts ***");
    wait (s_axi_aresetn);

    // Check version register
    axi_read(32'h0, data);
    assert (data == 32'h20230411)
    else $error("Version register mismatch");

    // Check scratch registers
    axi_write(32'h4, 32'h12345678);
    axi_read(32'h4, data);
    assert (data == 32'h12345678)
    else $error("Scratch register 0 mismatch");

    axi_write(32'h8, 32'h9abcdef0);
    axi_read(32'h8, data);
    assert (data == 32'h9abcdef0)
    else $error("Scratch register 1 mismatch");

    // PTP src mac register
    axi_write(32'h314, 32'h22334455);
    axi_write(32'h318, 32'h0011);
    // PTP domain number register
    axi_write(32'h320, 32'h18);
    // PTP log announce interval register
    axi_write(32'h328, 32'hF8);
    // PTP log sync interval register
    axi_write(32'h32C, 32'hF8);
    // PTP control register
    axi_write(32'h310, 32'h1);

    #10000000;
    $finish;
  end

  final begin
    $display("*** Simulation ends ***");
  end

  initial begin
    s_axis_rx_tdata = 0;
    s_axis_rx_tkeep = 0;
    s_axis_rx_tvalid = 0;
    s_axis_rx_tlast = 0;
    s_axis_rx_tuser = 0;

    m_axis_tx_tready = 1;

    rx_ptp_timestamp = 0;
    rx_ptp_timestamp_valid = 0;

    tx_ptp_timestamp = 0;
    tx_ptp_timestamp_tag = 0;
    tx_ptp_timestamp_valid = 0;

    pps_in = 0;
    tod_sec = 0;
    tod_ns = 0;

    m_axis_tready = 1;

    m_message_tready = 1;

    s_axis_tdata = 0;
    s_axis_tkeep = 0;
    s_axis_tlast = 0;
    s_axis_tvalid = 0;

    s_message_tdata = 0;
    s_message_tkeep = 0;
    s_message_tlast = 0;
    s_message_tvalid = 0;
  end

  // DUT

  fh DUT (.*);

endmodule

`default_nettype wire
