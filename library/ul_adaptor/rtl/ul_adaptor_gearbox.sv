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
    input var         ul_radio_start_10ms,
    input var         ul_update            [      NUM_CC],
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
    output var [11:0] ram_addr             [NUM_UL_LAYER][NUM_CC],
    output var        ram_rden             [NUM_UL_LAYER][NUM_CC],
    input var  [63:0] ram_data             [NUM_UL_LAYER][NUM_CC],
    // Control Interface
    //==================
    input var  [ 1:0] ctrl_compression_mode[      NUM_CC]
);


  logic        ul_update_sync     [      NUM_CC];

  logic [23:0] fram_req_data_s    [NUM_UL_LAYER];
  logic        fram_req_rden_s    [NUM_UL_LAYER];
  logic        fram_req_empty_s   [NUM_UL_LAYER];

  logic [23:0] fram_req_data_raw  [NUM_UL_LAYER];
  logic        fram_req_rden_raw  [NUM_UL_LAYER];
  logic        fram_req_empty_raw [NUM_UL_LAYER];

  logic [23:0] fram_req_data_bfp9 [NUM_UL_LAYER];
  logic        fram_req_rden_bfp9 [NUM_UL_LAYER];
  logic        fram_req_empty_bfp9[NUM_UL_LAYER];

  logic [11:0] ram_addr_raw       [NUM_UL_LAYER] [NUM_CC];
  logic        ram_rden_raw       [NUM_UL_LAYER] [NUM_CC];
  logic [63:0] ram_data_raw       [NUM_UL_LAYER] [NUM_CC];

  logic [11:0] ram_addr_bfp9      [NUM_UL_LAYER] [NUM_CC];
  logic        ram_rden_bfp9      [NUM_UL_LAYER] [NUM_CC];
  logic [63:0] ram_data_bfp9      [NUM_UL_LAYER] [NUM_CC];

  logic [63:0] s_axis_tdata_s     [NUM_UL_LAYER];
  logic [ 7:0] s_axis_tkeep_s     [NUM_UL_LAYER];
  logic        s_axis_tvalid_s    [NUM_UL_LAYER];
  logic        s_axis_tlast_s     [NUM_UL_LAYER];
  logic        s_axis_tready_s    [NUM_UL_LAYER];

  logic [63:0] s_axis_tdata_raw   [NUM_UL_LAYER];
  logic [ 7:0] s_axis_tkeep_raw   [NUM_UL_LAYER];
  logic        s_axis_tvalid_raw  [NUM_UL_LAYER];
  logic        s_axis_tlast_raw   [NUM_UL_LAYER];
  logic        s_axis_tready_raw  [NUM_UL_LAYER];

  logic [63:0] s_axis_tdata_bfp9  [NUM_UL_LAYER];
  logic [ 7:0] s_axis_tkeep_bfp9  [NUM_UL_LAYER];
  logic        s_axis_tvalid_bfp9 [NUM_UL_LAYER];
  logic        s_axis_tlast_bfp9  [NUM_UL_LAYER];
  logic        s_axis_tready_bfp9 [NUM_UL_LAYER];

  logic [72:0] fifo_din           [NUM_UL_LAYER];
  logic        fifo_full          [NUM_UL_LAYER];
  logic        fifo_wren          [NUM_UL_LAYER];
  logic [72:0] fifo_dout          [NUM_UL_LAYER];
  logic        fifo_empty         [NUM_UL_LAYER];
  logic        fifo_rden          [NUM_UL_LAYER];

  generate
    for (genvar cc = 0; cc < NUM_CC; cc++) begin : g_as

      xpm_cdc_pulse #(
          .DEST_SYNC_FF  (4),
          .INIT_SYNC_FF  (0),
          .REG_OUTPUT    (1),
          .RST_USED      (1),
          .SIM_ASSERT_CHK(0)
      ) i_cdc_ul_update (
          .src_clk(clk_400m),
          .src_rst(rst_400m),
          .src_pulse(ul_update[cc]),
          .dest_clk(clk_491m52),
          .dest_rst(rst_491m52),
          .dest_pulse(ul_update_sync[cc])
      );

    end
  endgenerate

  generate
    for (genvar i = 0; i < NUM_UL_LAYER; i++) begin : g_ly

      ul_adaptor_req_fifo i_ul_adaptor_req_fifo (
          .rst   (rst_400m),
          // Write side
          .wr_clk(clk_400m),
          .wr_en (m_fram_data_req[i][24]),
          .din   (m_fram_data_req[i][23:0]),
          .full  (  /* Assume it will not full */),
          // Reader side
          .rd_clk(clk_491m52),
          .rd_en (fram_req_rden_s[i]),
          .dout  (fram_req_data_s[i]),
          .empty (fram_req_empty_s[i])
      );

      assign fram_req_data_raw[i] = ctrl_compression_mode[0] == 0 ? fram_req_data_s[i] : '0;
      assign fram_req_empty_raw[i] = ctrl_compression_mode[0] == 0 ? fram_req_empty_s[i] : '1;

      assign fram_req_data_bfp9[i] = ctrl_compression_mode[0] == 1 ? fram_req_data_s[i] : '0;
      assign fram_req_empty_bfp9[i] = ctrl_compression_mode[0] == 1 ? fram_req_empty_s[i] : '1;

      assign fram_req_rden_s[i]    = ctrl_compression_mode[0] == 0 ? fram_req_rden_raw[i] : fram_req_rden_bfp9[i];

      ul_adaptor_gearbox_raw #(
          .NUM_CC(NUM_CC)
      ) i_ul_adaptor_gearbox_raw (
          .clk                  (clk_491m52),
          .rst                  (rst_491m52),
          // ul timing
          .ul_radio_start_10ms  (ul_radio_start_10ms),
          .ul_update            (ul_update_sync),
          // ul data
          .m_axis_tdata         (s_axis_tdata_raw[i]),
          .m_axis_tkeep         (s_axis_tkeep_raw[i]),
          .m_axis_tvalid        (s_axis_tvalid_raw[i]),
          .m_axis_tlast         (s_axis_tlast_raw[i]),
          .m_axis_tready        (s_axis_tready_raw[i]),
          //
          .fram_req_data        (fram_req_data_raw[i]),
          .fram_req_rden        (fram_req_rden_raw[i]),
          .fram_req_empty       (fram_req_empty_raw[i]),
          //
          .uram_addr            (ram_addr_raw[i]),
          .uram_rden            (ram_rden_raw[i]),
          .uram_data            (ram_data_raw[i])
      );

      ul_adaptor_gearbox_bfp9 #(
          .NUM_CC(NUM_CC)
      ) i_ul_adaptor_gearbox_bfp9 (
          .clk                  (clk_491m52),
          .rst                  (rst_491m52),
          // ul timing
          .ul_radio_start_10ms  (ul_radio_start_10ms),
          .ul_update            (ul_update_sync),
          // ul data
          .m_axis_tdata         (s_axis_tdata_bfp9[i]),
          .m_axis_tkeep         (s_axis_tkeep_bfp9[i]),
          .m_axis_tvalid        (s_axis_tvalid_bfp9[i]),
          .m_axis_tlast         (s_axis_tlast_bfp9[i]),
          .m_axis_tready        (s_axis_tready_bfp9[i]),
          //
          .fram_req_data        (fram_req_data_bfp9[i]),
          .fram_req_rden        (fram_req_rden_bfp9[i]),
          .fram_req_empty       (fram_req_empty_bfp9[i]),
          //
          .uram_addr            (ram_addr_bfp9[i]),
          .uram_rden            (ram_rden_bfp9[i]),
          .uram_data            (ram_data_bfp9[i])
      );

      assign ram_addr[i] = ctrl_compression_mode[0] == 0 ? ram_addr_raw[i] : ram_addr_bfp9[i];
      assign ram_rden[i] = ctrl_compression_mode[0] == 0 ? ram_rden_raw[i] : ram_rden_bfp9[i];

      assign ram_data_raw[i] = ctrl_compression_mode[0] == 0 ? ram_data[i] : '{NUM_CC{'0}};
      assign ram_data_bfp9[i] = ctrl_compression_mode[0] == 1 ? ram_data[i] : '{NUM_CC{'0}};


      assign s_axis_tdata_s[i]  = ctrl_compression_mode[0] == 0 ? s_axis_tdata_raw[i] : s_axis_tdata_bfp9[i];
      assign s_axis_tkeep_s[i]  = ctrl_compression_mode[0] == 0 ? s_axis_tkeep_raw[i] : s_axis_tkeep_bfp9[i];
      assign s_axis_tvalid_s[i] = ctrl_compression_mode[0] == 0 ? s_axis_tvalid_raw[i] : s_axis_tvalid_bfp9[i];
      assign s_axis_tlast_s[i]  = ctrl_compression_mode[0] == 0 ? s_axis_tlast_raw[i] : s_axis_tlast_bfp9[i];

      assign s_axis_tready_raw[i] = ctrl_compression_mode[0] == 0 ? s_axis_tready_s[i] : 1'b1;
      assign s_axis_tready_bfp9[i] = ctrl_compression_mode[0] == 1 ? s_axis_tready_s[i] : 1'b1;

      ul_adaptor_fram_fifo i_ul_adaptor_fram_fifo (
          // Writer side (input)
          .wr_clk(clk_491m52),
          .rst   (rst_491m52),
          .din   (fifo_din[i]),
          .wr_en (fifo_wren[i]),
          .full  (fifo_full[i]),
          // Reader side (output)
          .rd_clk(clk_400m),
          .dout  (fifo_dout[i]),
          .empty (fifo_empty[i]),
          .rd_en (fifo_rden[i])
      );

      assign fifo_din[i] = {s_axis_tlast_s[i], s_axis_tkeep_s[i], s_axis_tdata_s[i]};
      assign fifo_wren[i] = s_axis_tvalid_s[i];
      assign s_axis_tready_s[i] = ~fifo_full[i];

      // Bug work around for XORIF, tlast should be exactly 1 tick
      assign m_fram_data_tlast[i] = fifo_dout[i][72] && (~fifo_empty[i]);
      assign m_fram_data_tkeep[i] = fifo_dout[i][71:64];
      assign m_fram_data_tdata[i] = fifo_dout[i][63:0];
      
      assign m_fram_data_tvalid[i] = ~fifo_empty[i];
      assign fifo_rden[i] = m_fram_data_tready[i];

    end
  endgenerate

endmodule

`default_nettype wire
