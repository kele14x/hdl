// File: oran_deframer_eth.sv
// Brief: This module does the following:
//        - Filter out none eCPRI packets
//        - Remove MAC header, which is not useful for following processing
//        - Moves Ethernet packet to `internal_bus_clk` domain
//        - Test if the packet size is correct
//        - Forward packet to next stage
`timescale 1 ns / 1 ps
//
`default_nettype none

module oran_deframer_eth #(
    parameter int NUM_DEST   = 2,
    parameter int FIFO_DEPTH = 1024
) (
    // Ethernet I/F
    //-------------
    input var         rx_eth_clk,
    input var         rx_eth_rst,
    //
    input var  [63:0] s_eth_defm_tdata,
    input var  [ 7:0] s_eth_defm_tkeep,
    input var         s_eth_defm_tvalid,
    input var         s_eth_defm_tlast,
    input var  [79:0] s_eth_defm_tuser,
    // Internal I/F
    //-------------
    input var         internal_bus_clk,
    input var         defm_reset,
    //
    output var [63:0] m_axis_tdata,
    output var [ 7:0] m_axis_tkeep,
    output var        m_axis_tvalid,
    output var        m_axis_tlast,
    output var [ 1:0] m_axis_tuser,
    input var         m_axis_tready,
    // O-RAN parse ports
    //------------------
    output var        m_mac_header_valid,
    output var [47:0] m_mac_dest_mac,
    output var [47:0] m_mac_source_mac,
    output var        m_mac_with_vlan,
    output var [15:0] m_mac_vlan_tag,
    output var [15:0] m_mac_ethertype,
    //
    output var        m_ecpri_header_valid,
    output var        m_ecpri_concat,
    output var [ 7:0] m_ecpri_messagetype,
    output var [15:0] m_ecpri_payloadsize,
    //
    output var        m_odm_header_valid,
    output var [ 7:0] m_odm_measurementid,
    output var [ 7:0] m_odm_actiontype,
    output var [79:0] m_odm_timestamp,
    output var [63:0] m_odm_compensation,
    output var [79:0] m_odm_timestamp2,
    //
    output var        m_trans_header_valid,
    output var [15:0] m_trans_rtc_pc_id,
    output var [ 7:0] m_trans_seqid,
    output var        m_trans_ebit,
    output var [ 6:0] m_trans_subseqid
);

  wire unused_defm_reset = &{1'b0, defm_reset};

  // Signals
  //--------

  logic [63:0] s0_axis_tdata;
  logic [7:0] s0_axis_tkeep;
  logic s0_axis_tvalid;
  logic s0_axis_tlast;
  logic [79:0] s0_axis_tuser;

  logic [63:0] s1_axis_tdata;
  logic [7:0] s1_axis_tkeep;
  logic s1_axis_tvalid;
  logic s1_axis_tlast;
  logic [79:0] s1_axis_tuser;
  logic [1:0] s1_axis_tdest;

  logic [63:0] s2_axis_tdata;
  logic [7:0] s2_axis_tkeep;
  logic s2_axis_tvalid;
  logic s2_axis_tlast;
  logic [1:0] s2_axis_tdest;

  logic [$clog2(FIFO_DEPTH):0] fifo_wr_data_count;
  logic [$clog2(FIFO_DEPTH):0] fifo_rd_data_count;
  logic fifo_s_axis_tready;
  logic fifo_almost_full;
  logic fifo_prog_full;
  logic fifo_m_axis_tid;
  logic [7:0] fifo_m_axis_tstrb;
  logic fifo_m_axis_tuser;
  logic fifo_almost_empty;
  logic fifo_prog_empty;
  logic fifo_sbiterr;
  logic fifo_dbiterr;

  wire unused_fifo_outputs = &{
    1'b0,
    fifo_wr_data_count,
    fifo_rd_data_count,
    fifo_s_axis_tready,
    fifo_almost_full,
    fifo_prog_full,
    fifo_m_axis_tid,
    fifo_m_axis_tstrb,
    fifo_m_axis_tuser,
    fifo_almost_empty,
    fifo_prog_empty,
    fifo_sbiterr,
    fifo_dbiterr
  };

  // Main
  //-----

  oran_deframer_eth_filter i_eth_filter (
      .clk               (rx_eth_clk),
      .rst               (rx_eth_rst),
      //
      .s_axis_tdata      (s_eth_defm_tdata),
      .s_axis_tkeep      (s_eth_defm_tkeep),
      .s_axis_tvalid     (s_eth_defm_tvalid),
      .s_axis_tlast      (s_eth_defm_tlast),
      .s_axis_tuser      (s_eth_defm_tuser),
      //
      .m_axis_tdata      (s0_axis_tdata),
      .m_axis_tkeep      (s0_axis_tkeep),
      .m_axis_tvalid     (s0_axis_tvalid),
      .m_axis_tlast      (s0_axis_tlast),
      .m_axis_tuser      (s0_axis_tuser),
      //
      .m_mac_header_valid(m_mac_header_valid),
      .m_mac_dest_mac    (m_mac_dest_mac),
      .m_mac_source_mac  (m_mac_source_mac),
      .m_mac_with_vlan   (m_mac_with_vlan),
      .m_mac_vlan_tag    (m_mac_vlan_tag),
      .m_mac_ethertype   (m_mac_ethertype)
  );

  oran_deframer_eth_common i_ecpri_common (
      .clk                 (rx_eth_clk),
      .rst                 (rx_eth_rst),
      //
      .s_axis_tdata        (s0_axis_tdata),
      .s_axis_tkeep        (s0_axis_tkeep),
      .s_axis_tvalid       (s0_axis_tvalid),
      .s_axis_tlast        (s0_axis_tlast),
      .s_axis_tuser        (s0_axis_tuser),
      //
      .m_axis_tdata        (s1_axis_tdata),
      .m_axis_tkeep        (s1_axis_tkeep),
      .m_axis_tvalid       (s1_axis_tvalid),
      .m_axis_tlast        (s1_axis_tlast),
      .m_axis_tuser        (s1_axis_tuser),
      .m_axis_tdest        (s1_axis_tdest),
      //
      .m_ecpri_header_valid(m_ecpri_header_valid),
      .m_ecpri_concat      (m_ecpri_concat),
      .m_ecpri_messagetype (m_ecpri_messagetype),
      .m_ecpri_payloadsize (m_ecpri_payloadsize)
  );

  oran_deframer_eth_parser #(
      .NUM_DEST(NUM_DEST)
  ) i_eth_parser (
      .clk                 (rx_eth_clk),
      .rst                 (rx_eth_rst),
      //
      .s_axis_tdata        (s1_axis_tdata),
      .s_axis_tkeep        (s1_axis_tkeep),
      .s_axis_tvalid       (s1_axis_tvalid && (s1_axis_tdest == 2'b00)),
      .s_axis_tlast        (s1_axis_tlast),
      //
      .m_axis_tdata        (s2_axis_tdata),
      .m_axis_tkeep        (s2_axis_tkeep),
      .m_axis_tvalid       (s2_axis_tvalid),
      .m_axis_tlast        (s2_axis_tlast),
      .m_axis_tdest        (s2_axis_tdest),
      // O-RAN parse ports
      .m_trans_header_valid(m_trans_header_valid),
      .m_trans_rtc_pc_id   (m_trans_rtc_pc_id),
      .m_trans_seqid       (m_trans_seqid),
      .m_trans_ebit        (m_trans_ebit),
      .m_trans_subseqid    (m_trans_subseqid)
  );

  // eCPRI

  oran_deframer_eth_odm i_odm (
      .clk                (rx_eth_clk),
      .rst                (rx_eth_rst),
      //
      .s_axis_tdata       (s1_axis_tdata),
      .s_axis_tkeep       (s1_axis_tkeep),
      .s_axis_tvalid      (s1_axis_tvalid && (s1_axis_tdest == 2'b10)),
      .s_axis_tlast       (s1_axis_tlast),
      .s_axis_tuser       (s1_axis_tuser),
      // O-RAN parse ports
      //------------------
      // eCPRI IQ Header
      .m_odm_header_valid (m_odm_header_valid),
      .m_odm_measurementid(m_odm_measurementid),
      .m_odm_actiontype   (m_odm_actiontype),
      .m_odm_timestamp    (m_odm_timestamp),
      .m_odm_compensation (m_odm_compensation),
      .m_odm_timestamp2   (m_odm_timestamp2)
  );


  // FIFO
  // CDC & possible buffer for packet routing,
  // This is fifo is assumed will never be full
  // TODO: use a custom packet FIFO here, it should handle the corrupt packet
  //       (marked with TUSER) and FIFO full case, it should discard entire
  //       packet instead of dropping some data in middle of packet.
`ifdef XILINX
  xpm_fifo_axis #(
      .CASCADE_HEIGHT     (0),
      .CDC_SYNC_STAGES    (2),
      .CLOCKING_MODE      ("independent_clock"),
      .ECC_MODE           ("no_ecc"),
      .FIFO_DEPTH         (FIFO_DEPTH),
      .FIFO_MEMORY_TYPE   ("block"),
      .PACKET_FIFO        ("true"),
      .PROG_EMPTY_THRESH  (10),
      .PROG_FULL_THRESH   (10),
      .RD_DATA_COUNT_WIDTH($clog2(FIFO_DEPTH) + 1),
      .RELATED_CLOCKS     (0),
      .SIM_ASSERT_CHK     (0),
      .TDATA_WIDTH        (64),
      .TDEST_WIDTH        (2),
      .TID_WIDTH          (1),
      .TUSER_WIDTH        (1),
      .USE_ADV_FEATURES   ("0808"),                  // required by packet FIFO
      .WR_DATA_COUNT_WIDTH($clog2(FIFO_DEPTH) + 1)
  ) xpm_fifo_axis_inst (
      .s_aclk            (rx_eth_clk),
      .s_aresetn         (!rx_eth_rst),
      //
      .s_axis_tdata      (s2_axis_tdata),
      .s_axis_tdest      (s2_axis_tdest),
      .s_axis_tid        ('0),
      .s_axis_tkeep      (s2_axis_tkeep),
      .s_axis_tlast      (s2_axis_tlast),
      .s_axis_tstrb      (s2_axis_tkeep),
      .s_axis_tuser      ('0),
      .s_axis_tvalid     (s2_axis_tvalid),
      .s_axis_tready     (fifo_s_axis_tready),
      //
      .injectdbiterr_axis(1'b0),
      .injectsbiterr_axis(1'b0),
      .wr_data_count_axis(fifo_wr_data_count),
      .almost_full_axis  (fifo_almost_full),
      .prog_full_axis    (fifo_prog_full),
      //
      .m_aclk            (internal_bus_clk),
      //
      .m_axis_tdata      (m_axis_tdata),
      .m_axis_tdest      (m_axis_tuser),        // !rename to TUSER after output
      .m_axis_tid        (fifo_m_axis_tid),
      .m_axis_tkeep      (m_axis_tkeep),
      .m_axis_tlast      (m_axis_tlast),
      .m_axis_tready     (m_axis_tready),
      .m_axis_tstrb      (fifo_m_axis_tstrb),
      .m_axis_tuser      (fifo_m_axis_tuser),
      .m_axis_tvalid     (m_axis_tvalid),
      .rd_data_count_axis(fifo_rd_data_count),
      .almost_empty_axis (fifo_almost_empty),
      .prog_empty_axis   (fifo_prog_empty),
      .sbiterr_axis      (fifo_sbiterr),
      .dbiterr_axis      (fifo_dbiterr)
      //
  );
`else
  axis_fifo #(
      .ASYNC_MODE  (1),
      .PACKET_MODE (1),
      .FIFO_DEPTH  (FIFO_DEPTH),
      .FIFO_LATENCY(3),
      .DATA_WIDTH  (64),
      .USER_WIDTH  (2)
  ) axis_fifo_inst (
      .s_axis_aclk   (rx_eth_clk),
      .s_axis_aresetn(!rx_eth_rst),
      .s_axis_tdata  (s2_axis_tdata),
      .s_axis_tkeep  (s2_axis_tkeep),
      .s_axis_tlast  (s2_axis_tlast),
      .s_axis_tuser  (s2_axis_tdest),
      .s_axis_tvalid (s2_axis_tvalid),
      .s_axis_tready (fifo_s_axis_tready),
      .m_axis_aclk   (internal_bus_clk),
      .m_axis_tdata  (m_axis_tdata),
      .m_axis_tkeep  (m_axis_tkeep),
      .m_axis_tlast  (m_axis_tlast),
      .m_axis_tuser  (m_axis_tuser),
      .m_axis_tvalid (m_axis_tvalid),
      .m_axis_tready (m_axis_tready)
  );

  assign fifo_wr_data_count = '0;
  assign fifo_rd_data_count = '0;
  assign fifo_almost_full   = 1'b0;
  assign fifo_prog_full     = 1'b0;
  assign fifo_m_axis_tid    = 1'b0;
  assign fifo_m_axis_tstrb  = '0;
  assign fifo_m_axis_tuser  = 1'b0;
  assign fifo_almost_empty  = 1'b1;
  assign fifo_prog_empty    = 1'b1;
  assign fifo_sbiterr       = 1'b0;
  assign fifo_dbiterr       = 1'b0;
`endif

endmodule

`default_nettype wire
