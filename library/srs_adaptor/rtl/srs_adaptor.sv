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
    output var [ 2:0] srs_cfg_cc,
    output var [11:0] srs_cfg_symbol,
    output var [ 3:0] srs_cfg_numsymbol,
    output var        srs_cfg_valid,
    // SRS data request
    output var [ 2:0] srs_req_cc,
    output var [ 5:0] srs_req_layer,
    output var [11:0] srs_req_symbol,
    output var        srs_req_valid,
    // SRS data
    input var  [23:0] srs_data_tdata,                         // {4E, 9Q, 9I}
    input var         srs_data_tlast,
    input var         srs_data_tvalid,
    output var        srs_data_tready,
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
    output var [31:0] m_fram_unsol_tuser,
    // Control
    //========
    // M-Plane SRS Configration
    input var  [15:0] ctrl_srs_rtc_pc_id,
    //
    input var  [ 7:0] ctrl_srs_frameid,
    input var  [ 3:0] ctrl_srs_subframeid,
    input var  [ 5:0] ctrl_srs_slotid,
    input var  [ 5:0] ctrl_srs_symbolid,
    //
    input var  [11:0] ctrl_srs_numsymbol,
    input var  [ 7:0] ctrl_srs_numprbc,
    input var  [ 9:0] ctrl_srs_startprbc,
    input var  [11:0] ctrl_srs_sectionid,
    //
    input var  [ 2:0] ctrl_srs_ethport,
    //
    input var         ctrl_srs_valid,
    // Mu
    input var  [ 1:0] ctrl_numerology        [      NUM_CC]
);


  logic [11:0] s_ul_sym_num_r     [      NUM_CC];
  logic        s_ul_update_r      [      NUM_CC];

  // SRS Filter output
  logic [15:0] srs_flt_rtc_pc_id  [NUM_ETH_PORT];
  logic [ 3:0] srs_flt_cc         [NUM_ETH_PORT];
  //
  logic [ 7:0] srs_flt_frameid    [NUM_ETH_PORT];
  logic [ 3:0] srs_flt_subframeid [NUM_ETH_PORT];
  logic [ 5:0] srs_flt_slotid     [NUM_ETH_PORT];
  logic [ 5:0] srs_flt_symbolid   [NUM_ETH_PORT];
  //
  logic [ 3:0] srs_flt_numsymbol  [NUM_ETH_PORT];
  logic [ 7:0] srs_flt_numprbc    [NUM_ETH_PORT];
  logic [ 9:0] srs_flt_startprbc  [NUM_ETH_PORT];
  logic [11:0] srs_flt_sectionid  [NUM_ETH_PORT];
  //
  logic        srs_flt_valid      [NUM_ETH_PORT];

  // SRS Mux output
  logic [15:0] srs_mux_rtc_pc_id;
  logic [ 2:0] srs_mux_cc;
  //
  logic [ 7:0] srs_mux_frameid;
  logic [ 3:0] srs_mux_subframeid;
  logic [ 5:0] srs_mux_slotid;
  logic [ 5:0] srs_mux_symbolid;
  logic [11:0] srs_mux_symbol;
  //
  logic [ 3:0] srs_mux_numsymbol;
  logic [ 7:0] srs_mux_numprbc;
  logic [ 9:0] srs_mux_startprbc;
  logic [11:0] srs_mux_sectionid;
  //
  logic [ 2:0] srs_mux_ethport;
  //
  logic        srs_mux_valid;

  // Send it to runner
  logic [15:0] srs_run_rtc_pc_id;
  logic [ 2:0] srs_run_cc;
  //
  logic [ 7:0] srs_run_frameid;
  logic [ 3:0] srs_run_subframeid;
  logic [ 5:0] srs_run_slotid;
  logic [ 5:0] srs_run_symbolid;
  logic [11:0] srs_run_symbol;
  //
  logic [ 7:0] srs_run_numprbc;
  logic [ 9:0] srs_run_startprbc;
  logic [11:0] srs_run_sectionid;
  //
  logic [ 2:0] srs_run_ethport;
  //
  logic        srs_run_valid;
  logic        srs_run_ready;

  // BRAM
  logic [10:0] bram_addr;
  logic        bram_rden;
  logic [95:0] bram_data;

  // Framer
  logic [ 2:0] fram_req_eth_port;
  logic [15:0] fram_req_rtc_pc_id;
  logic [63:0] fram_req_header;
  logic [ 9:0] fram_req_start_rb;
  logic [ 7:0] fram_req_num_rb;
  logic        fram_req_bank;
  logic        fram_req_valid;
  logic        fram_req_ready;



  // Pipe for timing
  always_ff @(posedge clk_400m) begin
    s_ul_sym_num_r <= s_ul_sym_num;
    s_ul_update_r  <= s_ul_update;
  end

  generate
    for (genvar i = 0; i < NUM_ETH_PORT; i++) begin : g_filter

      (* keep_hierarchy="yes" *)
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
          .srs_rtc_pc_id          (srs_flt_rtc_pc_id[i]),
          //
          .srs_frameid            (srs_flt_frameid[i]),
          .srs_subframeid         (srs_flt_subframeid[i]),
          .srs_slotid             (srs_flt_slotid[i]),
          .srs_symbolid           (srs_flt_symbolid[i]),
          //
          .srs_numsymbol          (srs_flt_numsymbol[i]),
          .srs_numprbc            (srs_flt_numprbc[i]),
          .srs_startprbc          (srs_flt_startprbc[i]),
          .srs_sectionid          (srs_flt_sectionid[i]),
          //
          .srs_valid              (srs_flt_valid[i])
      );

    end
  endgenerate

  (* keep_hierarchy="yes" *)
  srs_adaptor_mux #(
      .NUM_ETH_PORT(NUM_ETH_PORT)
  ) i_mux (
      // XORIF
      //======
      .clk               (clk_400m),
      .rst               (rst_400m),
      // SRS Filter
      //===========
      .srs_flt_rtc_pc_id (srs_flt_rtc_pc_id),
      //
      .srs_flt_frameid   (srs_flt_frameid),
      .srs_flt_subframeid(srs_flt_subframeid),
      .srs_flt_slotid    (srs_flt_slotid),
      .srs_flt_symbolid  (srs_flt_symbolid),
      //
      .srs_flt_numsymbol (srs_flt_numsymbol),
      .srs_flt_numprbc   (srs_flt_numprbc),
      .srs_flt_startprbc (srs_flt_startprbc),
      .srs_flt_sectionid (srs_flt_sectionid),
      //
      .srs_flt_valid     (srs_flt_valid),
      // SRS MUX
      //========
      .srs_mux_rtc_pc_id (srs_mux_rtc_pc_id),
      .srs_mux_cc        (srs_mux_cc),
      //
      .srs_mux_frameid   (srs_mux_frameid),
      .srs_mux_subframeid(srs_mux_subframeid),
      .srs_mux_slotid    (srs_mux_slotid),
      .srs_mux_symbolid  (srs_mux_symbolid),
      .srs_mux_symbol    (srs_mux_symbol),
      //
      .srs_mux_numsymbol (srs_mux_numsymbol),
      .srs_mux_numprbc   (srs_mux_numprbc),
      .srs_mux_startprbc (srs_mux_startprbc),
      .srs_mux_sectionid (srs_mux_sectionid),
      //
      .srs_mux_ethport   (srs_mux_ethport),
      //
      .srs_mux_valid     (srs_mux_valid),
      // Control
      //========
      .ctrl_numerology   (ctrl_numerology)
  );

  (* keep_hierarchy="yes" *)
  srs_adaptor_fwd i_fwd (
      // XORIF
      //======
      .clk_400m         (clk_400m),
      .rst_400m         (rst_400m),
      // SRS Filter
      .srs_cc           (srs_mux_cc),
      .srs_symbol       (srs_mux_symbol),
      .srs_numsymbol    (srs_mux_numsymbol),
      .srs_valid        (srs_mux_valid),
      // DFE
      //====
      .clk_491m52       (clk_491m52),
      .rst_491m52       (rst_491m52),
      // SRS Configuration Forward
      .srs_cfg_cc       (srs_cfg_cc),
      .srs_cfg_symbol   (srs_cfg_symbol),
      .srs_cfg_numsymbol(srs_cfg_numsymbol),
      .srs_cfg_valid    (srs_cfg_valid)
  );

  (* keep_hierarchy="yes" *)
  srs_adaptor_controller #(
      .NUM_CC(NUM_CC)
  ) i_controller (
      // XORIF
      //======
      .clk               (clk_400m),
      .rst               (rst_400m),
      // UL Timing
      .s_ul_sym_num      (s_ul_sym_num_r),
      .s_ul_update       (s_ul_update_r),
      // SRS Mux
      .srs_mux_rtc_pc_id (srs_mux_rtc_pc_id),
      .srs_mux_cc        (srs_mux_cc),
      //
      .srs_mux_frameid   (srs_mux_frameid),
      .srs_mux_subframeid(srs_mux_subframeid),
      .srs_mux_slotid    (srs_mux_slotid),
      .srs_mux_symbolid  (srs_mux_symbolid),
      .srs_mux_symbol    (srs_mux_symbol),
      //
      .srs_mux_numsymbol (srs_mux_numsymbol),
      .srs_mux_numprbc   (srs_mux_numprbc),
      .srs_mux_startprbc (srs_mux_startprbc),
      .srs_mux_sectionid (srs_mux_sectionid),
      //
      .srs_mux_ethport   (srs_mux_ethport),
      //
      .srs_mux_valid     (srs_mux_valid),
      // Runner
      //=======
      .srs_run_rtc_pc_id (srs_run_rtc_pc_id),
      .srs_run_cc        (srs_run_cc),
      //
      .srs_run_frameid   (srs_run_frameid),
      .srs_run_subframeid(srs_run_subframeid),
      .srs_run_slotid    (srs_run_slotid),
      .srs_run_symbolid  (srs_run_symbolid),
      .srs_run_symbol    (srs_run_symbol),
      //
      .srs_run_numprbc   (srs_run_numprbc),
      .srs_run_startprbc (srs_run_startprbc),
      .srs_run_sectionid (srs_run_sectionid),
      //
      .srs_run_ethport   (srs_run_ethport),
      //
      .srs_run_valid     (srs_run_valid),
      .srs_run_ready     (srs_run_ready)
  );

  (* keep_hierarchy="yes" *)
  srs_adaptor_runner i_runner (
      // 400M
      //======
      .clk_400m          (clk_400m),
      .rst_400m          (rst_400m),
      // SRS Request
      .srs_run_rtc_pc_id (srs_run_rtc_pc_id),
      .srs_run_cc        (srs_run_cc),
      //
      .srs_run_frameid   (srs_run_frameid),
      .srs_run_subframeid(srs_run_subframeid),
      .srs_run_slotid    (srs_run_slotid),
      .srs_run_symbolid  (srs_run_symbolid),
      .srs_run_symbol    (srs_run_symbol),
      //
      .srs_run_numprbc   (srs_run_numprbc),
      .srs_run_startprbc (srs_run_startprbc),
      .srs_run_sectionid (srs_run_sectionid),
      //
      .srs_run_ethport   (srs_run_ethport),
      //
      .srs_run_valid     (srs_run_valid),
      .srs_run_ready     (srs_run_ready),
      // Frame Request
      //==============
      .fram_req_eth_port (fram_req_eth_port),
      .fram_req_rtc_pc_id(fram_req_rtc_pc_id),
      .fram_req_header   (fram_req_header),
      .fram_req_start_rb (fram_req_start_rb),
      .fram_req_num_rb   (fram_req_num_rb),
      .fram_req_bank     (fram_req_bank),
      .fram_req_valid    (fram_req_valid),
      .fram_req_ready    (fram_req_ready),
      //
      .bram_rd_addr      (bram_addr),
      .bram_rd_rden      (bram_rden),
      .bram_rd_data      (bram_data),
      // DFE
      //====
      .clk_491m52        (clk_491m52),
      .rst_491m52        (rst_491m52),
      //
      .srs_data_tdata    (srs_data_tdata),
      .srs_data_tlast    (srs_data_tlast),
      .srs_data_tvalid   (srs_data_tvalid),
      .srs_data_tready   (srs_data_tready),
      // SRS Request
      .srs_req_cc        (srs_req_cc),
      .srs_req_layer     (srs_req_layer),
      .srs_req_symbol    (srs_req_symbol),
      .srs_req_valid     (srs_req_valid)
  );

  (* keep_hierarchy="yes" *)
  srs_adaptor_framer i_framer (
      // DFE
      //====
      .clk                (clk_400m),
      .rst                (rst_400m),
      //
      .bram_addr          (bram_addr),  // {4'b exponent, 9'b mantissa Q, 9'b mantissa I}
      .bram_rden          (bram_rden),
      .bram_data          (bram_data),
      // Frame request
      .fram_req_eth_port  (fram_req_eth_port),
      .fram_req_rtc_pc_id (fram_req_rtc_pc_id),
      .fram_req_header    (fram_req_header),
      .fram_req_start_rb  (fram_req_start_rb),
      .fram_req_num_rb    (fram_req_num_rb),
      .fram_req_bank      (fram_req_bank),
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
