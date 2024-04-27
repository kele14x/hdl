// File: oran_if.sv
// Brief: O-RAN Interface Slave IP Core
`timescale 1 ns / 1 ps
//
`default_nettype none

module oran_if #(
    parameter int FREQUENCY           = 1,
    //
    parameter int NUM_ETHERNET_PORT   = 1,
    parameter int NUM_ANTENNA_PORT    = 2,
    parameter int NUM_CC              = 1,
    //
    parameter int DEFM_ETH_FIFO_DEPTH = 1024,
    parameter int DEFM_ADAPTOR_SIZE   = 1024,
    parameter int DEFM_BUFFER_SIZE    = 4096,
    //
    parameter int FRAM_ETH_FIFO_DEPTH = 1024,
    parameter int FRAM_ADAPTOR_SIZE   = 1024,
    parameter int FRAM_BUFFER_SIZE    = 1024
) (
    // AXI-Lite I/F
    //-------------
    input var         s_axi_aclk,
    input var         s_axi_aresetn,
    //
    input var  [31:0] s_axi_awaddr,
    input var  [ 2:0] s_axi_awprot,
    input var         s_axi_awvalid,
    output var        s_axi_awready,
    //
    input var  [31:0] s_axi_wdata,
    input var  [ 3:0] s_axi_wstrb,
    input var         s_axi_wvalid,
    output var        s_axi_wready,
    //
    output var [ 1:0] s_axi_bresp,
    output var        s_axi_bvalid,
    input var         s_axi_bready,
    //
    input var  [31:0] s_axi_araddr,
    input var  [ 2:0] s_axi_arprot,
    input var         s_axi_arvalid,
    output var        s_axi_arready,
    //
    output var [31:0] s_axi_rdata,
    output var [ 1:0] s_axi_rresp,
    output var        s_axi_rvalid,
    input var         s_axi_rready,
    // interrupt pin
    output var        interrupt,
    // Ethernet I/F
    //-------------
    // Rx Ethernet ports
    input var         rx_eth_clk            [NUM_ETHERNET_PORT],
    input var         rx_eth_rst            [NUM_ETHERNET_PORT],
    //
    input var  [63:0] s_eth_defm_tdata      [NUM_ETHERNET_PORT],
    input var  [ 7:0] s_eth_defm_tkeep      [NUM_ETHERNET_PORT],
    input var         s_eth_defm_tvalid     [NUM_ETHERNET_PORT],
    input var         s_eth_defm_tlast      [NUM_ETHERNET_PORT],
    input var  [79:0] s_eth_defm_tuser      [NUM_ETHERNET_PORT],
    // Tx Ethernet ports
    input var         tx_eth_clk            [NUM_ETHERNET_PORT],
    input var         tx_eth_rst            [NUM_ETHERNET_PORT],
    //
    output var [63:0] m_eth_fram_tdata      [NUM_ETHERNET_PORT],
    output var [ 7:0] m_eth_fram_tkeep      [NUM_ETHERNET_PORT],
    output var        m_eth_fram_tvalid     [NUM_ETHERNET_PORT],
    output var        m_eth_fram_tlast      [NUM_ETHERNET_PORT],
    input var         m_eth_fram_tready     [NUM_ETHERNET_PORT],
    // Internal clock domain
    //----------------------
    // Clocks
    input var         internal_bus_clk,
    //
    input var         defm_reset,
    input var         fram_reset,
    // Timer
    input var  [ 7:0] timer_frame           [           NUM_CC],
    input var         timer_sof             [           NUM_CC],
    input var         timer_sos             [           NUM_CC],
    input var  [32:0] timer_frac            [           NUM_CC],
    // Ready status
    output var        defm_ready,
    output var        fram_ready,
    // DL Carrier ports
    output var [ 7:0] dl_syml_frame         [ NUM_ANTENNA_PORT][NUM_CC],
    output var        dl_syml_sof           [ NUM_ANTENNA_PORT][NUM_CC],
    output var        dl_syml_sos           [ NUM_ANTENNA_PORT][NUM_CC],
    output var [32:0] dl_syml_frac          [ NUM_ANTENNA_PORT][NUM_CC],
    output var [31:0] dl_syml_data          [ NUM_ANTENNA_PORT][NUM_CC],
    output var        dl_syml_valid         [ NUM_ANTENNA_PORT][NUM_CC],
    // UL Carrier ports
    input var  [ 7:0] ul_syml_frame         [ NUM_ANTENNA_PORT][NUM_CC],
    input var         ul_syml_sof           [ NUM_ANTENNA_PORT][NUM_CC],
    input var         ul_syml_sos           [ NUM_ANTENNA_PORT][NUM_CC],
    input var  [31:0] ul_syml_data          [ NUM_ANTENNA_PORT][NUM_CC],
    input var         ul_syml_valid         [ NUM_ANTENNA_PORT][NUM_CC],
    // O-RAN parse ports
    //------------------
    output var        m_mac_header_valid    [NUM_ETHERNET_PORT],
    output var [47:0] m_mac_dest_mac        [NUM_ETHERNET_PORT],
    output var [47:0] m_mac_source_mac      [NUM_ETHERNET_PORT],
    output var        m_mac_with_vlan       [NUM_ETHERNET_PORT],
    output var [15:0] m_mac_vlan_tag        [NUM_ETHERNET_PORT],
    output var [15:0] m_mac_ethertype       [NUM_ETHERNET_PORT],
    //
    output var        m_ecpri_header_valid  [NUM_ETHERNET_PORT],
    output var        m_ecpri_concat        [NUM_ETHERNET_PORT],
    output var [ 7:0] m_ecpri_messagetype   [NUM_ETHERNET_PORT],
    output var [15:0] m_ecpri_payloadsize   [NUM_ETHERNET_PORT],
    //
    output var        m_odm_header_valid    [NUM_ETHERNET_PORT],
    output var [ 7:0] m_odm_measurementid   [NUM_ETHERNET_PORT],
    output var [ 7:0] m_odm_actiontype      [NUM_ETHERNET_PORT],
    output var [79:0] m_odm_timestamp       [NUM_ETHERNET_PORT],
    output var [63:0] m_odm_compensation    [NUM_ETHERNET_PORT],
    output var [79:0] m_odm_timestamp2      [NUM_ETHERNET_PORT],
    //
    output var        m_trans_header_valid  [NUM_ETHERNET_PORT],
    output var [15:0] m_trans_rtc_pc_id     [NUM_ETHERNET_PORT],
    output var [ 7:0] m_trans_seqid         [NUM_ETHERNET_PORT],
    output var        m_trans_ebit          [NUM_ETHERNET_PORT],
    output var [ 6:0] m_trans_subseqid      [NUM_ETHERNET_PORT],
    //
    output var        m_app_header_valid    [ NUM_ANTENNA_PORT][NUM_CC],
    output var        m_app_datadirection   [ NUM_ANTENNA_PORT][NUM_CC],
    output var [ 3:0] m_app_filterindex     [ NUM_ANTENNA_PORT][NUM_CC],
    output var [ 7:0] m_app_frameid         [ NUM_ANTENNA_PORT][NUM_CC],
    output var [ 3:0] m_app_subframeid      [ NUM_ANTENNA_PORT][NUM_CC],
    output var [ 5:0] m_app_slotid          [ NUM_ANTENNA_PORT][NUM_CC],
    output var [ 5:0] m_app_symbolid        [ NUM_ANTENNA_PORT][NUM_CC],
    output var        m_app_packet_in_window[ NUM_ANTENNA_PORT][NUM_CC],
    output var [ 8:0] m_app_offset_in_symbol[ NUM_ANTENNA_PORT][NUM_CC],
    output var [ 7:0] m_app_numsections     [ NUM_ANTENNA_PORT][NUM_CC],
    output var [ 2:0] m_app_sectiontype     [ NUM_ANTENNA_PORT][NUM_CC],
    output var [ 7:0] m_app_udcomphdr       [ NUM_ANTENNA_PORT][NUM_CC],
    output var [15:0] m_app_timeoffset      [ NUM_ANTENNA_PORT][NUM_CC],
    output var [ 7:0] m_app_framestructure  [ NUM_ANTENNA_PORT][NUM_CC],
    output var [15:0] m_app_cplength        [ NUM_ANTENNA_PORT][NUM_CC],
    //
    output var        m_section_header_valid[ NUM_ANTENNA_PORT][NUM_CC],
    output var [11:0] m_section_sectionid   [ NUM_ANTENNA_PORT][NUM_CC],
    output var        m_section_rb          [ NUM_ANTENNA_PORT][NUM_CC],
    output var        m_section_syminc      [ NUM_ANTENNA_PORT][NUM_CC],
    output var [ 9:0] m_section_startprb    [ NUM_ANTENNA_PORT][NUM_CC],
    output var [ 7:0] m_section_numprb      [ NUM_ANTENNA_PORT][NUM_CC],
    output var [ 7:0] m_section_udcomphdr   [ NUM_ANTENNA_PORT][NUM_CC],
    output var [11:0] m_section_remask      [ NUM_ANTENNA_PORT][NUM_CC],
    output var [ 3:0] m_section_numsymbol   [ NUM_ANTENNA_PORT][NUM_CC],
    output var        m_section_ef          [ NUM_ANTENNA_PORT][NUM_CC],
    output var [14:0] m_section_beamid      [ NUM_ANTENNA_PORT][NUM_CC],
    output var [23:0] m_section_freqoffset  [ NUM_ANTENNA_PORT][NUM_CC]
);

  localparam int DefmBufferSymbol = 10;

  logic        defm_ctrl_has_udcomphdr_out;
  logic [ 3:0] defm_ctrl_udcompmeth_out;
  logic [ 3:0] defm_ctrl_udiqwidth_out;
  logic [11:0] defm_syml_rd_shift_val_out;

  logic        fram_ctrl_has_udcomphdr_out;
  logic [ 3:0] fram_ctrl_udcompmeth_out;
  logic [ 3:0] fram_ctrl_udiqwidth_out;
  logic [10:0] fram_syml_rd_shift_val_out;

  logic [31:0] defm_src_mac_l_val_in;
  logic [15:0] defm_src_mac_h_val_in;

  logic [15:0] defm_buffer_addr_offset_val_out[ DefmBufferSymbol];

  logic [31:0] fram_dest_mac_l_val_out;
  logic [15:0] fram_dest_mac_h_val_out;
  logic [31:0] fram_src_mac_l_val_out;
  logic [15:0] fram_src_mac_h_val_out;
  logic        fram_vlan_ctrl_has_vlan_out;
  logic [15:0] fram_vlan_ctrl_vlan_tag_out;

  logic        ctrl_defm_ctrl_en;
  logic        ctrl_fram_ctrl_en;

  logic        ctrl_tick_snap;
  logic        ctrl_tick_clear;

  logic        ctrl_has_udcomphdr             [ NUM_ANTENNA_PORT] [NUM_CC];
  logic [ 3:0] ctrl_ud_comp_meth              [ NUM_ANTENNA_PORT] [NUM_CC];
  logic [ 3:0] ctrl_ud_iq_width               [ NUM_ANTENNA_PORT] [NUM_CC];

  logic [11:0] ctrl_defm_syml_rd_shift        [ NUM_ANTENNA_PORT] [NUM_CC];

  logic        ctrl_fram_has_udcomphdr        [ NUM_ANTENNA_PORT] [NUM_CC];
  logic [ 3:0] ctrl_fram_ud_comp_meth         [ NUM_ANTENNA_PORT] [NUM_CC];
  logic [ 3:0] ctrl_fram_ud_iq_width          [ NUM_ANTENNA_PORT] [NUM_CC];

  logic [11:0] ctrl_fram_syml_rd_shift        [ NUM_ANTENNA_PORT] [NUM_CC];

  logic [15:0] ctrl_buffer_addr_offset        [ NUM_ANTENNA_PORT] [NUM_CC] [DefmBufferSymbol];

  logic [47:0] ctrl_fram_dest_mac             [NUM_ETHERNET_PORT];
  logic [47:0] ctrl_fram_src_mac              [NUM_ETHERNET_PORT];
  logic        ctrl_fram_has_vlan             [NUM_ETHERNET_PORT];
  logic [15:0] ctrl_fram_vlan_tag             [NUM_ETHERNET_PORT];

  logic [ 3:0] ctrl_buf_wr_addr               [ NUM_ANTENNA_PORT] [NUM_CC];
  logic        ctrl_buf_wr_en                 [ NUM_ANTENNA_PORT] [NUM_CC];
  logic        ctrl_buf_wr_we                 [ NUM_ANTENNA_PORT] [NUM_CC];
  logic [31:0] ctrl_buf_wr_din                [ NUM_ANTENNA_PORT] [NUM_CC];
  logic [31:0] ctrl_buf_wr_dout               [ NUM_ANTENNA_PORT] [NUM_CC];

  logic [ 4:0] ctrl_mask_wr_addr              [ NUM_ANTENNA_PORT] [NUM_CC];
  logic        ctrl_mask_wr_en                [ NUM_ANTENNA_PORT] [NUM_CC];
  logic        ctrl_mask_wr_we                [ NUM_ANTENNA_PORT] [NUM_CC];
  logic [31:0] ctrl_mask_wr_din               [ NUM_ANTENNA_PORT] [NUM_CC];
  logic [31:0] ctrl_mask_wr_dout              [ NUM_ANTENNA_PORT] [NUM_CC];

  logic [47:0] stat_total_pkt_cnt;
  logic [47:0] stat_oran_pkt_cnt;
  logic [47:0] stat_ontime_pkt_cnt;
  logic [47:0] stat_early_pkt_cnt;
  logic [47:0] stat_late_pkt_cnt;

  logic [ 8:0] stat_earliest_u_pkt;
  logic [ 8:0] stat_latest_u_pkt;


  oran_slave_regs i_regs (
      .s_axi_aclk                       (s_axi_aclk),
      .s_axi_aresetn                    (s_axi_aresetn),
      //
      .s_axi_awaddr                     (s_axi_awaddr),
      .s_axi_awprot                     (s_axi_awprot),
      .s_axi_awvalid                    (s_axi_awvalid),
      .s_axi_awready                    (s_axi_awready),
      //
      .s_axi_wdata                      (s_axi_wdata),
      .s_axi_wstrb                      (s_axi_wstrb),
      .s_axi_wvalid                     (s_axi_wvalid),
      .s_axi_wready                     (s_axi_wready),
      //
      .s_axi_bresp                      (s_axi_bresp),
      .s_axi_bvalid                     (s_axi_bvalid),
      .s_axi_bready                     (s_axi_bready),
      //
      .s_axi_araddr                     (s_axi_araddr),
      .s_axi_arprot                     (s_axi_arprot),
      .s_axi_arvalid                    (s_axi_arvalid),
      .s_axi_arready                    (s_axi_arready),
      //
      .s_axi_rdata                      (s_axi_rdata),
      .s_axi_rresp                      (s_axi_rresp),
      .s_axi_rvalid                     (s_axi_rvalid),
      .s_axi_rready                     (s_axi_rready),
      // tick.tick,
      .tick_tick_out                    (ctrl_tick_snap),
      // tick.clear,
      .tick_clear_out                   (ctrl_tick_clear),
      // defm_ctrl.en,
      .defm_ctrl_en_out                 (ctrl_defm_ctrl_en),
      // defm_ctrl.has_udcomphdr,
      .defm_ctrl_has_udcomphdr_out      (defm_ctrl_has_udcomphdr_out),
      // defm_ctrl.udcompmeth,
      .defm_ctrl_udcompmeth_out         (defm_ctrl_udcompmeth_out),
      // defm_ctrl.udiqwidth,
      .defm_ctrl_udiqwidth_out          (defm_ctrl_udiqwidth_out),
      // defm_syml_rd_shift.val,
      .defm_syml_rd_shift_val_out       (defm_syml_rd_shift_val_out),
      // defm_src_mac_l.val,
      .defm_src_mac_l_val_in            (defm_src_mac_l_val_in),
      // defm_src_mac_h.val,
      .defm_src_mac_h_val_in            (defm_src_mac_h_val_in),
      // defm_buffer_addr_offset_0.val,
      .defm_buffer_addr_offset_0_val_out(defm_buffer_addr_offset_val_out[0]),
      // defm_buffer_addr_offset_1.val,
      .defm_buffer_addr_offset_1_val_out(defm_buffer_addr_offset_val_out[1]),
      // defm_buffer_addr_offset_2.val,
      .defm_buffer_addr_offset_2_val_out(defm_buffer_addr_offset_val_out[2]),
      // defm_buffer_addr_offset_3.val,
      .defm_buffer_addr_offset_3_val_out(defm_buffer_addr_offset_val_out[3]),
      // defm_buffer_addr_offset_4.val,
      .defm_buffer_addr_offset_4_val_out(defm_buffer_addr_offset_val_out[4]),
      // defm_buffer_addr_offset_5.val,
      .defm_buffer_addr_offset_5_val_out(defm_buffer_addr_offset_val_out[5]),
      // defm_buffer_addr_offset_6.val,
      .defm_buffer_addr_offset_6_val_out(defm_buffer_addr_offset_val_out[6]),
      // defm_buffer_addr_offset_7.val,
      .defm_buffer_addr_offset_7_val_out(defm_buffer_addr_offset_val_out[7]),
      // defm_buffer_addr_offset_8.val,
      .defm_buffer_addr_offset_8_val_out(defm_buffer_addr_offset_val_out[8]),
      // defm_buffer_addr_offset_9.val,
      .defm_buffer_addr_offset_9_val_out(defm_buffer_addr_offset_val_out[9]),
      // total_pkt_cnt_lo.val,
      .total_pkt_cnt_lo_val_in          (stat_total_pkt_cnt[31:0]),
      // total_pkt_cnt_hi.val,
      .total_pkt_cnt_hi_val_in          (stat_total_pkt_cnt[47:32]),
      // oran_pkt_cnt_lo.val,
      .oran_pkt_cnt_lo_val_in           (stat_oran_pkt_cnt[31:0]),
      // oran_pkt_cnt_hi.val,
      .oran_pkt_cnt_hi_val_in           (stat_oran_pkt_cnt[47:32]),
      // ontime_pkt_cnt_lo.val,
      .ontime_pkt_cnt_lo_val_in         (stat_ontime_pkt_cnt[31:0]),
      // ontime_pkt_cnt_hi.val,
      .ontime_pkt_cnt_hi_val_in         (stat_ontime_pkt_cnt[47:32]),
      // early_pkt_cnt_lo.val,
      .early_pkt_cnt_lo_val_in          (stat_early_pkt_cnt[31:0]),
      // early_pkt_cnt_hi.val,
      .early_pkt_cnt_hi_val_in          (stat_early_pkt_cnt[47:32]),
      // late_pkt_cnt_lo.val,
      .late_pkt_cnt_lo_val_in           (stat_late_pkt_cnt[31:0]),
      // late_pkt_cnt_hi.val,
      .late_pkt_cnt_hi_val_in           (stat_late_pkt_cnt[47:32]),
      // earliest_u_pkt.val,
      .earliest_u_pkt_val_in            (stat_earliest_u_pkt),
      // latest_u_pkt.val,
      .latest_u_pkt_val_in              (stat_latest_u_pkt),
      // fram_ctrl.en,
      .fram_ctrl_en_out                 (ctrl_fram_ctrl_en),
      // fram_ctrl.has_udcomphdr,
      .fram_ctrl_has_udcomphdr_out      (fram_ctrl_has_udcomphdr_out),
      // fram_ctrl.udcompmeth,
      .fram_ctrl_udcompmeth_out         (fram_ctrl_udcompmeth_out),
      // fram_ctrl.udiqwidth,
      .fram_ctrl_udiqwidth_out          (fram_ctrl_udiqwidth_out),
      // fram_syml_rd_shift.val,
      .fram_syml_rd_shift_val_out       (fram_syml_rd_shift_val_out),
      // fram_dest_mac_l.val,
      .fram_dest_mac_l_val_out          (fram_dest_mac_l_val_out),
      // fram_dest_mac_h.val,
      .fram_dest_mac_h_val_out          (fram_dest_mac_h_val_out),
      // fram_src_mac_l.val,
      .fram_src_mac_l_val_out           (fram_src_mac_l_val_out),
      // fram_src_mac_h.val,
      .fram_src_mac_h_val_out           (fram_src_mac_h_val_out),
      // fram_vlan_ctrl.vlan_tag,
      .fram_vlan_ctrl_vlan_tag_out      (fram_vlan_ctrl_vlan_tag_out),
      // fram_vlan_ctrl.has_vlan,
      .fram_vlan_ctrl_has_vlan_out      (fram_vlan_ctrl_has_vlan_out),
      // fram_ctrl_buf0
      .fram_ctrl_buf0_addr              (ctrl_buf_wr_addr[0][0]),
      .fram_ctrl_buf0_en                (ctrl_buf_wr_en[0][0]),
      .fram_ctrl_buf0_we                (ctrl_buf_wr_we[0][0]),
      .fram_ctrl_buf0_din               (ctrl_buf_wr_din[0][0]),
      .fram_ctrl_buf0_dout              (ctrl_buf_wr_dout[0][0]),
      // fram_mask_buf0
      .fram_mask_buf0_addr              (ctrl_mask_wr_addr[0][0]),
      .fram_mask_buf0_en                (ctrl_mask_wr_en[0][0]),
      .fram_mask_buf0_we                (ctrl_mask_wr_we[0][0]),
      .fram_mask_buf0_din               (ctrl_mask_wr_din[0][0]),
      .fram_mask_buf0_dout              (ctrl_mask_wr_dout[0][0]),
      // fram_ctrl_buf1
      .fram_ctrl_buf1_addr              (ctrl_buf_wr_addr[1][0]),
      .fram_ctrl_buf1_en                (ctrl_buf_wr_en[1][0]),
      .fram_ctrl_buf1_we                (ctrl_buf_wr_we[1][0]),
      .fram_ctrl_buf1_din               (ctrl_buf_wr_din[1][0]),
      .fram_ctrl_buf1_dout              (ctrl_buf_wr_dout[1][0]),
      // fram_mask_buf1
      .fram_mask_buf1_addr              (ctrl_mask_wr_addr[1][0]),
      .fram_mask_buf1_en                (ctrl_mask_wr_en[1][0]),
      .fram_mask_buf1_we                (ctrl_mask_wr_we[1][0]),
      .fram_mask_buf1_din               (ctrl_mask_wr_din[1][0]),
      .fram_mask_buf1_dout              (ctrl_mask_wr_dout[1][0])
  );

  always_ff @(posedge rx_eth_clk[0]) begin
    if (m_mac_header_valid[0]) begin
      defm_src_mac_l_val_in <= m_mac_source_mac[0][31:0];
      defm_src_mac_h_val_in <= m_mac_source_mac[0][47:32];
    end
  end

  generate
    for (genvar a = 0; a < NUM_ANTENNA_PORT; a++) begin : g_a
      for (genvar cc = 0; cc < NUM_CC; cc++) begin : g_cc
        assign ctrl_has_udcomphdr[a][cc]      = defm_ctrl_has_udcomphdr_out;
        assign ctrl_ud_comp_meth[a][cc]       = defm_ctrl_udcompmeth_out;
        assign ctrl_ud_iq_width[a][cc]        = defm_ctrl_udiqwidth_out;

        assign ctrl_defm_syml_rd_shift[a][cc] = defm_syml_rd_shift_val_out;

        assign ctrl_fram_has_udcomphdr[a][cc] = fram_ctrl_has_udcomphdr_out;
        assign ctrl_fram_ud_comp_meth[a][cc]  = fram_ctrl_udcompmeth_out;
        assign ctrl_fram_ud_iq_width[a][cc]   = fram_ctrl_udiqwidth_out;

        assign ctrl_fram_syml_rd_shift[a][cc] = fram_syml_rd_shift_val_out;

        for (genvar s = 0; s < DefmBufferSymbol; s++) begin : g_dl_sym
          assign ctrl_buffer_addr_offset[a][cc][s] = defm_buffer_addr_offset_val_out[s];
        end
      end
    end
  endgenerate

  generate
    for (genvar e = 0; e < NUM_ETHERNET_PORT; e++) begin : g_e
      // assign ctrl_fram_dest_mac[e] = {fram_dest_mac_h_val_out, fram_dest_mac_l_val_out};
      always_ff @(posedge rx_eth_clk[e]) begin
        if (m_mac_header_valid[e] && m_mac_ethertype[e] == 16'hAEFE) begin
          ctrl_fram_dest_mac[e] <= m_mac_source_mac[e];
        end
      end
      assign ctrl_fram_src_mac[e]  = {fram_src_mac_h_val_out, fram_src_mac_l_val_out};
      assign ctrl_fram_has_vlan[e] = fram_vlan_ctrl_has_vlan_out;
      assign ctrl_fram_vlan_tag[e] = fram_vlan_ctrl_vlan_tag_out;
    end
  endgenerate

  oran_deframer #(
      .FREQUENCY        (FREQUENCY),
      //
      .NUM_ETHERNET_PORT(NUM_ETHERNET_PORT),
      .NUM_ANTENNA_PORT (NUM_ANTENNA_PORT),
      .NUM_CC           (NUM_CC),
      //
      .ETH_FIFO_DEPTH   (DEFM_ETH_FIFO_DEPTH),
      .ADAPTOR_SIZE     (DEFM_ADAPTOR_SIZE),
      .BUFFER_SIZE      (DEFM_BUFFER_SIZE),
      .BUFFER_SYMBOL    (DefmBufferSymbol)
  ) i_dl (
      // Rx Ethernet ports
      //------------------
      .rx_eth_clk             (rx_eth_clk),
      .rx_eth_rst             (rx_eth_rst),
      //
      .s_eth_defm_tdata       (s_eth_defm_tdata),
      .s_eth_defm_tkeep       (s_eth_defm_tkeep),
      .s_eth_defm_tvalid      (s_eth_defm_tvalid),
      .s_eth_defm_tlast       (s_eth_defm_tlast),
      .s_eth_defm_tuser       (s_eth_defm_tuser),
      // Internal clock domain
      //----------------------
      .internal_bus_clk       (internal_bus_clk),
      .defm_reset             (defm_reset),
      // Ready status
      .defm_ready             (defm_ready),
      // Timer
      .timer_frame            (timer_frame),
      .timer_sof              (timer_sof),
      .timer_sos              (timer_sos),
      .timer_frac             (timer_frac),
      // DL Carrier ports
      .dl_syml_frame          (dl_syml_frame),
      .dl_syml_sof            (dl_syml_sof),
      .dl_syml_sos            (dl_syml_sos),
      .dl_syml_frac           (dl_syml_frac),
      .dl_syml_data           (dl_syml_data),
      .dl_syml_valid          (dl_syml_valid),
      // O-RAN parse ports
      //------------------
      .m_mac_header_valid     (m_mac_header_valid),
      .m_mac_dest_mac         (m_mac_dest_mac),
      .m_mac_source_mac       (m_mac_source_mac),
      .m_mac_with_vlan        (m_mac_with_vlan),
      .m_mac_vlan_tag         (m_mac_vlan_tag),
      .m_mac_ethertype        (m_mac_ethertype),
      //
      .m_ecpri_header_valid   (m_ecpri_header_valid),
      .m_ecpri_concat         (m_ecpri_concat),
      .m_ecpri_messagetype    (m_ecpri_messagetype),
      .m_ecpri_payloadsize    (m_ecpri_payloadsize),
      //
      .m_odm_header_valid     (m_odm_header_valid),
      .m_odm_measurementid    (m_odm_measurementid),
      .m_odm_actiontype       (m_odm_actiontype),
      .m_odm_timestamp        (m_odm_timestamp),
      .m_odm_compensation     (m_odm_compensation),
      .m_odm_timestamp2       (m_odm_timestamp2),
      //
      .m_trans_header_valid   (m_trans_header_valid),
      .m_trans_rtc_pc_id      (m_trans_rtc_pc_id),
      .m_trans_seqid          (m_trans_seqid),
      .m_trans_ebit           (m_trans_ebit),
      .m_trans_subseqid       (m_trans_subseqid),
      //
      .m_app_header_valid     (m_app_header_valid),
      .m_app_datadirection    (m_app_datadirection),
      .m_app_filterindex      (m_app_filterindex),
      .m_app_frameid          (m_app_frameid),
      .m_app_subframeid       (m_app_subframeid),
      .m_app_slotid           (m_app_slotid),
      .m_app_packet_in_window (m_app_packet_in_window),
      .m_app_offset_in_symbol (m_app_offset_in_symbol),
      .m_app_symbolid         (m_app_symbolid),
      .m_app_numsections      (m_app_numsections),
      .m_app_sectiontype      (m_app_sectiontype),
      .m_app_udcomphdr        (m_app_udcomphdr),
      .m_app_timeoffset       (m_app_timeoffset),
      .m_app_framestructure   (m_app_framestructure),
      .m_app_cplength         (m_app_cplength),
      //
      .m_section_header_valid (m_section_header_valid),
      .m_section_sectionid    (m_section_sectionid),
      .m_section_rb           (m_section_rb),
      .m_section_syminc       (m_section_syminc),
      .m_section_startprb     (m_section_startprb),
      .m_section_numprb       (m_section_numprb),
      .m_section_udcomphdr    (m_section_udcomphdr),
      .m_section_remask       (m_section_remask),
      .m_section_numsymbol    (m_section_numsymbol),
      .m_section_ef           (m_section_ef),
      .m_section_beamid       (m_section_beamid),
      .m_section_freqoffset   (m_section_freqoffset),
      // Control & Status
      //-----------------
      .ctrl_has_udcomphdr     (ctrl_has_udcomphdr),
      .ctrl_ud_comp_meth      (ctrl_ud_comp_meth),
      .ctrl_ud_iq_width       (ctrl_ud_iq_width),
      //
      .ctrl_syml_rd_shift     (ctrl_defm_syml_rd_shift),
      .ctrl_buffer_addr_offset(ctrl_buffer_addr_offset)
  );

  oran_framer #(
      .NUM_ETHERNET_PORT(NUM_ETHERNET_PORT),
      .NUM_ANTENNA_PORT (NUM_ANTENNA_PORT),
      .NUM_CC           (NUM_CC),
      //
      .ETH_FIFO_DEPTH   (FRAM_ETH_FIFO_DEPTH),
      .ADAPTOR_SIZE     (FRAM_ADAPTOR_SIZE),
      .BUFFER_SIZE      (FRAM_BUFFER_SIZE)
  ) i_ul (
      // Tx Ethernet ports
      //------------------
      .tx_eth_clk        (tx_eth_clk),
      .tx_eth_rst        (tx_eth_rst),
      // Tx data
      .m_eth_fram_tdata  (m_eth_fram_tdata),
      .m_eth_fram_tkeep  (m_eth_fram_tkeep),
      .m_eth_fram_tvalid (m_eth_fram_tvalid),
      .m_eth_fram_tlast  (m_eth_fram_tlast),
      .m_eth_fram_tready (m_eth_fram_tready),
      // Internal clock domain
      //----------------------
      .internal_bus_clk  (internal_bus_clk),
      .fram_reset        (fram_reset),
      // Ready status
      .fram_ready        (fram_ready),
      // Lowphy !@ internal_bus_clk
      .ul_syml_frame     (ul_syml_frame),
      .ul_syml_sof       (ul_syml_sof),
      .ul_syml_sos       (ul_syml_sos),
      .ul_syml_data      (ul_syml_data),
      .ul_syml_valid     (ul_syml_valid),
      // Control I/F
      //------------
      .ctrl_clk          (s_axi_aclk),
      .ctrl_rst          (~s_axi_aresetn),
      //
      .ctrl_has_udcomphdr(ctrl_fram_has_udcomphdr),
      .ctrl_ud_comp_meth (ctrl_fram_ud_comp_meth),
      .ctrl_ud_iq_width  (ctrl_fram_ud_iq_width),
      .ctrl_syml_rd_shift(ctrl_fram_syml_rd_shift),
      //
      .ctrl_dest_mac     (ctrl_fram_dest_mac),
      .ctrl_src_mac      (ctrl_fram_src_mac),
      .ctrl_has_vlan     (ctrl_fram_has_vlan),
      .ctrl_vlan_tag     (ctrl_fram_vlan_tag),
      //
      .ctrl_buf_wr_addr  (ctrl_buf_wr_addr),
      .ctrl_buf_wr_en    (ctrl_buf_wr_en),
      .ctrl_buf_wr_we    (ctrl_buf_wr_we),
      .ctrl_buf_wr_din   (ctrl_buf_wr_din),
      .ctrl_buf_wr_dout  (ctrl_buf_wr_dout),
      //
      .ctrl_mask_wr_addr (ctrl_mask_wr_addr),
      .ctrl_mask_wr_en   (ctrl_mask_wr_en),
      .ctrl_mask_wr_we   (ctrl_mask_wr_we),
      .ctrl_mask_wr_din  (ctrl_mask_wr_din),
      .ctrl_mask_wr_dout (ctrl_mask_wr_dout)
  );

  oran_statistics #(
      .NUM_ETHERNET_PORT(NUM_ETHERNET_PORT),
      .NUM_ANTENNA_PORT (NUM_ANTENNA_PORT),
      .NUM_CC           (NUM_CC)
  ) i_statistics (
      .rx_eth_clk            (rx_eth_clk),
      .rx_eth_rst            (rx_eth_rst),
      //
      .clk                   (internal_bus_clk),
      .rst                   (defm_reset),
      // Timer
      .defm_radio_start_10ms (timer_sof[0]),
      // O-RAN Parse Ports
      //------------------
      .m_mac_header_valid    (m_mac_header_valid),
      .m_mac_dest_mac        (m_mac_dest_mac),
      .m_mac_source_mac      (m_mac_source_mac),
      .m_mac_with_vlan       (m_mac_with_vlan),
      .m_mac_vlan_tag        (m_mac_vlan_tag),
      .m_mac_ethertype       (m_mac_ethertype),
      //
      .m_ecpri_header_valid  (m_ecpri_header_valid),
      .m_ecpri_concat        (m_ecpri_concat),
      .m_ecpri_messagetype   (m_ecpri_messagetype),
      .m_ecpri_payloadsize   (m_ecpri_payloadsize),
      //
      .m_trans_header_valid  (m_trans_header_valid),
      .m_trans_rtc_pc_id     (m_trans_rtc_pc_id),
      .m_trans_seqid         (m_trans_seqid),
      .m_trans_ebit          (m_trans_ebit),
      .m_trans_subseqid      (m_trans_subseqid),
      //
      .m_app_header_valid    (m_app_header_valid),
      .m_app_datadirection   (m_app_datadirection),
      .m_app_filterindex     (m_app_filterindex),
      .m_app_frameid         (m_app_frameid),
      .m_app_subframeid      (m_app_subframeid),
      .m_app_slotid          (m_app_slotid),
      .m_app_symbolid        (m_app_symbolid),
      .m_app_packet_in_window(m_app_packet_in_window),
      .m_app_offset_in_symbol(m_app_offset_in_symbol),
      .m_app_numsections     (m_app_numsections),
      .m_app_sectiontype     (m_app_sectiontype),
      .m_app_udcomphdr       (m_app_udcomphdr),
      .m_app_timeoffset      (m_app_timeoffset),
      .m_app_framestructure  (m_app_framestructure),
      .m_app_cplength        (m_app_cplength),
      //
      .m_section_header_valid(m_section_header_valid),
      .m_section_sectionid   (m_section_sectionid),
      .m_section_rb          (m_section_rb),
      .m_section_syminc      (m_section_syminc),
      .m_section_startprb    (m_section_startprb),
      .m_section_numprb      (m_section_numprb),
      .m_section_remask      (m_section_remask),
      .m_section_numsymbol   (m_section_numsymbol),
      .m_section_ef          (m_section_ef),
      .m_section_beamid      (m_section_beamid),
      .m_section_freqoffset  (m_section_freqoffset),
      // Control & Status
      //-----------------
      .ctrl_tick_snap        (ctrl_tick_snap),
      .ctrl_tick_clear       (ctrl_tick_clear),
      //
      .stat_total_pkt_cnt    (stat_total_pkt_cnt),
      .stat_oran_pkt_cnt     (stat_oran_pkt_cnt),
      .stat_ontime_pkt_cnt   (stat_ontime_pkt_cnt),
      .stat_early_pkt_cnt    (stat_early_pkt_cnt),
      .stat_late_pkt_cnt     (stat_late_pkt_cnt),
      //
      .stat_earliest_u_pkt   (stat_earliest_u_pkt),
      .stat_latest_u_pkt     (stat_latest_u_pkt)
  );

endmodule

`default_nettype wire
