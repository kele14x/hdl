`timescale 1 ns / 1 ps `default_nettype none

module ul_adaptor_gearbox #(
    parameter int NUM_CC = 2,
    parameter int NUM_UL_LAYER = 8
) (
    // Interface with XORIF
    //=====================
    input var         clk_400m,
    input var         rst_400m,
    // ul timing
    input var         fram_radio_start_10ms,
    // ul data
    output var [63:0] m_fram_data_tdata    [NUM_UL_LAYER],
    output var [ 7:0] m_fram_data_tkeep    [NUM_UL_LAYER],
    output var        m_fram_data_tvalid   [NUM_UL_LAYER],
    output var        m_fram_data_tlast    [NUM_UL_LAYER],
    input var         m_fram_data_tready   [NUM_UL_LAYER],
    // request for ul data
    input var  [24:0] m_fram_data_req      [NUM_UL_LAYER],
    // Interface with DFE
    //===================
    input var         clk_491m52,
    input var         rst_491m52,
    //
    output var [11:0] ram_addr             [      NUM_CC][NUM_UL_LAYER],
    output var        ram_rden             [      NUM_CC][NUM_UL_LAYER],
    input var  [63:0] ram_data             [      NUM_CC][NUM_UL_LAYER],
    // Control Interface
    //==================
    input var  [ 1:0] ctrl_compression_mode[      NUM_CC]
);


  logic [63:0] s_axis_tdata  [NUM_UL_LAYER];
  logic [ 7:0] s_axis_tkeep  [NUM_UL_LAYER];
  logic        s_axis_tvalid [NUM_UL_LAYER];
  logic        s_axis_tlast  [NUM_UL_LAYER];
  logic        s_axis_tready [NUM_UL_LAYER];

  logic [11:0] ram_addr_s    [NUM_UL_LAYER] [NUM_CC];
  logic        ram_rden_s    [NUM_UL_LAYER] [NUM_CC];
  logic [63:0] ram_data_s    [NUM_UL_LAYER] [NUM_CC];

  logic [23:0] fram_req_data [NUM_UL_LAYER];
  logic        fram_req_rden [NUM_UL_LAYER];
  logic        fram_req_empty[NUM_UL_LAYER];


  generate
    for (genvar cc = 0; cc < NUM_CC; cc++) begin : g_as
      for (genvar ly = 0; ly < NUM_UL_LAYER; ly++) begin : g_ly
        assign ram_addr[cc][ly]   = ram_data_s[ly][cc];
        assign ram_rden[cc][ly]   = ram_rden_s[ly][cc];
        assign ram_data_s[ly][cc] = ram_data[cc][ly];
      end
    end
  endgenerate

  generate
    for (genvar i = 0; i < NUM_UL_LAYER; i++) begin : g_ly

      ul_adaptor_fram_fifo i_ul_adaptor_fram_fifo (
          // Writer side
          .s_aclk       (clk_491m52),
          .s_aresetn    (~rst_491m52),
          .s_axis_tdata (s_axis_tdata[i]),
          .s_axis_tkeep (s_axis_tkeep[i]),
          .s_axis_tvalid(s_axis_tvalid[i]),
          .s_axis_tlast (s_axis_tlast[i]),
          .s_axis_tready(s_axis_tready[i]),
          // Reader side
          .m_aclk       (clk_400m),
          .m_axis_tdata (m_fram_data_tdata[i]),
          .m_axis_tkeep (m_fram_data_tkeep[i]),
          .m_axis_tvalid(m_fram_data_tvalid[i]),
          .m_axis_tlast (m_fram_data_tlast[i]),
          .m_axis_tready(m_fram_data_tready[i])
      );

      ul_adaptor_req_fifo i_ul_adaptor_req_fifo (
          .rst   (rst_400m),
          // Write side
          .wr_clk(clk_400m),
          .wr_en (m_fram_data_req[24]),
          .din   (m_fram_data_req[23:0]),
          .full  (  /* Assume it will not full */),
          // Reader side
          .rd_clk(clk_491m52),
          .rd_en (fram_req_rden[i]),
          .dout  (fram_req_data[i]),
          .empty (fram_req_empty[i])
      );

      ul_adaptor_gearbox_raw #(
          .NUM_CC(NUM_CC)
      ) i_ul_adaptor_gearbox_raw (
          .clk_491m52           (clk_491m52),
          .rst_491m52           (rst_491m52),
          // ul timing
          .fram_radio_start_10ms(fram_radio_start_10ms),
          // ul data
          .m_axis_tdata         (s_axis_tdata[i]),
          .m_axis_tkeep         (s_axis_tkeep[i]),
          .m_axis_tvalid        (s_axis_tvalid[i]),
          .m_axis_tlast         (s_axis_tlast[i]),
          .m_axis_tready        (s_axis_tready[i]),
          //
          .fram_req_data        (fram_req_data[i]),
          .fram_req_rden        (fram_req_rden[i]),
          .fram_req_empty       (fram_req_empty[i]),
          //
          .ram_addr             (ram_addr[i]),
          .ram_rden             (ram_rden[i]),
          .ram_data             (ram_data[i])
      );

    end
  endgenerate

endmodule

`default_nettype wire
