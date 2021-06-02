`timescale 1 ns / 1 ps `default_nettype none

module srs_adaptor #(
    parameter int NUM_ETH_PORT = 2,
    parameter int NUM_SRS_LAYER = 64,
    parameter int NUM_CC = 2
) (
    // Interface with DFE
    //===================
    input var         clk_491m52,
    input var         rst_491m52,
    // SRS Section Header
    output var [ 3:0] srs_cfg_cc,
    output var [11:0] srs_cfg_symbol,
    output var [ 3:0] srs_cfg_numsymbol,
    output var        srs_cfg_valid,
    // SRS data request
    output var [ 3:0] srs_req_cc,
    output var [ 5:0] srs_req_layer,
    output var [11:0] srs_req_symbol,
    output var        srs_req_valid,
    // SRS data
    input var  [21:0] srs_data, // {4E, 9Q, 9I}
    input var         srs_valid,
    input var         srs_sop,
    input var         srs_eop,
    // Interface with XORIF
    //=====================
    input var         clk_400m,
    input var         rst_400m,
    // UL Timing
    input var  [11:0] s_ul_sym_num           [      NUM_CC],
    input var         s_ul_update            [      NUM_CC],
    // ORAN Parse Port
    input var         s_t_header_offset_valid[NUM_ETH_PORT],
    input var         s_runt_packet_len      [NUM_ETH_PORT],
    input var  [15:0] s_rtc_pc_id            [NUM_ETH_PORT],
    input var         s_concat               [NUM_ETH_PORT],
    input var  [ 2:0] s_messagetype          [NUM_ETH_PORT],
    input var  [ 7:0] s_seqid                [NUM_ETH_PORT],
    input var  [ 6:0] s_subseqid             [NUM_ETH_PORT],
    input var         s_ebit                 [NUM_ETH_PORT],
    input var  [15:0] s_payloadsize          [NUM_ETH_PORT],
    input var         s_packet_in_window     [NUM_ETH_PORT],
    input var  [11:0] s_offset_in_symbol     [NUM_ETH_PORT],
    //
    input var         s_radio_app_head_valid [NUM_ETH_PORT],
    input var         s_datadirection        [NUM_ETH_PORT],
    input var  [ 7:0] s_numsections          [NUM_ETH_PORT],
    input var  [ 2:0] s_sectiontype          [NUM_ETH_PORT],
    input var  [ 3:0] s_filterindex          [NUM_ETH_PORT],
    input var  [ 7:0] s_frameid              [NUM_ETH_PORT],
    input var  [ 3:0] s_subframeid           [NUM_ETH_PORT],
    input var  [ 5:0] s_slotid               [NUM_ETH_PORT],
    input var  [ 5:0] s_symbolid             [NUM_ETH_PORT],
    input var  [ 7:0] s_udcomphdr            [NUM_ETH_PORT],
    input var  [15:0] s_timeoffset           [NUM_ETH_PORT],
    input var  [ 7:0] s_framestructure       [NUM_ETH_PORT],
    input var  [15:0] s_cplength             [NUM_ETH_PORT],
    //
    input var         s_section_header_valid [NUM_ETH_PORT],
    input var  [ 3:0] s_numsymbol            [NUM_ETH_PORT],
    input var  [ 7:0] s_numprbc              [NUM_ETH_PORT],
    input var  [ 9:0] s_startprbc            [NUM_ETH_PORT],
    input var  [11:0] s_sectionid            [NUM_ETH_PORT],
    input var         s_rb                   [NUM_ETH_PORT],
    input var  [11:0] s_remask               [NUM_ETH_PORT],
    input var  [14:0] s_beamid15             [NUM_ETH_PORT],
    input var  [23:0] s_freqoffset           [NUM_ETH_PORT],
    // UNSOL port
    output var [63:0] m_fram_unsol_tdata,
    output var [ 7:0] m_fram_unsol_tkeep,
    output var        m_fram_unsol_tvalid,
    output var        m_fram_unsol_tlast,
    input var         m_fram_unsol_tready,
    output var [31:0] m_fram_unsol_tuser
);


  logic        srs_flt_valid     [NUM_ETH_PORT];
  logic [15:0] srs_flt_rtc_pc_id [NUM_ETH_PORT];
  logic [ 3:0] srs_flt_cc        [NUM_ETH_PORT];
  logic [ 3:0] srs_flt_subframeid[NUM_ETH_PORT];
  logic [ 5:0] srs_flt_slotid    [NUM_ETH_PORT];
  logic [ 7:0] srs_flt_symbolid  [NUM_ETH_PORT];
  logic [ 3:0] srs_flt_numsymbol [NUM_ETH_PORT];
  logic [ 7:0] srs_flt_numprbc   [NUM_ETH_PORT];
  logic [ 9:0] srs_flt_startprbc [NUM_ETH_PORT];
  logic [11:0] srs_flt_sectionid [NUM_ETH_PORT];

  logic [ 2:0] fram_req_eth_port;
  logic [63:0] fram_req_header;
  logic [ 8:0] fram_req_start_rb;
  logic [ 7:0] fram_req_num_rb;
  logic        fram_req_valid;
  logic        fram_req_ready;


  generate
    for (genvar i = 0; i < NUM_ETH_PORT; i++) begin : g_filter

      srs_adaptor_filter i_filter (
          // Interface with XORIF
          //=====================
          .clk                    (clk_400m),
          .rst                    (rst_400m),
          // ORAN Parse Port
          .s_t_header_offset_valid(s_t_header_offset_valid[i]),
          .s_runt_packet_len      (s_runt_packet_len[i]),
          .s_rtc_pc_id            (s_rtc_pc_id[i]),
          .s_concat               (s_concat[i]),
          .s_messagetype          (s_messagetype[i]),
          .s_seqid                (s_seqid[i]),
          .s_subseqid             (s_subseqid[i]),
          .s_ebit                 (s_ebit[i]),
          .s_payloadsize          (s_payloadsize[i]),
          .s_packet_in_window     (s_packet_in_window[i]),
          .s_offset_in_symbol     (s_offset_in_symbol[i]),
          //
          .s_radio_app_head_valid (s_radio_app_head_valid[i]),
          .s_datadirection        (s_datadirection[i]),
          .s_numsections          (s_numsections[i]),
          .s_sectiontype          (s_sectiontype[i]),
          .s_filterindex          (s_filterindex[i]),
          .s_frameid              (s_frameid[i]),
          .s_subframeid           (s_subframeid[i]),
          .s_slotid               (s_slotid[i]),
          .s_symbolid             (s_symbolid[i]),
          .s_udcomphdr            (s_udcomphdr[i]),
          .s_timeoffset           (s_timeoffset[i]),
          .s_framestructure       (s_framestructure[i]),
          .s_cplength             (s_cplength[i]),
          //
          .s_section_header_valid (s_section_header_valid[i]),
          .s_numsymbol            (s_numsymbol[i]),
          .s_numprbc              (s_numprbc[i]),
          .s_startprbc            (s_startprbc[i]),
          .s_sectionid            (s_sectionid[i]),
          .s_rb                   (s_rb[i]),
          .s_remask               (s_remask[i]),
          .s_beamid15             (s_beamid15[i]),
          .s_freqoffset           (s_freqoffset[i]),
          // SRS Information
          //================
          .srs_valid              (srs_flt_valid[i]),
          .srs_rtc_pc_id          (srs_flt_rtc_pc_id[i]),
          .srs_cc                 (srs_flt_cc[i]),
          .srs_subframeid         (srs_flt_subframeid[i]),
          .srs_slotid             (srs_flt_slotid[i]),
          .srs_symbolid           (srs_flt_symbolid[i]),
          .srs_numsymbol          (srs_flt_numsymbol[i]),
          .srs_numprbc            (srs_flt_numprbc[i]),
          .srs_startprbc          (srs_flt_startprbc[i]),
          .srs_sectionid          (srs_flt_sectionid[i])
      );

    end
  endgenerate

  srs_adaptor_controller #(
      .NUM_ETH_PORT(NUM_ETH_PORT)
  ) i_controller (
      // XORIF
      //======
      .clk_400m         (clk_400m),
      .rst_400m         (rst_400m),
      // UL Timing
      .s_ul_sym_num     (s_ul_sym_num),
      .s_ul_update      (s_ul_update),
      // SRS Filter
      .srs_valid        (srs_flt_valid),
      .srs_rtc_pc_id    (srs_flt_rtc_pc_id),
      .srs_cc           (srs_flt_cc),
      .srs_subframeid   (srs_flt_subframeid),
      .srs_slotid       (srs_flt_slotid),
      .srs_symbolid     (srs_flt_symbolid),
      .srs_numsymbol    (srs_flt_numsymbol),
      .srs_numprbc      (srs_flt_numprbc),
      .srs_startprbc    (srs_flt_startprbc),
      .srs_sectionid    (srs_flt_sectionid),
      // Frame request
      .fram_req_eth_port(fram_req_eth_port),
      .fram_req_header  (fram_req_header),
      .fram_req_start_rb(fram_req_start_rb),
      .fram_req_num_rb  (fram_req_num_rb),
      .fram_req_valid   (fram_req_valid),
      .fram_req_ready   (fram_req_ready),
      // DFE
      //==========================
      .clk_491m52       (clk_491m52),
      .rst_491m52       (rst_491m52),
      // SRS Configuration Forward
      .srs_cfg_cc       (srs_cfg_cc),
      .srs_cfg_symbol   (srs_cfg_symbol),
      .srs_cfg_numsymbol(srs_cfg_numsymbol),
      .srs_cfg_valid    (srs_cfg_valid),
      // SRS Request
      .srs_req_cc       (srs_req_cc),
      .srs_req_layer    (srs_req_layer),
      .srs_req_symbol   (srs_req_symbol),
      .srs_req_valid    (srs_req_valid)
  );

  srs_adaptor_gearbox i_gearbox (
      // DFE
      //====
      .clk_491m52         (clk_491m52),
      .rst_491m52         (rst_491m52),
      //
      .srs_data           (srs_data),  // {4'b exponent, 9'b mantissa Q, 9'b mantissa I}
      .srs_valid          (srs_valid),
      .srs_eop            (srs_eop),
      // XORIF
      //=======
      .clk_400m           (clk_400m),
      .rst_400m           (rst_400m),
      // Frame request
      .fram_req_eth_port  (fram_req_eth_port),
      .fram_req_header    (fram_req_header),
      .fram_req_start_rb  (fram_req_start_rb),
      .fram_req_num_rb    (fram_req_num_rb),
      .fram_req_valid     (fram_req_valid),
      .fram_req_ready     (fram_req_ready),
      // UNSOL port
      .m_fram_unsol_tdata (m_fram_unsol_tdata),
      .m_fram_unsol_tkeep (m_fram_unsol_tkeep),
      .m_fram_unsol_tvalid(m_fram_unsol_tvalid),
      .m_fram_unsol_tlast (m_fram_unsol_tlast),
      .m_fram_unsol_tready(m_fram_unsol_tready),
      .m_fram_unsol_tuser (m_fram_unsol_tuser)
  );


endmodule

`default_nettype wire
