// file: ul_adaptor_buf.sv
// brief: This file is wrapper for SysGen generated block (ul_adaptor_ctrl and
//        ul_adaptor_data).
`timescale 1 ns / 1 ps `default_nettype none

module ul_adaptor_buf #(
    parameter int LAYER_NUMBER_C = 8
) (
    // DFE Interface with UL
    //======================
    // Clock & Reset
    input var         clk_491m_i,
    input var         rst_491m_i,
    input var         clk_491m_gating_ul_i,
    input var         clk_491m_gating_ul_flush_i,
    // Data bus & valid & sop & sof & index input
    input var  [15:0] ul_di_i                   [LAYER_NUMBER_C],
    input var  [15:0] ul_dq_i                   [LAYER_NUMBER_C],
    input var         ul_sof_ahead_3_i,
    input var         ul_sop_ahead_3_i,
    // Interface with Reader
    //======================
    output var        ul_buf_ready_o,
    //
    input var  [11:0] buffer_rd_addr_i          [LAYER_NUMBER_C],
    input var         buffer_rd_en_i            [LAYER_NUMBER_C],
    output var [63:0] ul_data_o                 [LAYER_NUMBER_C],
    output var        ul_data_sop_o             [LAYER_NUMBER_C],
    output var        ul_data_valid_o           [LAYER_NUMBER_C],
    // Control Interface
    //==================
    // AXI clk&rst
    input var         clk_axi,
    input var         rst_axi,
    // RAT and bandwidth configuration
    input var  [ 3:0] bw_mode_i,
    input var  [ 1:0] rat_mode_i,
    // BRAM
    input var  [ 1:0] buffer_mem_ctrl_en,
    input var  [11:0] buffer_mem_addr_i         [LAYER_NUMBER_C],
    input var  [31:0] buffer_mem_data_i         [LAYER_NUMBER_C],
    input var         buffer_mem_we             [LAYER_NUMBER_C],
    output var [31:0] buffer_mem_data_o         [LAYER_NUMBER_C]
);


  logic [13:0] buffer_wr_ctrl  [8];

  ul_adaptor_ctrl inst_ul_adaptor_ctrl (
      .clk             (clk_491m_i),
      .bw_sel_i        (bw_mode_i),
      .rat_mode_i      (rat_mode_i),
      .ul_sof_ahead_3_i(ul_sof_ahead_3_i),
      .ul_sop_ahead_3_i(ul_sop_ahead_3_i),
      .buffer_wr_ctrl  (buffer_wr_ctrl[0]),
      .symbol_no_o     (  /* Not used */),
      .ul_buf_ready_o  (ul_buf_ready_o)
  );


  generate
    for (genvar ii = 0; ii <= 2; ii++) begin : g_dly
      always_ff @(posedge clk_491m_i) begin
        buffer_wr_ctrl[ii+1] <= buffer_wr_ctrl[ii];
      end
    end
  endgenerate

  generate
    for (genvar ii = 0; ii <= 3; ii++) begin : g_cpy
      assign buffer_wr_ctrl[ii+4] = buffer_wr_ctrl[ii];
    end
  endgenerate


  generate
    for (genvar ii = 0; ii < LAYER_NUMBER_C; ii++) begin
      ul_adaptor_data inst_ul_adaptor_data (
          .clk               (clk_491m_gating_ul_i),
          .buffer_mem_addr_i (buffer_mem_addr_i[ii]),
          .buffer_mem_ctrl_en(buffer_mem_ctrl_en),
          .buffer_mem_data_i (buffer_mem_data_i[ii]),
          .buffer_mem_we     (buffer_mem_we[ii]),
          .buffer_mem_data_o (buffer_mem_data_o[ii]),
          .buffer_wr_ctrl_i  ({1'b0, buffer_wr_ctrl[ii]}),
          .buffer_rd_addr_i  (buffer_rd_addr_i[ii]),
          .buffer_rd_en_i    (buffer_rd_en_i[ii]),
          .idata_i           (ul_di_i[ii]),
          .qdata_i           (ul_dq_i[ii]),
          .data_o            (ul_data_o[ii]),
          .sop_o             (ul_data_sop_o[ii]),
          .valid_o           (ul_data_valid_o[ii])
      );
    end
  endgenerate

endmodule

`default_nettype wire
