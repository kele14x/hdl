// File: dl_adaptor.sv
// Brief: Downlink PDxCH (DL U-Plane data) adaptor. Input is 4 branch (4 dl
//        layer) stream from XORIF ip core, each stream contains all CCs' data.
//        However, output has different share structure. Each stream contains 4
//        layer interleaved data. Also each CC has separated port, resulting
//        8 streams for 4 branches/layers and 2 CCs.
`timescale 1 ns / 1 ps `default_nettype none

module dl_adaptor #(
    parameter int NUM_CC = 2,
    parameter int NUM_DL_LAYER = 16
) (
    // Interface with XORIF
    //=====================
    input var         clk_400m,
    input var         rst_400m,
    // Timing ports
    input var         defm_radio_start_10ms,
    input var         s_dl_update          [      NUM_CC],
    // 4 branch/layer stream, CC shared
    input var  [63:0] s_defm_data_tdata    [NUM_DL_LAYER],
    input var  [ 7:0] s_defm_data_tkeep    [NUM_DL_LAYER],
    input var         s_defm_data_tvalid   [NUM_DL_LAYER],
    input var         s_defm_data_tlast    [NUM_DL_LAYER],
    output var        s_defm_data_tready   [NUM_DL_LAYER],
    input var  [30:0] s_defm_data_tuser    [NUM_DL_LAYER],
    // Interface with DFE
    //===================
    input var         clk_491m52,
    input var         rst_491m52,
    // DL symbol timing
    input var         dl_radio_start_10ms,
    // 2 CC port, each will have interleaved 4 layer data
    output var        dl_sof               [      NUM_CC][NUM_DL_LAYER],
    output var        dl_sos               [      NUM_CC][NUM_DL_LAYER],
    output var [15:0] dl_data_i            [      NUM_CC][NUM_DL_LAYER],
    output var [15:0] dl_data_q            [      NUM_CC][NUM_DL_LAYER],
    output var        dl_valid             [      NUM_CC][NUM_DL_LAYER],
    // Control Interface
    //==================
    input var  [ 3:0] ctrl_bandwidth       [      NUM_CC],
    input var  [ 1:0] ctrl_numerology      [      NUM_CC],
    input var  [ 1:0] ctrl_compression_mode[      NUM_CC]
);

  // Start of symbol for each CC
  logic        gb_sos  [NUM_CC];

  logic [63:0] gb_data [NUM_CC] [NUM_DL_LAYER];
  logic        gb_valid[NUM_CC] [NUM_DL_LAYER];
  logic [11:0] gb_re   [NUM_CC] [NUM_DL_LAYER];

  generate
    for (genvar i = 0; i < NUM_CC; i++) begin : g_cdc

      xpm_cdc_pulse #(
          .DEST_SYNC_FF  (2),
          .INIT_SYNC_FF  (0),
          .REG_OUTPUT    (1),
          .RST_USED      (1),
          .SIM_ASSERT_CHK(0)
      ) i_xpm_cdc_pulse_s_dl_update (
          .src_clk   (clk_400m),
          .src_rst   (rst_400m),
          .src_pulse (s_dl_update[i]),
          .dest_clk  (clk_491m52),
          .dest_rst  (rst_491m52),
          .dest_pulse(gb_sos[i])
      );

    end
  endgenerate


  dl_adaptor_gearbox i_dl_adaptor_gearbox (
      // Interface with XORIF
      //=====================
      .clk_400m             (clk_400m),
      .rst_400m             (rst_400m),
      //
      .s_defm_data_tdata    (s_defm_data_tdata),
      .s_defm_data_tkeep    (s_defm_data_tkeep),
      .s_defm_data_tvalid   (s_defm_data_tvalid),
      .s_defm_data_tlast    (s_defm_data_tlast),
      .s_defm_data_tready   (s_defm_data_tready),
      .s_defm_data_tuser    (s_defm_data_tuser),
      // Interface with DFE
      //===================
      .clk_491m52           (clk_491m52),
      .rst_491m52           (rst_491m52),
      // Shared by CC0 and CC1
      .gb_data              (gb_data),  // {Q, I}
      .gb_valid             (gb_valid),
      .gb_re                (gb_re),  // RE number, 0 ~ 3275
      // Control Interface
      //==================
      .ctrl_compression_mode(ctrl_compression_mode)
  );


  generate
    for (genvar i = 0; i < NUM_CC; i++) begin: g_buf

      //
      dl_adaptor_buf #(
          .LAYER_NUMBER_C(NUM_DL_LAYER)
      ) dl_adaptor_buf (
          // Clock & Reset
          //==============
          .clk_491m_i                (clk_491m52),
          .rst_491m_i                (rst_491m52),
          .clk_491m_gating_dl_i      (clk_491m52),
          .clk_491m_gating_dl_flush_i(rst_491m52),
          // DL extra timing ports
          // TODO:
          .s0_rd_trig_i              (1'b0),
          .s0_rd_trig_en             (1'b0),
          // Data from Gearbox
          .dl_data_i                 (gb_data),
          .dl_data_sof_i             (dl_radio_start_10ms),
          .dl_data_sop_i             (gb_sos[i]),
          .dl_data_valid_i           (gb_valid),
          .re_no_i                   (gb_re),
          // Data output to DFE
          .dl_di_o                   (dl_data_i[i]),
          .dl_dq_o                   (dl_data_q[i]),
          .dl_sof_o                  (dl_sof[i]),
          .dl_sop_o                  (dl_sos[i]),
          .dl_sof_ahead_7_o          (  /* Not used */),
          .dl_sop_ahead_7_o          (  /* Not used */),
          .dl_valid_o                (dl_valid[i]),
          // Control interface
          //===================
          .bw_mode_i                 (ctrl_bandwidth[i]),  // Bandwidth mode
          .rat_mode_i                (ctrl_numerology[i]),  // Numerology
          .compression_mode          (ctrl_compression_mode[i]),  // Compression mode
          //
          .buffer_mem_ctrl_en        ( /* Not used */),
          .buffer_mem_addr_i         ( /* Not used */),
          .buffer_mem_data_i         ( /* Not used */),
          .buffer_mem_we             ( /* Not used */),
          .buffer_mem_data_o         ( /* Not used */)
      );

    end
  endgenerate

endmodule

`default_nettype wire
