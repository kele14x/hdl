`timescale 1 ns / 1 ps
//
`default_nettype none

module oran_framer #(
    parameter int NUM_ETHERNET_PORT = 1,     // Number of Ethernet ports
    parameter int NUM_ANTENNA_PORT  = 2,     // Number of physical antenna ports
    parameter int NUM_CC            = 1,     // Number of carrier component
    //
    parameter int ETH_FIFO_DEPTH    = 1024,
    parameter int ADAPTOR_SIZE      = 1024,
    parameter int BUFFER_SIZE       = 1024
) (
    // Tx Ethernet ports
    //------------------
    input var         tx_eth_clk        [NUM_ETHERNET_PORT],
    input var         tx_eth_rst        [NUM_ETHERNET_PORT],
    // Tx data
    output var [63:0] m_eth_fram_tdata  [NUM_ETHERNET_PORT],
    output var [ 7:0] m_eth_fram_tkeep  [NUM_ETHERNET_PORT],
    output var        m_eth_fram_tvalid [NUM_ETHERNET_PORT],
    output var        m_eth_fram_tlast  [NUM_ETHERNET_PORT],
    input var         m_eth_fram_tready [NUM_ETHERNET_PORT],
    // Internal clock domain
    //----------------------
    input var         internal_bus_clk,
    input var         fram_reset,
    // Ready status
    output var        fram_ready,
    // Lowphy
    input var  [ 7:0] ul_syml_frame     [ NUM_ANTENNA_PORT][NUM_CC],
    input var         ul_syml_sof       [ NUM_ANTENNA_PORT][NUM_CC],
    input var         ul_syml_sos       [ NUM_ANTENNA_PORT][NUM_CC],
    input var  [31:0] ul_syml_data      [ NUM_ANTENNA_PORT][NUM_CC],
    input var         ul_syml_valid     [ NUM_ANTENNA_PORT][NUM_CC],
    // Control I/F
    //------------
    input var         ctrl_clk,
    input var         ctrl_rst,
    //
    input var         ctrl_has_udcomphdr[ NUM_ANTENNA_PORT][NUM_CC],
    input var  [ 3:0] ctrl_ud_comp_meth [ NUM_ANTENNA_PORT][NUM_CC],
    input var  [ 3:0] ctrl_ud_iq_width  [ NUM_ANTENNA_PORT][NUM_CC],
    input var  [11:0] ctrl_syml_rd_shift[ NUM_ANTENNA_PORT][NUM_CC],
    //
    input var  [47:0] ctrl_dest_mac     [NUM_ETHERNET_PORT],
    input var  [47:0] ctrl_src_mac      [NUM_ETHERNET_PORT],
    input var         ctrl_has_vlan     [NUM_ETHERNET_PORT],
    input var  [15:0] ctrl_vlan_tag     [NUM_ETHERNET_PORT],
    //
    input var  [ 3:0] ctrl_buf_wr_addr  [ NUM_ANTENNA_PORT][NUM_CC],
    input var         ctrl_buf_wr_en    [ NUM_ANTENNA_PORT][NUM_CC],
    input var         ctrl_buf_wr_we    [ NUM_ANTENNA_PORT][NUM_CC],
    input var  [31:0] ctrl_buf_wr_din   [ NUM_ANTENNA_PORT][NUM_CC],
    output var [31:0] ctrl_buf_wr_dout  [ NUM_ANTENNA_PORT][NUM_CC],
    //
    input var  [ 4:0] ctrl_mask_wr_addr [ NUM_ANTENNA_PORT][NUM_CC],
    input var         ctrl_mask_wr_en   [ NUM_ANTENNA_PORT][NUM_CC],
    input var         ctrl_mask_wr_we   [ NUM_ANTENNA_PORT][NUM_CC],
    input var  [31:0] ctrl_mask_wr_din  [ NUM_ANTENNA_PORT][NUM_CC],
    output var [31:0] ctrl_mask_wr_dout [ NUM_ANTENNA_PORT][NUM_CC]
);

  logic [                 63:0] s0_axis_tdata [ NUM_ANTENNA_PORT] [NUM_CC];
  logic [                  7:0] s0_axis_tkeep [ NUM_ANTENNA_PORT] [NUM_CC];
  logic                         s0_axis_tvalid[ NUM_ANTENNA_PORT] [NUM_CC];
  logic                         s0_axis_tlast [ NUM_ANTENNA_PORT] [NUM_CC];
  logic                         s0_axis_tready[ NUM_ANTENNA_PORT] [NUM_CC];
  logic [NUM_ETHERNET_PORT-1:0] s0_axis_tuser [ NUM_ANTENNA_PORT] [NUM_CC];

  logic [                 63:0] s1_axis_tdata [NUM_ETHERNET_PORT];
  logic [                  7:0] s1_axis_tkeep [NUM_ETHERNET_PORT];
  logic                         s1_axis_tvalid[NUM_ETHERNET_PORT];
  logic                         s1_axis_tlast [NUM_ETHERNET_PORT];
  logic                         s1_axis_tready[NUM_ETHERNET_PORT];

  assign fram_ready = 1'b1;

  generate
    for (genvar i = 0; i < NUM_ETHERNET_PORT; i++) begin : g_eth

      oran_framer_eth #(
          .FIFO_DEPTH(ETH_FIFO_DEPTH)
      ) i_eth (
          // Tx Ethernet ports
          //------------------
          .tx_eth_clk       (tx_eth_clk[i]),
          .tx_eth_rst       (tx_eth_rst[i]),
          // Tx data
          .m_eth_fram_tdata (m_eth_fram_tdata[i]),
          .m_eth_fram_tkeep (m_eth_fram_tkeep[i]),
          .m_eth_fram_tvalid(m_eth_fram_tvalid[i]),
          .m_eth_fram_tlast (m_eth_fram_tlast[i]),
          .m_eth_fram_tready(m_eth_fram_tready[i]),
          // Internal clock domain
          //----------------------
          .internal_bus_clk (internal_bus_clk),
          .fram_reset       (fram_reset),
          //
          .s_axis_tdata     (s1_axis_tdata[i]),
          .s_axis_tkeep     (s1_axis_tkeep[i]),
          .s_axis_tvalid    (s1_axis_tvalid[i]),
          .s_axis_tlast     (s1_axis_tlast[i]),
          .s_axis_tready    (s1_axis_tready[i]),
          // Control
          //--------
          .ctrl_dest_mac    (ctrl_dest_mac[i]),
          .ctrl_src_mac     (ctrl_src_mac[i]),
          .ctrl_has_vlan    (ctrl_has_vlan[i]),
          .ctrl_vlan_tag    (ctrl_vlan_tag[i])
      );

    end
  endgenerate

  oran_framer_switch #(
      .NUM_ETHERNET_PORT(NUM_ETHERNET_PORT),
      .NUM_ANTENNA_PORT (NUM_ANTENNA_PORT),
      .NUM_CC           (NUM_CC)
  ) i_switch (
      .clk          (internal_bus_clk),
      .rst          (fram_reset),
      //
      .m_axis_tdata (s1_axis_tdata),
      .m_axis_tkeep (s1_axis_tkeep),
      .m_axis_tvalid(s1_axis_tvalid),
      .m_axis_tlast (s1_axis_tlast),
      .m_axis_tready(s1_axis_tready),
      //
      .s_axis_tdata (s0_axis_tdata),
      .s_axis_tkeep (s0_axis_tkeep),
      .s_axis_tvalid(s0_axis_tvalid),
      .s_axis_tlast (s0_axis_tlast),
      .s_axis_tready(s0_axis_tready),
      .s_axis_tuser (s0_axis_tuser)
  );

  generate
    for (genvar i = 0; i < NUM_ANTENNA_PORT; i++) begin : g_ant
      for (genvar cc = 0; cc < NUM_CC; cc++) begin : g_cc

        oran_framer_ul_ss #(
            .PC_ID       (16'(cc * NUM_ANTENNA_PORT + i)),
            .ADAPTOR_SIZE(ADAPTOR_SIZE),
            .BUFFER_SIZE (BUFFER_SIZE)
        ) i_ul_ss (
            // Tx Ethernet ports
            //------------------
            .clk               (internal_bus_clk),
            .rst               (fram_reset),
            // Tx data
            .m_axis_tdata      (s0_axis_tdata[i][cc]),
            .m_axis_tkeep      (s0_axis_tkeep[i][cc]),
            .m_axis_tvalid     (s0_axis_tvalid[i][cc]),
            .m_axis_tlast      (s0_axis_tlast[i][cc]),
            .m_axis_tready     (s0_axis_tready[i][cc]),
            .m_axis_tuser      (s0_axis_tuser[i][cc]),
            //
            .ul_syml_frame     (ul_syml_frame[i][cc]),
            .ul_syml_sof       (ul_syml_sof[i][cc]),
            .ul_syml_sos       (ul_syml_sos[i][cc]),
            .ul_syml_data      (ul_syml_data[i][cc]),
            .ul_syml_valid     (ul_syml_valid[i][cc]),
            // Control I/F
            //------------
            .ctrl_clk          (ctrl_clk),
            .ctrl_rst          (ctrl_rst),
            //
            .ctrl_has_udcomphdr(ctrl_has_udcomphdr[i][cc]),
            .ctrl_ud_comp_meth (ctrl_ud_comp_meth[i][cc]),
            .ctrl_ud_iq_width  (ctrl_ud_iq_width[i][cc]),
            .ctrl_syml_rd_shift(ctrl_syml_rd_shift[i][cc]),
            //
            .ctrl_buf_wr_addr  (ctrl_buf_wr_addr[i][cc]),
            .ctrl_buf_wr_en    (ctrl_buf_wr_en[i][cc]),
            .ctrl_buf_wr_we    (ctrl_buf_wr_we[i][cc]),
            .ctrl_buf_wr_din   (ctrl_buf_wr_din[i][cc]),
            .ctrl_buf_wr_dout  (ctrl_buf_wr_dout[i][cc]),
            //
            .ctrl_mask_wr_addr (ctrl_mask_wr_addr[i][cc]),
            .ctrl_mask_wr_en   (ctrl_mask_wr_en[i][cc]),
            .ctrl_mask_wr_we   (ctrl_mask_wr_we[i][cc]),
            .ctrl_mask_wr_din  (ctrl_mask_wr_din[i][cc]),
            .ctrl_mask_wr_dout (ctrl_mask_wr_dout[i][cc])
        );

      end
    end
  endgenerate

endmodule

`default_nettype wire
