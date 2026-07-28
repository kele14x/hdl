`timescale 1 ns / 1 ps
//
`default_nettype none

module oran_deframer #(
    parameter int FREQUENCY         = 1,
    //
    // Number of Ethernet ports
    parameter int NUM_ETHERNET_PORT = 1,
    // Number of physical antenna ports
    parameter int NUM_ANTENNA_PORT  = 2,
    // Number of carrier component supported
    parameter int NUM_CC            = 1,
    //
    // Ethernet FIFO Depth in 64-bit entries
    parameter int ETH_FIFO_DEPTH    = 1024,
    // Adaptor size in number of REs
    parameter int ADAPTOR_SIZE      = 1024,
    // Buffer size in 64-bit entries
    parameter int BUFFER_SIZE       = 4096,
    // Number of symbol buffer for DL U-Plane
    parameter int BUFFER_SYMBOL     = 10
) (
    // Rx Ethernet ports
    //------------------
    input var         rx_eth_clk             [NUM_ETHERNET_PORT],
    input var         rx_eth_rst             [NUM_ETHERNET_PORT],
    //
    input var  [63:0] s_eth_defm_tdata       [NUM_ETHERNET_PORT],
    input var  [ 7:0] s_eth_defm_tkeep       [NUM_ETHERNET_PORT],
    input var         s_eth_defm_tvalid      [NUM_ETHERNET_PORT],
    input var         s_eth_defm_tlast       [NUM_ETHERNET_PORT],
    input var  [79:0] s_eth_defm_tuser       [NUM_ETHERNET_PORT],
    // Internal clock domain
    //----------------------
    input var         internal_bus_clk,
    input var         defm_reset,
    // Ready status
    output var        defm_ready,
    // Timer
    input var  [ 7:0] timer_frame            [           NUM_CC],
    input var         timer_sof              [           NUM_CC],
    input var         timer_sos              [           NUM_CC],
    input var  [32:0] timer_frac             [           NUM_CC],
    // DL Carrier ports
    output var [ 7:0] dl_syml_frame          [ NUM_ANTENNA_PORT][NUM_CC],
    output var        dl_syml_sof            [ NUM_ANTENNA_PORT][NUM_CC],
    output var        dl_syml_sos            [ NUM_ANTENNA_PORT][NUM_CC],
    output var [32:0] dl_syml_frac           [ NUM_ANTENNA_PORT][NUM_CC],
    output var [31:0] dl_syml_data           [ NUM_ANTENNA_PORT][NUM_CC],
    output var        dl_syml_valid          [ NUM_ANTENNA_PORT][NUM_CC],
    // O-RAN parse ports
    //------------------
    output var        m_mac_header_valid     [NUM_ETHERNET_PORT],
    output var [47:0] m_mac_dest_mac         [NUM_ETHERNET_PORT],
    output var [47:0] m_mac_source_mac       [NUM_ETHERNET_PORT],
    output var        m_mac_with_vlan        [NUM_ETHERNET_PORT],
    output var [15:0] m_mac_vlan_tag         [NUM_ETHERNET_PORT],
    output var [15:0] m_mac_ethertype        [NUM_ETHERNET_PORT],
    //
    output var        m_ecpri_header_valid   [NUM_ETHERNET_PORT],
    output var        m_ecpri_concat         [NUM_ETHERNET_PORT],
    output var [ 7:0] m_ecpri_messagetype    [NUM_ETHERNET_PORT],
    output var [15:0] m_ecpri_payloadsize    [NUM_ETHERNET_PORT],
    //
    output var        m_odm_header_valid     [NUM_ETHERNET_PORT],
    output var [ 7:0] m_odm_measurementid    [NUM_ETHERNET_PORT],
    output var [ 7:0] m_odm_actiontype       [NUM_ETHERNET_PORT],
    output var [79:0] m_odm_timestamp        [NUM_ETHERNET_PORT],
    output var [63:0] m_odm_compensation     [NUM_ETHERNET_PORT],
    output var [79:0] m_odm_timestamp2       [NUM_ETHERNET_PORT],
    //
    output var        m_trans_header_valid   [NUM_ETHERNET_PORT],
    output var [15:0] m_trans_rtc_pc_id      [NUM_ETHERNET_PORT],
    output var [ 7:0] m_trans_seqid          [NUM_ETHERNET_PORT],
    output var        m_trans_ebit           [NUM_ETHERNET_PORT],
    output var [ 6:0] m_trans_subseqid       [NUM_ETHERNET_PORT],
    //
    output var        m_app_header_valid     [ NUM_ANTENNA_PORT][NUM_CC],
    output var        m_app_datadirection    [ NUM_ANTENNA_PORT][NUM_CC],
    output var [ 3:0] m_app_filterindex      [ NUM_ANTENNA_PORT][NUM_CC],
    output var [ 7:0] m_app_frameid          [ NUM_ANTENNA_PORT][NUM_CC],
    output var [ 3:0] m_app_subframeid       [ NUM_ANTENNA_PORT][NUM_CC],
    output var [ 5:0] m_app_slotid           [ NUM_ANTENNA_PORT][NUM_CC],
    output var [ 5:0] m_app_symbolid         [ NUM_ANTENNA_PORT][NUM_CC],
    output var        m_app_packet_in_window [ NUM_ANTENNA_PORT][NUM_CC],
    output var [ 8:0] m_app_offset_in_symbol [ NUM_ANTENNA_PORT][NUM_CC],
    output var [ 7:0] m_app_numsections      [ NUM_ANTENNA_PORT][NUM_CC],
    output var [ 2:0] m_app_sectiontype      [ NUM_ANTENNA_PORT][NUM_CC],
    output var [ 7:0] m_app_udcomphdr        [ NUM_ANTENNA_PORT][NUM_CC],
    output var [15:0] m_app_timeoffset       [ NUM_ANTENNA_PORT][NUM_CC],
    output var [ 7:0] m_app_framestructure   [ NUM_ANTENNA_PORT][NUM_CC],
    output var [15:0] m_app_cplength         [ NUM_ANTENNA_PORT][NUM_CC],
    //
    output var        m_section_header_valid [ NUM_ANTENNA_PORT][NUM_CC],
    output var [11:0] m_section_sectionid    [ NUM_ANTENNA_PORT][NUM_CC],
    output var        m_section_rb           [ NUM_ANTENNA_PORT][NUM_CC],
    output var        m_section_syminc       [ NUM_ANTENNA_PORT][NUM_CC],
    output var [ 9:0] m_section_startprb     [ NUM_ANTENNA_PORT][NUM_CC],
    output var [ 7:0] m_section_numprb       [ NUM_ANTENNA_PORT][NUM_CC],
    output var [ 7:0] m_section_udcomphdr    [ NUM_ANTENNA_PORT][NUM_CC],
    output var [11:0] m_section_remask       [ NUM_ANTENNA_PORT][NUM_CC],
    output var [ 3:0] m_section_numsymbol    [ NUM_ANTENNA_PORT][NUM_CC],
    output var        m_section_ef           [ NUM_ANTENNA_PORT][NUM_CC],
    output var [14:0] m_section_beamid       [ NUM_ANTENNA_PORT][NUM_CC],
    output var [23:0] m_section_freqoffset   [ NUM_ANTENNA_PORT][NUM_CC],
    // Control & Status
    //-----------------
    input var         ctrl_has_udcomphdr     [ NUM_ANTENNA_PORT][NUM_CC],
    input var  [ 3:0] ctrl_ud_comp_meth      [ NUM_ANTENNA_PORT][NUM_CC],
    input var  [ 3:0] ctrl_ud_iq_width       [ NUM_ANTENNA_PORT][NUM_CC],
    input var  [11:0] ctrl_syml_rd_shift     [ NUM_ANTENNA_PORT][NUM_CC],
    input var  [15:0] ctrl_buffer_addr_offset[ NUM_ANTENNA_PORT][NUM_CC][BUFFER_SYMBOL]
);

  localparam int NumDest = NUM_ANTENNA_PORT * NUM_CC;

  // Timing signals for each CC

  logic               start_of_frame       [           NUM_CC];
  logic               start_of_symbol      [           NUM_CC];

  logic [       14:0] current_sample       [           NUM_CC];
  logic [        3:0] current_symbol       [           NUM_CC];
  logic [        4:0] current_subframe_slot[           NUM_CC];

  // AXIS signal

  logic [       63:0] s0_axis_tdata        [NUM_ETHERNET_PORT];
  logic [        7:0] s0_axis_tkeep        [NUM_ETHERNET_PORT];
  logic               s0_axis_tvalid       [NUM_ETHERNET_PORT];
  logic               s0_axis_tlast        [NUM_ETHERNET_PORT];
  logic               s0_axis_tready       [NUM_ETHERNET_PORT];
  logic [NumDest-1:0] s0_axis_tuser        [NUM_ETHERNET_PORT];

  logic [       63:0] s1_axis_tdata        [ NUM_ANTENNA_PORT] [NUM_CC];
  logic [        7:0] s1_axis_tkeep        [ NUM_ANTENNA_PORT] [NUM_CC];
  logic               s1_axis_tvalid       [ NUM_ANTENNA_PORT] [NUM_CC];
  logic               s1_axis_tlast        [ NUM_ANTENNA_PORT] [NUM_CC];


  // Per Ethernet channel
  //---------------------
  // Packet filter & parser

  generate
    for (genvar i = 0; i < NUM_ETHERNET_PORT; i++) begin : g_eth

      oran_deframer_eth #(
          .NUM_DEST  (NumDest),
          .FIFO_DEPTH(ETH_FIFO_DEPTH)
      ) i_eth (
          .rx_eth_clk          (rx_eth_clk[i]),
          .rx_eth_rst          (rx_eth_rst[i]),
          //
          .s_eth_defm_tdata    (s_eth_defm_tdata[i]),
          .s_eth_defm_tkeep    (s_eth_defm_tkeep[i]),
          .s_eth_defm_tvalid   (s_eth_defm_tvalid[i]),
          .s_eth_defm_tlast    (s_eth_defm_tlast[i]),
          .s_eth_defm_tuser    (s_eth_defm_tuser[i]),
          //
          .internal_bus_clk    (internal_bus_clk),
          .defm_reset          (defm_reset),
          //
          .m_axis_tdata        (s0_axis_tdata[i]),
          .m_axis_tkeep        (s0_axis_tkeep[i]),
          .m_axis_tvalid       (s0_axis_tvalid[i]),
          .m_axis_tlast        (s0_axis_tlast[i]),
          .m_axis_tuser        (s0_axis_tuser[i]),
          .m_axis_tready       (s0_axis_tready[i]),
          // O-RAN parse ports
          .m_mac_header_valid  (m_mac_header_valid[i]),
          .m_mac_dest_mac      (m_mac_dest_mac[i]),
          .m_mac_source_mac    (m_mac_source_mac[i]),
          .m_mac_with_vlan     (m_mac_with_vlan[i]),
          .m_mac_vlan_tag      (m_mac_vlan_tag[i]),
          .m_mac_ethertype     (m_mac_ethertype[i]),
          //
          .m_ecpri_header_valid(m_ecpri_header_valid[i]),
          .m_ecpri_concat      (m_ecpri_concat[i]),
          .m_ecpri_messagetype (m_ecpri_messagetype[i]),
          .m_ecpri_payloadsize (m_ecpri_payloadsize[i]),
          //
          .m_odm_header_valid  (m_odm_header_valid[i]),
          .m_odm_measurementid (m_odm_measurementid[i]),
          .m_odm_actiontype    (m_odm_actiontype[i]),
          .m_odm_timestamp     (m_odm_timestamp[i]),
          .m_odm_compensation  (m_odm_compensation[i]),
          .m_odm_timestamp2    (m_odm_timestamp2[i]),
          //
          .m_trans_header_valid(m_trans_header_valid[i]),
          .m_trans_rtc_pc_id   (m_trans_rtc_pc_id[i]),
          .m_trans_seqid       (m_trans_seqid[i]),
          .m_trans_ebit        (m_trans_ebit[i]),
          .m_trans_subseqid    (m_trans_subseqid[i])
      );

    end
  endgenerate


  oran_deframer_switch #(
      .NUM_ETHERNET_PORT(NUM_ETHERNET_PORT),
      .NUM_ANTENNA_PORT (NUM_ANTENNA_PORT),
      .NUM_CC           (NUM_CC)
  ) i_switch (
      .clk          (internal_bus_clk),
      .rst          (defm_reset),
      //
      .s_axis_tdata (s0_axis_tdata),
      .s_axis_tkeep (s0_axis_tkeep),
      .s_axis_tvalid(s0_axis_tvalid),
      .s_axis_tlast (s0_axis_tlast),
      .s_axis_tready(s0_axis_tready),
      .s_axis_tuser (s0_axis_tuser),
      //
      .m_axis_tdata (s1_axis_tdata),
      .m_axis_tkeep (s1_axis_tkeep),
      .m_axis_tvalid(s1_axis_tvalid),
      .m_axis_tlast (s1_axis_tlast)
  );


  // Per Physical Port Channel
  //--------------------------

  generate
    for (genvar i = 0; i < NUM_ANTENNA_PORT; i++) begin : g_ant
      for (genvar cc = 0; cc < NUM_CC; cc++) begin : g_cc

        // TODO: add DL Ctrl
        // TODO: add UL Ctrl

        oran_deframer_dl_ss #(
            .BUFFER_SYMBOL(BUFFER_SYMBOL),
            .ADAPTOR_SIZE (ADAPTOR_SIZE),
            .BUFFER_SIZE  (BUFFER_SIZE)
        ) i_dl_ss (
            .clk                    (internal_bus_clk),
            .rst                    (defm_reset),
            //
            .timer_frame            (timer_frame[cc]),
            .timer_sof              (timer_sof[cc]),
            .timer_sos              (timer_sos[cc]),
            .timer_frac             (timer_frac[cc]),
            //
            .s_axis_tdata           (s1_axis_tdata[i][cc]),
            .s_axis_tkeep           (s1_axis_tkeep[i][cc]),
            .s_axis_tvalid          (s1_axis_tvalid[i][cc]),
            .s_axis_tlast           (s1_axis_tlast[i][cc]),
            // De-framer data
            .dl_syml_frame          (dl_syml_frame[i][cc]),
            .dl_syml_sof            (dl_syml_sof[i][cc]),
            .dl_syml_sos            (dl_syml_sos[i][cc]),
            .dl_syml_frac           (dl_syml_frac[i][cc]),
            .dl_syml_data           (dl_syml_data[i][cc]),
            .dl_syml_valid          (dl_syml_valid[i][cc]),
            //
            .m_app_header_valid     (m_app_header_valid[i][cc]),
            .m_app_datadirection    (m_app_datadirection[i][cc]),
            .m_app_filterindex      (m_app_filterindex[i][cc]),
            .m_app_frameid          (m_app_frameid[i][cc]),
            .m_app_subframeid       (m_app_subframeid[i][cc]),
            .m_app_slotid           (m_app_slotid[i][cc]),
            .m_app_symbolid         (m_app_symbolid[i][cc]),
            .m_app_packet_in_window (m_app_packet_in_window[i][cc]),
            .m_app_offset_in_symbol (m_app_offset_in_symbol[i][cc]),
            .m_app_numsections      (m_app_numsections[i][cc]),
            .m_app_sectiontype      (m_app_sectiontype[i][cc]),
            .m_app_udcomphdr        (m_app_udcomphdr[i][cc]),
            .m_app_timeoffset       (m_app_timeoffset[i][cc]),
            .m_app_framestructure   (m_app_framestructure[i][cc]),
            .m_app_cplength         (m_app_cplength[i][cc]),
            //
            .m_section_header_valid (m_section_header_valid[i][cc]),
            .m_section_sectionid    (m_section_sectionid[i][cc]),
            .m_section_rb           (m_section_rb[i][cc]),
            .m_section_syminc       (m_section_syminc[i][cc]),
            .m_section_startprb     (m_section_startprb[i][cc]),
            .m_section_numprb       (m_section_numprb[i][cc]),
            .m_section_udcomphdr    (m_section_udcomphdr[i][cc]),
            .m_section_remask       (m_section_remask[i][cc]),
            .m_section_numsymbol    (m_section_numsymbol[i][cc]),
            .m_section_ef           (m_section_ef[i][cc]),
            .m_section_beamid       (m_section_beamid[i][cc]),
            .m_section_freqoffset   (m_section_freqoffset[i][cc]),
            //
            .ctrl_has_udcomphdr     (ctrl_has_udcomphdr[i][cc]),
            .ctrl_ud_comp_meth      (ctrl_ud_comp_meth[i][cc]),
            .ctrl_ud_iq_width       (ctrl_ud_iq_width[i][cc]),
            //
            .ctrl_syml_rd_shift     (ctrl_syml_rd_shift[i][cc]),
            .ctrl_buffer_addr_offset(ctrl_buffer_addr_offset[i][cc])
        );

      end
    end
  endgenerate

endmodule

`default_nettype wire
