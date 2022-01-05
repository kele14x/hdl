// file: srs_adaptor:
// breif: Top module srs_adaptor This module will parse SRS C-Plane message and
//        forward it to SRS processor. When SRS processor buffered the symbol,
//        module will readout SRS symbol and put it to XORIF.
`timescale 1 ns / 1 ps `default_nettype none

module srs_adaptor #(
    parameter int NUM_ETH_PORT = 2,
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
    input var         ctrl_clk,
    input var         ctrl_rst,
    // Enable SRS function
    input var         ctrl_srs_en,
    // M-Plane SRS Configuration
    // Use generated SRS message instead from DU
    input var         ctrl_srs_gen_en,
    //
    input var  [15:0] ctrl_srs_rtc_pc_id,
    //
    input var  [ 7:0] ctrl_srs_frameid,
    input var  [ 3:0] ctrl_srs_subframeid,
    input var  [ 5:0] ctrl_srs_slotid,
    input var  [ 5:0] ctrl_srs_symbolid,
    //
    input var  [ 3:0] ctrl_srs_numsymbol,
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


  logic        src_send;
  logic        src_rcv;

  logic [11:0] s_ul_sym_num_r        [      NUM_CC];
  logic        s_ul_update_r         [      NUM_CC];

  // SRS Filter output
  logic [15:0] srs_flt_rtc_pc_id     [NUM_ETH_PORT];
  //
  logic [ 7:0] srs_flt_frameid       [NUM_ETH_PORT];
  logic [ 3:0] srs_flt_subframeid    [NUM_ETH_PORT];
  logic [ 5:0] srs_flt_slotid        [NUM_ETH_PORT];
  logic [ 5:0] srs_flt_symbolid      [NUM_ETH_PORT];
  //
  logic [ 3:0] srs_flt_numsymbol     [NUM_ETH_PORT];
  logic [ 7:0] srs_flt_numprbc       [NUM_ETH_PORT];
  logic [ 9:0] srs_flt_startprbc     [NUM_ETH_PORT];
  logic [11:0] srs_flt_sectionid     [NUM_ETH_PORT];
  //
  logic        srs_flt_valid         [NUM_ETH_PORT];

  // SRS Mux output
  logic [ 2:0] srs_mux_cc;
  logic [ 5:0] srs_mux_layer;
  logic [11:0] srs_mux_symbol;
  //
  logic [15:0] srs_mux_rtc_pc_id;
  //
  logic [ 7:0] srs_mux_frameid;
  logic [ 3:0] srs_mux_subframeid;
  logic [ 5:0] srs_mux_slotid;
  logic [ 5:0] srs_mux_symbolid;
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
  logic [ 2:0] srs_run_cc;
  logic [ 5:0] srs_run_layer;
  logic [11:0] srs_run_symbol;
  //
  logic [15:0] srs_run_rtc_pc_id;
  //
  logic [ 7:0] srs_run_frameid;
  logic [ 3:0] srs_run_subframeid;
  logic [ 5:0] srs_run_slotid;
  logic [ 5:0] srs_run_symbolid;
  //
  logic [ 3:0] srs_run_numsymbol;
  logic [ 7:0] srs_run_numprbc;
  logic [ 9:0] srs_run_startprbc;
  logic [11:0] srs_run_sectionid;
  //
  logic [ 2:0] srs_run_ethport;
  //
  logic        srs_run_valid;
  logic        srs_run_ready;

  // BRAM
  logic [11:0] bram_wr_addr;
  logic        bram_wr_en;
  logic [23:0] bram_wr_data;

  logic [ 9:0] bram_rd_addr;
  logic        bram_rd_en;
  logic [95:0] bram_rd_data;

  logic        bram_bank;

  // Framer
  logic [15:0] fram_req_rtc_pc_id;
  //
  logic [ 7:0] fram_req_frameid;
  logic [ 3:0] fram_req_subframeid;
  logic [ 5:0] fram_req_slotid;
  logic [ 5:0] fram_req_symbolid;
  //
  logic [ 3:0] fram_req_numsymbol;
  logic [ 7:0] fram_req_numprbc;
  logic [ 9:0] fram_req_startprbc;
  logic [11:0] fram_req_sectionid;
  //
  logic [ 2:0] fram_req_ethport;
  //
  logic        fram_req_valid;
  logic        fram_req_ready;

  // Control signals
  logic        ctrl_srs_en_s;
  // Use generated SRS message instead from DU
  logic        ctrl_srs_gen_en_s;
  // SRS message generator
  logic [15:0] ctrl_srs_rtc_pc_id_s;
  //
  logic [ 7:0] ctrl_srs_frameid_s;
  logic [ 3:0] ctrl_srs_subframeid_s;
  logic [ 5:0] ctrl_srs_slotid_s;
  logic [ 5:0] ctrl_srs_symbolid_s;
  //
  logic [ 3:0] ctrl_srs_numsymbol_s;
  logic [ 7:0] ctrl_srs_numprbc_s;
  logic [ 9:0] ctrl_srs_startprbc_s;
  logic [11:0] ctrl_srs_sectionid_s;
  //
  logic [ 2:0] ctrl_srs_ethport_s;
  //
  logic        ctrl_srs_valid_s;
  // Mu
  logic [ 1:0] ctrl_numerology_s     [      NUM_CC];


  // Control Signals CDC
  //====================

  xpm_cdc_single #(
      .DEST_SYNC_FF  (2),
      .INIT_SYNC_FF  (0),
      .SIM_ASSERT_CHK(0),
      .SRC_INPUT_REG (0)
  ) xpm_cdc_single_srs_en (
      .src_clk (1'b0),
      .src_in  (ctrl_srs_en),
      .dest_clk(clk_400m),
      .dest_out(ctrl_srs_en_s)
  );

  xpm_cdc_single #(
      .DEST_SYNC_FF  (2),
      .INIT_SYNC_FF  (0),
      .SIM_ASSERT_CHK(0),
      .SRC_INPUT_REG (0)
  ) xpm_cdc_single_srs_gen_en (
      .src_clk (1'b0),
      .src_in  (ctrl_srs_gen_en),
      .dest_clk(clk_400m),
      .dest_out(ctrl_srs_gen_en_s)
  );

  xpm_cdc_handshake #(
      .DEST_EXT_HSK  (0),
      .DEST_SYNC_FF  (2),
      .INIT_SYNC_FF  (0),
      .SIM_ASSERT_CHK(0),
      .SRC_SYNC_FF   (2),
      .WIDTH         (77)
  ) xpm_cdc_handshake_inst (
      .src_clk(ctrl_clk),
      .src_rcv(src_rcv),
      .src_in({
        ctrl_srs_rtc_pc_id,
        ctrl_srs_frameid,
        ctrl_srs_subframeid,
        ctrl_srs_slotid,
        ctrl_srs_symbolid,
        ctrl_srs_numsymbol,
        ctrl_srs_numprbc,
        ctrl_srs_startprbc,
        ctrl_srs_sectionid,
        ctrl_srs_ethport
      }),
      .src_send(src_send),
      //
      .dest_clk(clk_400m),
      .dest_req(ctrl_srs_valid_s),
      .dest_out({
        ctrl_srs_rtc_pc_id_s,
        ctrl_srs_frameid_s,
        ctrl_srs_subframeid_s,
        ctrl_srs_slotid_s,
        ctrl_srs_symbolid_s,
        ctrl_srs_numsymbol_s,
        ctrl_srs_numprbc_s,
        ctrl_srs_startprbc_s,
        ctrl_srs_sectionid_s,
        ctrl_srs_ethport_s
      }),
      .dest_ack(1'b1)
  );

  always_ff @(posedge ctrl_clk) begin
    if (ctrl_rst) begin
      src_send <= 1'b0;
    end else if (ctrl_srs_valid) begin
      src_send <= 1'b1;
    end else if (src_rcv) begin
      src_send <= 1'b0;
    end
  end

  generate
    for (genvar cc = 0; cc < NUM_CC; cc++) begin : g_cdc
      xpm_cdc_array_single #(
          .DEST_SYNC_FF  (2),
          .INIT_SYNC_FF  (0),
          .SIM_ASSERT_CHK(0),
          .SRC_INPUT_REG (0),
          .WIDTH         (2)
      ) xpm_cdc_single_numerology (
          .src_clk (1'b0),
          .src_in  (ctrl_numerology[cc]),
          .dest_clk(clk_400m),
          .dest_out(ctrl_numerology_s[cc])
      );
    end
  endgenerate


  // Pipe for timing
  always_ff @(posedge clk_400m) begin
    s_ul_sym_num_r <= s_ul_sym_num;
    s_ul_update_r  <= s_ul_update;
  end

  generate
    for (genvar i = 0; i < NUM_ETH_PORT; i++) begin : g_filter

      srs_adaptor_filter #(
          .NUM_CC(NUM_CC)
      ) i_filter (
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

  srs_adaptor_mux #(
      .NUM_CC      (NUM_CC),
      .NUM_ETH_PORT(NUM_ETH_PORT)
  ) i_mux (
      // XORIF
      //======
      .clk                (clk_400m),
      .rst                (rst_400m),
      // SRS Filter
      //===========
      .srs_flt_rtc_pc_id  (srs_flt_rtc_pc_id),
      //
      .srs_flt_frameid    (srs_flt_frameid),
      .srs_flt_subframeid (srs_flt_subframeid),
      .srs_flt_slotid     (srs_flt_slotid),
      .srs_flt_symbolid   (srs_flt_symbolid),
      //
      .srs_flt_numsymbol  (srs_flt_numsymbol),
      .srs_flt_numprbc    (srs_flt_numprbc),
      .srs_flt_startprbc  (srs_flt_startprbc),
      .srs_flt_sectionid  (srs_flt_sectionid),
      //
      .srs_flt_valid      (srs_flt_valid),
      // SRS MUX
      //========
      .srs_mux_cc         (srs_mux_cc),
      .srs_mux_layer      (srs_mux_layer),
      .srs_mux_symbol     (srs_mux_symbol),
      //
      .srs_mux_rtc_pc_id  (srs_mux_rtc_pc_id),
      //
      .srs_mux_frameid    (srs_mux_frameid),
      .srs_mux_subframeid (srs_mux_subframeid),
      .srs_mux_slotid     (srs_mux_slotid),
      .srs_mux_symbolid   (srs_mux_symbolid),
      //
      .srs_mux_numsymbol  (srs_mux_numsymbol),
      .srs_mux_numprbc    (srs_mux_numprbc),
      .srs_mux_startprbc  (srs_mux_startprbc),
      .srs_mux_sectionid  (srs_mux_sectionid),
      //
      .srs_mux_ethport    (srs_mux_ethport),
      //
      .srs_mux_valid      (srs_mux_valid),
      // Control
      //========
      .ctrl_srs_en        (ctrl_srs_en_s),
      //
      .ctrl_srs_gen_en    (ctrl_srs_gen_en_s),
      //
      .ctrl_srs_rtc_pc_id (ctrl_srs_rtc_pc_id_s),
      //
      .ctrl_srs_frameid   (ctrl_srs_frameid_s),
      .ctrl_srs_subframeid(ctrl_srs_subframeid_s),
      .ctrl_srs_slotid    (ctrl_srs_slotid_s),
      .ctrl_srs_symbolid  (ctrl_srs_symbolid_s),
      //
      .ctrl_srs_numsymbol (ctrl_srs_numsymbol_s),
      .ctrl_srs_numprbc   (ctrl_srs_numprbc_s),
      .ctrl_srs_startprbc (ctrl_srs_startprbc_s),
      .ctrl_srs_sectionid (ctrl_srs_sectionid_s),
      //
      .ctrl_srs_ethport   (ctrl_srs_ethport_s),
      //
      .ctrl_srs_valid     (ctrl_srs_valid_s),
      //
      .ctrl_numerology    (ctrl_numerology_s)
  );

  srs_adaptor_fwd #(
      .NUM_CC(NUM_CC)
  ) i_fwd (
      // XORIF
      //======
      .clk_400m         (clk_400m),
      .rst_400m         (rst_400m),
      // UL Timing
      .s_ul_sym_num     (s_ul_sym_num_r),
      .s_ul_update      (s_ul_update_r),
      // SRS Filter
      .srs_cc           (srs_mux_cc),
      .srs_symbol       (srs_mux_symbol),
      .srs_numsymbol    (srs_mux_numsymbol),
      //
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
      .srs_mux_cc        (srs_mux_cc),
      .srs_mux_layer     (srs_mux_layer),
      .srs_mux_symbol    (srs_mux_symbol),
      //
      .srs_mux_rtc_pc_id (srs_mux_rtc_pc_id),
      //
      .srs_mux_frameid   (srs_mux_frameid),
      .srs_mux_subframeid(srs_mux_subframeid),
      .srs_mux_slotid    (srs_mux_slotid),
      .srs_mux_symbolid  (srs_mux_symbolid),
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
      .srs_run_cc        (srs_run_cc),
      .srs_run_layer     (srs_run_layer),
      .srs_run_symbol    (srs_run_symbol),
      //
      .srs_run_rtc_pc_id (srs_run_rtc_pc_id),
      //
      .srs_run_frameid   (srs_run_frameid),
      .srs_run_subframeid(srs_run_subframeid),
      .srs_run_slotid    (srs_run_slotid),
      .srs_run_symbolid  (srs_run_symbolid),
      //
      .srs_run_numsymbol (srs_run_numsymbol),
      .srs_run_numprbc   (srs_run_numprbc),
      .srs_run_startprbc (srs_run_startprbc),
      .srs_run_sectionid (srs_run_sectionid),
      //
      .srs_run_ethport   (srs_run_ethport),
      //
      .srs_run_valid     (srs_run_valid),
      .srs_run_ready     (srs_run_ready),
      //
      .ctrl_srs_en       (ctrl_srs_en_s),
      .ctrl_srs_gen_en   (ctrl_srs_gen_en_s),
      .error_fifo_full   (  /* not used */)
  );

  srs_adaptor_runner #(
      .NUM_CC(NUM_CC)
  ) i_runner (
      // 400M
      //======
      .clk_400m           (clk_400m),
      .rst_400m           (rst_400m),
      // UL Timing
      .s_ul_sym_num       (s_ul_sym_num_r),
      .s_ul_update        (s_ul_update_r),
      // SRS Request
      .srs_run_cc         (srs_run_cc),
      .srs_run_layer      (srs_run_layer),
      .srs_run_symbol     (srs_run_symbol),
      //
      .srs_run_rtc_pc_id  (srs_run_rtc_pc_id),
      //
      .srs_run_frameid    (srs_run_frameid),
      .srs_run_subframeid (srs_run_subframeid),
      .srs_run_slotid     (srs_run_slotid),
      .srs_run_symbolid   (srs_run_symbolid),
      //
      .srs_run_numsymbol  (srs_run_numsymbol),
      .srs_run_numprbc    (srs_run_numprbc),
      .srs_run_startprbc  (srs_run_startprbc),
      .srs_run_sectionid  (srs_run_sectionid),
      //
      .srs_run_ethport    (srs_run_ethport),
      //
      .srs_run_valid      (srs_run_valid),
      .srs_run_ready      (srs_run_ready),
      // Frame Request
      //==============
      .fram_req_rtc_pc_id (fram_req_rtc_pc_id),
      //
      .fram_req_frameid   (fram_req_frameid),
      .fram_req_subframeid(fram_req_subframeid),
      .fram_req_slotid    (fram_req_slotid),
      .fram_req_symbolid  (fram_req_symbolid),
      //
      .fram_req_numsymbol (fram_req_numsymbol),
      .fram_req_numprbc   (fram_req_numprbc),
      .fram_req_startprbc (fram_req_startprbc),
      .fram_req_sectionid (fram_req_sectionid),
      //
      .fram_req_ethport   (fram_req_ethport),
      //
      .fram_req_valid     (fram_req_valid),
      .fram_req_ready     (fram_req_ready),
      // DFE
      //====
      .clk_491m52         (clk_491m52),
      .rst_491m52         (rst_491m52),
      // SRS Request
      .srs_req_cc         (srs_req_cc),
      .srs_req_layer      (srs_req_layer),
      .srs_req_symbol     (srs_req_symbol),
      .srs_req_valid      (srs_req_valid),
      //
      .srs_data_tdata     (srs_data_tdata),
      .srs_data_tlast     (srs_data_tlast),
      .srs_data_tvalid    (srs_data_tvalid),
      .srs_data_tready    (srs_data_tready),
      // BRAM
      .bram_bank          (bram_bank),
      //
      .bram_wr_addr       (bram_wr_addr),
      .bram_wr_en         (bram_wr_en),
      .bram_wr_data       (bram_wr_data)
  );

  srs_adaptor_buffer i_buffer (
      // Writer
      .clk_491m52  (clk_491m52),
      .rst_491m52  (rst_491m52),
      //
      .bram_bank   (bram_bank),
      //
      .bram_wr_addr(bram_wr_addr),  // 4096 * 24b
      .bram_wr_en  (bram_wr_en),
      .bram_wr_data(bram_wr_data),
      // Reader
      .clk_400m    (clk_400m),
      .rst_400m    (rst_400m),
      //
      .bram_rd_addr(bram_rd_addr),  // 1024 * 96b
      .bram_rd_en  (bram_rd_en),    // !connect to all registers in output pipe
      .bram_rd_data(bram_rd_data)   // 4 RE
  );

  srs_adaptor_framer i_framer (
      // DFE
      //====
      .clk                (clk_400m),
      .rst                (rst_400m),
      // Frame request
      .fram_req_rtc_pc_id (fram_req_rtc_pc_id),
      //
      .fram_req_frameid   (fram_req_frameid),
      .fram_req_subframeid(fram_req_subframeid),
      .fram_req_slotid    (fram_req_slotid),
      .fram_req_symbolid  (fram_req_symbolid),
      //
      .fram_req_numsymbol (fram_req_numsymbol),
      .fram_req_numprbc   (fram_req_numprbc),
      .fram_req_startprbc (fram_req_startprbc),
      .fram_req_sectionid (fram_req_sectionid),
      //
      .fram_req_ethport   (fram_req_ethport),
      //
      .fram_req_valid     (fram_req_valid),
      .fram_req_ready     (fram_req_ready),
      // BRAM
      //=====
      .bram_addr          (bram_rd_addr),
      .bram_rden          (bram_rd_en),
      .bram_data          (bram_rd_data),         // {4'b exponent, 9'b mantissa Q, 9'b mantissa I}
      // UNSOL port
      //===========
      .m_fram_unsol_tdata (m_fram_unsol_tdata),
      .m_fram_unsol_tkeep (m_fram_unsol_tkeep),
      .m_fram_unsol_tvalid(m_fram_unsol_tvalid),
      .m_fram_unsol_tlast (m_fram_unsol_tlast),
      .m_fram_unsol_tready(m_fram_unsol_tready),
      .m_fram_unsol_tuser (m_fram_unsol_tuser)
  );

endmodule

`default_nettype wire
