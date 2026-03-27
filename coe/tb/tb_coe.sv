`timescale 1 ns / 1 ps
//
`default_nettype none

module tb_coe ();

  `include "tb_axi4l.svh"

  // AXI-Lite interface

  logic         s_axi_aclk = 0;
  logic         s_axi_aresetn = 0;
  //
  logic [ 31:0] s_axi_awaddr;
  logic [  2:0] s_axi_awprot;
  logic         s_axi_awvalid;
  logic         s_axi_awready;
  //
  logic [ 31:0] s_axi_wdata;
  logic [  3:0] s_axi_wstrb;
  logic         s_axi_wvalid;
  logic         s_axi_wready;
  //
  logic [  1:0] s_axi_bresp;
  logic         s_axi_bvalid;
  logic         s_axi_bready;
  //
  logic [ 31:0] s_axi_araddr;
  logic [  2:0] s_axi_arprot;
  logic         s_axi_arvalid;
  logic         s_axi_arready;
  //
  logic [ 31:0] s_axi_rdata;
  logic [  1:0] s_axi_rresp;
  logic         s_axi_rvalid;
  logic         s_axi_rready;

  // Ethernet interfaces

  logic         rx_eth_clk = 0;
  logic         rx_eth_rst = 0;

  logic [ 31:0] s_eth_rx_tdata;
  logic [  3:0] s_eth_rx_tkeep;
  logic         s_eth_rx_tlast;
  logic         s_eth_rx_tuser;
  logic         s_eth_rx_tvalid;

  logic         tx_eth_clk = 0;
  logic         tx_eth_rst = 0;

  logic [ 31:0] m_eth_tx_tdata;
  logic [  3:0] m_eth_tx_tkeep;
  logic         m_eth_tx_tlast;
  logic         m_eth_tx_tuser;
  logic         m_eth_tx_tvalid;
  logic         m_eth_tx_tready;

  // PTP interface

  logic [ 79:0] rx_ptp_timestamp;
  logic         rx_ptp_timestamp_valid;

  logic [  1:0] tx_ptp_1588op;
  logic [ 15:0] tx_ptp_tag_field;
  logic [ 79:0] tx_ptp_timestamp;
  logic [ 15:0] tx_ptp_timestamp_tag;
  logic         tx_ptp_timestamp_valid;

  logic [ 79:0] ctl_rx_systemtimer;
  logic [ 79:0] ctl_tx_systemtimer;

  // Internal signals

  logic         clk = 0;
  logic         rst = 0;

  // Timer ports
  logic         pps_in;
  logic [ 47:0] tod_sec;
  logic [ 31:0] tod_ns;

  // Message interface
  logic [ 31:0] m_message_tdata;
  logic [  3:0] m_message_tkeep;
  logic         m_message_tlast;
  logic         m_message_tvalid;
  logic         m_message_tready;

  logic [ 31:0] s_message_tdata;
  logic [  3:0] s_message_tkeep;
  logic         s_message_tlast;
  logic         s_message_tvalid;
  logic         s_message_tready;

  // Radio interface
  logic [767:0] m_axis_rx_tdata;
  logic [  7:0] m_axis_rx_tuser;
  logic         m_axis_rx_tlast;
  logic         m_axis_rx_tvalid;
  logic         m_axis_rx_tready;

  logic [767:0] s_axis_tx_tdata;
  logic [  7:0] s_axis_tx_tuser;
  logic         s_axis_tx_tlast;
  logic         s_axis_tx_tvalid;
  logic         s_axis_tx_tready;

  // Clock generation
  always #5 s_axi_aclk = ~s_axi_aclk;
  always #4 rx_eth_clk = ~rx_eth_clk;
  always #4 tx_eth_clk = ~tx_eth_clk;
  always #1 clk = ~clk;

  // DUT instantiation
  coe DUT (.*);

  // Test stimulus
  initial begin
    logic [31:0] data;
    $display("*** Test started ***");

    // Initialize inputs
    s_axi_aresetn = 0;
    rx_eth_rst = 1;
    tx_eth_rst = 1;
    rst = 1;

    // Default values for AXI-Lite
    axi_reset();

    // Default values for streams
    s_eth_rx_tdata = 0;
    s_eth_rx_tkeep = 0;
    s_eth_rx_tlast = 0;
    s_eth_rx_tuser = 0;
    s_eth_rx_tvalid = 0;

    m_eth_tx_tready = 1;

    rx_ptp_timestamp = 0;
    rx_ptp_timestamp_valid = 0;

    tx_ptp_timestamp = 0;
    tx_ptp_timestamp_tag = 0;
    tx_ptp_timestamp_valid = 0;

    pps_in = 0;
    tod_sec = 0;
    tod_ns = 0;

    m_message_tready = 1;

    s_message_tdata = 0;
    s_message_tkeep = 0;
    s_message_tlast = 0;
    s_message_tvalid = 0;

    m_axis_rx_tready = 1;

    s_axis_tx_tdata = 0;
    s_axis_tx_tuser = 0;
    s_axis_tx_tlast = 0;
    s_axis_tx_tvalid = 0;

    // Wait 100ns for global reset
    #100;

    // Release resets
    s_axi_aresetn = 1;
    rx_eth_rst = 0;
    tx_eth_rst = 0;
    rst = 0;

    // Test case 1: Basic AXI-Lite write/read
    #100;
    @(posedge s_axi_aclk);
    axi_read(32'h0, data);
    if (data !== 32'h20241017) begin
      $fatal("Error: Read data mismatch!");
    end

    axi_write(32'h4, 32'h12345678);
    axi_write(32'h8, 32'h5A5A5A5A);

    axi_read(32'h4, data);
    if (data !== 32'h12345678) begin
      $fatal("Error: Read data mismatch!");
    end

    axi_read(32'h8, data);
    if (data !== 32'h5A5A5A5A) begin
      $fatal("Error: Read data mismatch!");
    end

    $display("Success: AXI-Lite write/read test passed!");

    // Test case 2: Basic frame pattern
    #100;
    @(posedge s_axi_aclk);

    // fram_seq_en
    axi_write(32'h220, 32'h1);
    // fram_seq_id
    axi_write(32'h224, 32'h3F3F3F00);
    axi_write(32'h228, 32'h3F3F3F3F);
    axi_write(32'h22C, 32'h3F3F3F3F);
    axi_write(32'h230, 32'h3F3F3F3F);
    // fram_en
    axi_write(32'h200, 32'h1);

    @(posedge clk);
    pps_in <= 1'b1;
    @(posedge clk);
    pps_in <= 1'b0;

    for (int i = 0; i < 1000; i++) begin
      for (int j = 0; j < 16; j++) begin
        s_axis_tx_tdata  <= 100 + i;
        s_axis_tx_tuser  <= (j == 0);
        s_axis_tx_tlast  <= 0;
        s_axis_tx_tvalid <= 1;
        @(posedge clk);
      end
    end
    s_axis_tx_tvalid <= 0;

    #1000;
    $finish;
  end

  final begin
    $display("*** Test finished ***");
  end

endmodule

`default_nettype wire
