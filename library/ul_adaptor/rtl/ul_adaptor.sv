// File: ul_adaptor.sv
// Brief: Uplink PUxCH (UL U-Plane data) adaptor. Input are 16 (8 branch x 2 CC)
//        streams from DFE module. Each stream contains bit-reversed data from
//        FFT process.
//        Output are 8 streams. Each stream contains all CCs data for one layer.
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
    output var        ul_radio_start_10ms,
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
    input var         rst_491m52,
    //
    input var         ul_sof,
    input var         ul_sos               [      NUM_CC],
    input var  [15:0] ul_data_i            [      NUM_CC][NUM_UL_LAYER],
    input var  [15:0] ul_data_q            [      NUM_CC][NUM_UL_LAYER],
    input var         ul_valid             [      NUM_CC],
    // Control Interface
    //==================
    input var  [ 3:0] ctrl_bandwidth       [      NUM_CC],
    input var  [ 1:0] ctrl_numerology      [      NUM_CC],
    input var  [ 1:0] ctrl_compression_mode[      NUM_CC]
);


  logic [11:0] ram_addr              [NUM_CC][NUM_UL_LAYER];
  logic        ram_rden              [NUM_CC][NUM_UL_LAYER];
  logic [63:0] ram_data              [NUM_CC][NUM_UL_LAYER];

  logic        fram_radio_start_10ms;

  ul_adaptor_gearbox #(
      .NUM_CC      (NUM_CC),
      .NUM_UL_LAYER(NUM_UL_LAYER)
  ) i_ul_adaptor_gearbox (
      // Interface with XORIF
      //=====================
      .clk_400m             (clk_400m),
      .rst_400m             (rst_400m),
      // ul timing
      .fram_radio_start_10ms(fram_radio_start_10ms),
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
      .ram_addr             (ram_addr),
      .ram_rden             (ram_rden),
      .ram_data             (ram_data),
      // Control Interface
      //==================
      .ctrl_compression_mode(ctrl_compression_mode)
  );

endmodule

`default_nettype wire
