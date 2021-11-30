// File: ul_adaptor.sv
// Brief: Uplink PUxCH (UL U-Plane data) adaptor. Input are 16 (8 branch x 2 CC)
//        streams from DFE module. Each stream contains bit-reversed data from
//        FFT process.
//        Output are 8 streams. Each stream contains all CCs data for one layer.
//
//                                 +------------+
//                                 |            |
//           fram_radio_start_10ms |            |  ul_sof
//          <----------------------+            |<--------
//                                 |            |
//                                 |            |
//                       ul_update | ul_adaptor |
//          ---------------------->|            |
//                                 |            |
//                   fram_data_req |            |
//          ---------------------->|            |
//                                 |            |
//                                 +------------+
//
`timescale 1 ns / 1 ps `default_nettype none

module ul_adaptor #(
    parameter int NUM_CC = 2,
    parameter int NUM_UL_LAYER = 8
) (
    // Interface with XORIF
    //=====================
    input var         clk_400m,
    input var         rst_400m,
    //
    output var        fram_radio_start_10ms,
    input var         s_ul_update          [      NUM_CC],
    //
    output var [63:0] m_fram_data_tdata    [NUM_UL_LAYER],
    output var [ 7:0] m_fram_data_tkeep    [NUM_UL_LAYER],
    output var        m_fram_data_tvalid   [NUM_UL_LAYER],
    output var        m_fram_data_tlast    [NUM_UL_LAYER],
    input var         m_fram_data_tready   [NUM_UL_LAYER],
    //
    input var  [24:0] m_fram_data_req      [NUM_UL_LAYER],
    // Interface with DFE
    //===================
    input var         clk_491m52,
    //
    input var         ul_sof_ahead_3       [      NUM_CC],
    input var         ul_sop_ahead_3       [      NUM_CC],
    input var  [15:0] ul_data_i            [      NUM_CC][NUM_UL_LAYER],
    input var  [15:0] ul_data_q            [      NUM_CC][NUM_UL_LAYER],
    // Control Interface
    //==================
    input var  [ 3:0] ctrl_bandwidth       [      NUM_CC],
    input var  [ 1:0] ctrl_numerology      [      NUM_CC],
    input var  [ 1:0] ctrl_compression_mode[      NUM_CC],
    //
    input var  [ 1:0] buffer_mem_ctrl_en   [      NUM_CC],
    input var  [11:0] buffer_mem_addr_i    [      NUM_CC][NUM_UL_LAYER],
    input var  [31:0] buffer_mem_data_i    [      NUM_CC][NUM_UL_LAYER],
    input var         buffer_mem_we        [      NUM_CC][NUM_UL_LAYER],
    output var [31:0] buffer_mem_data_o    [      NUM_CC][NUM_UL_LAYER]
);

  logic        rst_491m52;

  logic [11:0] ram_addr_s         [NUM_UL_LAYER] [      NUM_CC];
  logic        ram_rden_s         [NUM_UL_LAYER] [      NUM_CC];
  logic [63:0] ram_data_s         [NUM_UL_LAYER] [      NUM_CC];

  logic [11:0] ram_addr           [      NUM_CC] [NUM_UL_LAYER];
  logic        ram_rden           [      NUM_CC] [NUM_UL_LAYER];
  logic [63:0] ram_data           [      NUM_CC] [NUM_UL_LAYER];

  logic        ul_radio_start_10ms[      NUM_CC];


  // We will get two SOP from DFE module (each for one CC). We assume they
  // are same so we only use [0].
  xpm_cdc_pulse #(
      .DEST_SYNC_FF  (4),
      .INIT_SYNC_FF  (0),
      .REG_OUTPUT    (1),
      .RST_USED      (0),
      .SIM_ASSERT_CHK(0)
  ) xpm_cdc_pulse_inst (
      .src_clk   (clk_491m52),
      .src_rst   (rst_491m52),
      .src_pulse (ul_radio_start_10ms[0]),
      .dest_clk  (clk_400m),
      .dest_rst  (rst_400m),
      .dest_pulse(fram_radio_start_10ms)
  );

  xpm_cdc_async_rst #(
      .DEST_SYNC_FF   (4),
      .INIT_SYNC_FF   (0),
      .RST_ACTIVE_HIGH(1)
  ) xpm_cdc_async_rst_inst (
      .src_arst (rst_400m),
      .dest_clk (clk_491m52),
      .dest_arst(rst_491m52)
  );

  ul_adaptor_gearbox #(
      .NUM_CC      (NUM_CC),
      .NUM_UL_LAYER(NUM_UL_LAYER)
  ) i_ul_adaptor_gearbox (
      // Interface with XORIF
      //=====================
      .clk_400m             (clk_400m),
      .rst_400m             (rst_400m),
      // ul timing
      .ul_radio_start_10ms  (ul_radio_start_10ms[0]),
      .ul_update            (s_ul_update),
      // ul data
      .m_fram_data_tdata    (m_fram_data_tdata),
      .m_fram_data_tkeep    (m_fram_data_tkeep),
      .m_fram_data_tvalid   (m_fram_data_tvalid),
      .m_fram_data_tlast    (m_fram_data_tlast),
      .m_fram_data_tready   (m_fram_data_tready),
      // request for ul data
      .m_fram_data_req      (m_fram_data_req),
      // Interface with DFE
      //===================
      .clk_491m52           (clk_491m52),
      .rst_491m52           (rst_491m52),
      //
      .ram_addr             (ram_addr_s),
      .ram_rden             (ram_rden_s),
      .ram_data             (ram_data_s),
      // Control Interface
      //==================
      .ctrl_compression_mode(ctrl_compression_mode)
  );

  generate
    for (genvar cc = 0; cc < NUM_CC; cc++) begin : g_cc
      for (genvar ly = 0; ly < NUM_UL_LAYER; ly++) begin : g_ly
        assign ram_addr[cc][ly]   = ram_addr_s[ly][cc];
        assign ram_rden[cc][ly]   = ram_rden_s[ly][cc];
        assign ram_data_s[ly][cc] = ram_data[cc][ly];
      end
    end
  endgenerate

  generate
    for (genvar i = 0; i < NUM_CC; i++) begin : g_buf
      ul_adaptor_buf #(
          .LAYER_NUMBER_C(NUM_UL_LAYER)
      ) i_ul_adaptor_buf (
          // DFE Interface
          //==============
          .clk_491m_i                (clk_491m52),
          .rst_491m_i                (rst_491m52),
          .clk_491m_gating_ul_i      (clk_491m52),
          .clk_491m_gating_ul_flush_i(1'b0),
          //
          .ul_sof_ahead_3_i          (ul_sof_ahead_3[i]),
          .ul_sop_ahead_3_i          (ul_sop_ahead_3[i]),
          .ul_di_i                   (ul_data_i[i]),
          .ul_dq_i                   (ul_data_q[i]),
          // Internal Interface
          //===================
          .ul_buf_ready_o            (ul_radio_start_10ms[i]),
          //
          .buffer_rd_addr_i          (ram_addr[i]),
          .buffer_rd_en_i            (ram_rden[i]),
          .ul_data_o                 (ram_data[i]),
          .ul_data_sop_o             (  /* not used */),
          .ul_data_valid_o           (  /* not used */),
          // Control Interface
          //==================
          .clk_axi                   (1'b0),
          .rst_axi                   (1'b0),
          //
          .bw_mode_i                 (ctrl_bandwidth[i]),
          .rat_mode_i                (ctrl_numerology[i]),
          //
          .buffer_mem_ctrl_en        (buffer_mem_ctrl_en[i]),
          .buffer_mem_addr_i         (buffer_mem_addr_i[i]),
          .buffer_mem_data_i         (buffer_mem_data_i[i]),
          .buffer_mem_we             (buffer_mem_we[i]),
          .buffer_mem_data_o         (buffer_mem_data_o[i])
      );
    end
  endgenerate

endmodule

`default_nettype wire
