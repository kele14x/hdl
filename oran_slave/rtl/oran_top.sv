// File: oran_top.sv
// Brief: Wrapper for module oran_if for more simple interface
`timescale 1 ns / 1 ps
//
`default_nettype none

module oran_top #(
    parameter int ANT_NUM = 2
) (
    // AXI
    //----
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
    //
    output var        interrupt,
    // Ethernet
    //---------
    input var         eth_clk,
    input var         eth_rst,
    // RX
    input var  [63:0] rx_axis_tdata,
    input var  [ 7:0] rx_axis_tkeep,
    input var         rx_axis_tvalid,
    input var         rx_axis_tlast,
    input var  [79:0] rx_axis_tuser,
    // TX
    output var [63:0] tx_axis_tdata,
    output var [ 7:0] tx_axis_tkeep,
    output var        tx_axis_tlast,
    output var        tx_axis_tvalid,
    input var         tx_axis_tready,
    //
    output var        m_odm_header_valid,
    output var [79:0] m_odm_timestamp,
    output var [79:0] m_odm_timestamp2,
    //
    output var [ 7:0] m_app_frameid,
    // Lowphy
    //-------
    input var         clk,
    input var         rst,
    // Timer
    input var  [ 7:0] timer_frame,
    input var         timer_sof,
    input var         timer_sos,
    input var  [32:0] timer_frac,
    // DL
    output var [ 7:0] dl_syml_frame     [ANT_NUM],
    output var        dl_syml_sof       [ANT_NUM],
    output var        dl_syml_sos       [ANT_NUM],
    output var [32:0] dl_syml_frac      [ANT_NUM],
    output var [31:0] dl_syml_data      [ANT_NUM],
    output var        dl_syml_valid     [ANT_NUM],
    // UL
    input var  [ 7:0] ul_syml_frame     [ANT_NUM],
    input var         ul_syml_sof       [ANT_NUM],
    input var         ul_syml_sos       [ANT_NUM],
    input var  [31:0] ul_syml_data      [ANT_NUM],
    input var         ul_syml_valid     [ANT_NUM]
);

  // Clock frequency
  localparam int Frequency = 1;

  // Number of carrier components per antenna
  localparam int NumCc = 1;
  // Number of Ethernet ports
  localparam int NumEth = 1;

  // Ethernet RX FIFO depth
  localparam int DefmEthFifoDepth = 1024;
  // Adaptor RE size
  localparam int DefmAdaptorSize = 1024;
  // Deframer section data buffer size
  localparam int DefmBufferSize = 4096;

  // Ethernet TX FIFO depth
  localparam int FramEthFifoDepth = 1024;
  // Adaptor RE size
  localparam int FramAdaptorSize = 1024;
  // Deframer section data buffer size
  localparam int FramBufferSize = 1024;

  // Timer ports

  (* max_fanout=500 *)
  logic        local_resetn;

  logic        fram_ready;
  logic        defm_ready;

  logic        rx_eth_clk          [ NumEth];
  logic        rx_eth_rst          [ NumEth];

  logic        tx_eth_clk          [ NumEth];
  logic        tx_eth_rst          [ NumEth];

  logic [ 7:0] timer_frame_s       [  NumCc];
  logic        timer_sof_s         [  NumCc];
  logic        timer_sos_s         [  NumCc];
  logic [32:0] timer_frac_s        [  NumCc];

  logic [ 7:0] dl_syml_frame_s     [ANT_NUM] [NumCc];
  logic        dl_syml_sof_s       [ANT_NUM] [NumCc];
  logic        dl_syml_sos_s       [ANT_NUM] [NumCc];
  logic [32:0] dl_syml_frac_s      [ANT_NUM] [NumCc];
  logic [31:0] dl_syml_data_s      [ANT_NUM] [NumCc];
  logic        dl_syml_valid_s     [ANT_NUM] [NumCc];

  logic [ 7:0] ul_syml_frame_s     [ANT_NUM] [NumCc];
  logic        ul_syml_sof_s       [ANT_NUM] [NumCc];
  logic        ul_syml_sos_s       [ANT_NUM] [NumCc];
  logic [31:0] ul_syml_data_s      [ANT_NUM] [NumCc];
  logic        ul_syml_valid_s     [ANT_NUM] [NumCc];

  // RX
  logic [63:0] rx_axis_tdata_s     [ NumEth];
  logic [ 7:0] rx_axis_tkeep_s     [ NumEth];
  logic        rx_axis_tvalid_s    [ NumEth];
  logic        rx_axis_tlast_s     [ NumEth];
  logic [79:0] rx_axis_tuser_s     [ NumEth];
  // TX
  logic [63:0] tx_axis_tdata_s     [ NumEth];
  logic [ 7:0] tx_axis_tkeep_s     [ NumEth];
  logic        tx_axis_tlast_s     [ NumEth];
  logic        tx_axis_tvalid_s    [ NumEth];
  logic        tx_axis_tready_s    [ NumEth];

  logic        m_odm_header_valid_s[ NumEth];
  logic [79:0] m_odm_timestamp_s   [ NumEth];
  logic [79:0] m_odm_timestamp2_s  [ NumEth];

  logic [ 7:0] m_app_frameid_s     [ANT_NUM] [NumCc];


  // Main
  //-----

  always_ff @(posedge s_axi_aclk) begin
    local_resetn <= s_axi_aresetn;
  end

  generate
    for (genvar i = 0; i < NumEth; i++) begin : g_eth
      assign rx_eth_clk[i] = eth_clk;
      assign rx_eth_rst[i] = eth_rst;
      //
      assign tx_eth_clk[i] = eth_clk;
      assign tx_eth_rst[i] = eth_rst;
    end
  endgenerate

  generate
    for (genvar i = 0; i < NumCc; i++) begin : g_cc
      assign timer_frame_s[i] = timer_frame;
      assign timer_sof_s[i]   = timer_sof;
      assign timer_sos_s[i]   = timer_sos;
      assign timer_frac_s[i]  = timer_frac;
    end
  endgenerate

  assign tx_axis_tdata = tx_axis_tdata_s[0];
  assign tx_axis_tkeep = tx_axis_tkeep_s[0];
  assign tx_axis_tlast = tx_axis_tlast_s[0];
  assign tx_axis_tvalid = tx_axis_tvalid_s[0];
  assign tx_axis_tready_s[0] = tx_axis_tready;

  assign rx_axis_tdata_s[0] = rx_axis_tdata;
  assign rx_axis_tkeep_s[0] = rx_axis_tkeep;
  assign rx_axis_tlast_s[0] = rx_axis_tlast;
  assign rx_axis_tuser_s[0] = rx_axis_tuser;
  assign rx_axis_tvalid_s[0] = rx_axis_tvalid;

  assign m_odm_header_valid = m_odm_header_valid_s[0];
  assign m_odm_timestamp    = m_odm_timestamp_s[0];
  assign m_odm_timestamp2   = m_odm_timestamp2_s[0];

  generate
    for (genvar i = 0; i < ANT_NUM; i++) begin : g_ant

      assign dl_syml_frame[i] = dl_syml_frame_s[i][0];
      assign dl_syml_sof[i] = dl_syml_sof_s[i][0];
      assign dl_syml_sos[i] = dl_syml_sos_s[i][0];
      assign dl_syml_frac[i] = dl_syml_frac_s[i][0];
      assign dl_syml_data[i] = dl_syml_data_s[i][0];
      assign dl_syml_valid[i] = dl_syml_valid_s[i][0];

      assign ul_syml_frame_s[i][0] = ul_syml_frame[i];
      assign ul_syml_sof_s[i][0] = ul_syml_sof[i];
      assign ul_syml_sos_s[i][0] = ul_syml_sos[i];
      assign ul_syml_data_s[i][0] = ul_syml_data[i];
      assign ul_syml_valid_s[i][0] = ul_syml_valid[i];

    end
  endgenerate

  assign m_app_frameid = m_app_frameid_s[0][0];

  oran_if #(
      .FREQUENCY          (Frequency),
      //
      .NUM_ETHERNET_PORT  (NumEth),
      .NUM_ANTENNA_PORT   (ANT_NUM),
      .NUM_CC             (NumCc),
      //
      .DEFM_ETH_FIFO_DEPTH(DefmEthFifoDepth),
      .DEFM_ADAPTOR_SIZE  (DefmAdaptorSize),
      .DEFM_BUFFER_SIZE   (DefmBufferSize),
      //
      .FRAM_ETH_FIFO_DEPTH(FramEthFifoDepth),
      .FRAM_ADAPTOR_SIZE  (FramAdaptorSize),
      .FRAM_BUFFER_SIZE   (FramBufferSize)
  ) i_oran_if (
      // AXI
      //----
      .s_axi_aclk            (s_axi_aclk),
      .s_axi_aresetn         (local_resetn),
      //
      .s_axi_awaddr          (s_axi_awaddr),
      .s_axi_awprot          (s_axi_awprot),
      .s_axi_awvalid         (s_axi_awvalid),
      .s_axi_awready         (s_axi_awready),
      //
      .s_axi_wdata           (s_axi_wdata),
      .s_axi_wstrb           (s_axi_wstrb),
      .s_axi_wvalid          (s_axi_wvalid),
      .s_axi_wready          (s_axi_wready),
      //
      .s_axi_bresp           (s_axi_bresp),
      .s_axi_bvalid          (s_axi_bvalid),
      .s_axi_bready          (s_axi_bready),
      //
      .s_axi_araddr          (s_axi_araddr),
      .s_axi_arprot          (s_axi_arprot),
      .s_axi_arvalid         (s_axi_arvalid),
      .s_axi_arready         (s_axi_arready),
      //
      .s_axi_rdata           (s_axi_rdata),
      .s_axi_rresp           (s_axi_rresp),
      .s_axi_rvalid          (s_axi_rvalid),
      .s_axi_rready          (s_axi_rready),
      // IRQ
      .interrupt             (interrupt),
      // Ethernet
      //---------
      .rx_eth_clk            (rx_eth_clk),
      .rx_eth_rst            (rx_eth_rst),
      //
      .s_eth_defm_tdata      (rx_axis_tdata_s),
      .s_eth_defm_tkeep      (rx_axis_tkeep_s),
      .s_eth_defm_tvalid     (rx_axis_tvalid_s),
      .s_eth_defm_tlast      (rx_axis_tlast_s),
      .s_eth_defm_tuser      (rx_axis_tuser_s),
      //
      .tx_eth_clk            (tx_eth_clk),
      .tx_eth_rst            (tx_eth_rst),
      //
      .m_eth_fram_tdata      (tx_axis_tdata_s),
      .m_eth_fram_tkeep      (tx_axis_tkeep_s),
      .m_eth_fram_tvalid     (tx_axis_tvalid_s),
      .m_eth_fram_tlast      (tx_axis_tlast_s),
      .m_eth_fram_tready     (tx_axis_tready_s),
      // Carrier Ports
      //--------------
      .internal_bus_clk      (clk),
      // Reset
      .defm_reset            (rst),
      .fram_reset            (rst),
      //
      .timer_frame           (timer_frame_s),
      .timer_sof             (timer_sof_s),
      .timer_sos             (timer_sos_s),
      .timer_frac            (timer_frac_s),
      //
      .defm_ready            (defm_ready),
      .fram_ready            (fram_ready),
      // DL
      .dl_syml_frame         (dl_syml_frame_s),
      .dl_syml_sof           (dl_syml_sof_s),
      .dl_syml_sos           (dl_syml_sos_s),
      .dl_syml_frac          (dl_syml_frac_s),
      .dl_syml_data          (dl_syml_data_s),
      .dl_syml_valid         (dl_syml_valid_s),
      // UL
      .ul_syml_frame         (ul_syml_frame_s),
      .ul_syml_sof           (ul_syml_sof_s),
      .ul_syml_sos           (ul_syml_sos_s),
      .ul_syml_data          (ul_syml_data_s),
      .ul_syml_valid         (ul_syml_valid_s),
      //
      .m_mac_header_valid    (),
      .m_mac_dest_mac        (),
      .m_mac_source_mac      (),
      .m_mac_with_vlan       (),
      .m_mac_vlan_tag        (),
      .m_mac_ethertype       (),
      //
      .m_ecpri_header_valid  (),
      .m_ecpri_concat        (),
      .m_ecpri_messagetype   (),
      .m_ecpri_payloadsize   (),
      //
      .m_odm_header_valid    (m_odm_header_valid_s),
      .m_odm_measurementid   (),
      .m_odm_actiontype      (),
      .m_odm_timestamp       (m_odm_timestamp_s),
      .m_odm_compensation    (),
      .m_odm_timestamp2      (m_odm_timestamp2_s),
      //
      .m_trans_header_valid  (),
      .m_trans_rtc_pc_id     (),
      .m_trans_seqid         (),
      .m_trans_ebit          (),
      .m_trans_subseqid      (),
      //
      .m_app_header_valid    (),
      .m_app_datadirection   (),
      .m_app_filterindex     (),
      .m_app_frameid         (m_app_frameid_s),
      .m_app_subframeid      (),
      .m_app_slotid          (),
      .m_app_packet_in_window(),
      .m_app_offset_in_symbol(),
      .m_app_symbolid        (),
      .m_app_numsections     (),
      .m_app_sectiontype     (),
      .m_app_udcomphdr       (),
      .m_app_timeoffset      (),
      .m_app_framestructure  (),
      .m_app_cplength        (),
      //
      .m_section_header_valid(),
      .m_section_sectionid   (),
      .m_section_rb          (),
      .m_section_syminc      (),
      .m_section_startprb    (),
      .m_section_numprb      (),
      .m_section_udcomphdr   (),
      .m_section_remask      (),
      .m_section_numsymbol   (),
      .m_section_ef          (),
      .m_section_beamid      (),
      .m_section_freqoffset  ()
  );

endmodule

`default_nettype wire
