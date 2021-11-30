`timescale 1 ns / 1 ps `default_nettype none
module dl_adaptor_buf #(
    parameter int LAYER_NUMBER_C = 16
) (

    // Radio Interface
    //================
    // Clock & reset
    input var         clk_491m_i,
    input var         rst_491m_i,
    input var         clk_491m_gating_dl_i,
    input var         clk_491m_gating_dl_flush_i,
    // DL timing
    input var         dl_data_sof_i,
    input var         dl_data_sop_i,
    // DL data from Gearbox
    input var  [63:0] dl_data_i                 [LAYER_NUMBER_C],
    input var         dl_data_valid_i           [LAYER_NUMBER_C],
    input var  [11:0] re_no_i                   [LAYER_NUMBER_C],
    // DL data output to DFE
    output var        dl_sof_o,
    output var        dl_sop_o,
    output var        dl_sof_ahead_9_o,
    output var        dl_sop_ahead_9_o,
    output var [15:0] dl_di_o                   [LAYER_NUMBER_C],
    output var [15:0] dl_dq_o                   [LAYER_NUMBER_C],
    output var        dl_valid_o,
    //
    // Control Interface
    //==================
    // Clock & reset
    input var         clk_axi,
    input var         rst_axi,
    // TODO: not used
    input var         s0_rd_trig_i,
    input var         s0_rd_trig_en,
    // RAT and bandwidth configuration
    input var  [ 3:0] bw_mode_i,
    input var  [ 1:0] rat_mode_i,
    input var  [ 1:0] compression_mode,
    // Buffer access
    input var  [ 1:0] buffer_mem_ctrl_en,
    input var  [ 8:0] dfe_dl_adaptor_mem_symbol_no_sel,
    input var  [11:0] buffer_mem_addr_i         [LAYER_NUMBER_C],
    input var  [31:0] buffer_mem_data_i         [LAYER_NUMBER_C],
    input var         buffer_mem_we             [LAYER_NUMBER_C],
    output var [31:0] buffer_mem_data_o         [LAYER_NUMBER_C]
);

  logic [14:0] buffer_rd_ctrl[16];
  logic [ 1:0] buffer_mem_ctrl_en_s;
  logic        buffer_mem_ctrl_override;
  logic [ 8:0] symbol_no_s;

  dl_adaptor_ctrl inst_dl_adaptor_ctrl (
      .clk             (clk_491m_i),
      .bw_sel_i        (bw_mode_i),
      .rat_mode_i      (rat_mode_i),
      .s0_read_trig    (s0_rd_trig_i),
      .s0_read_trig_en (s0_rd_trig_en),
      .sof0_i          (dl_data_sof_i),
      .sof_o           (dl_sof_o),
      .sop_o           (dl_sop_o),
      .sof_ahead_9_o   (dl_sof_ahead_9_o),
      .sop_ahead_9_o   (dl_sop_ahead_9_o),
      .valid_o         (dl_valid_o),
      .subframe_no_o   (  /* Not used */),
      .symbol_no_o     (symbol_no_s),
      .buffer_rd_ctrl0 (buffer_rd_ctrl[0]),
      .buffer_rd_ctrl1 (buffer_rd_ctrl[1]),
      .buffer_rd_ctrl2 (buffer_rd_ctrl[2]),
      .buffer_rd_ctrl3 (buffer_rd_ctrl[3]),
      .buffer_rd_ctrl4 (buffer_rd_ctrl[4]),
      .buffer_rd_ctrl5 (buffer_rd_ctrl[5]),
      .buffer_rd_ctrl6 (buffer_rd_ctrl[6]),
      .buffer_rd_ctrl7 (buffer_rd_ctrl[7]),
      .buffer_rd_ctrl8 (buffer_rd_ctrl[8]),
      .buffer_rd_ctrl9 (buffer_rd_ctrl[9]),
      .buffer_rd_ctrl10(buffer_rd_ctrl[10]),
      .buffer_rd_ctrl11(buffer_rd_ctrl[11]),
      .buffer_rd_ctrl12(buffer_rd_ctrl[12]),
      .buffer_rd_ctrl13(buffer_rd_ctrl[13]),
      .buffer_rd_ctrl14(buffer_rd_ctrl[14]),
      .buffer_rd_ctrl15(buffer_rd_ctrl[15])
  );

  always_ff @(posedge clk_491m_i) begin
    if (symbol_no_s == dfe_dl_adaptor_mem_symbol_no_sel && buffer_mem_ctrl_en[1] == 1'b1) begin
      buffer_mem_ctrl_override <= 1'b1;
    end else if (buffer_mem_ctrl_en[1] == 1'b0) begin
      buffer_mem_ctrl_override <= 1'b0;
    end else begin
      buffer_mem_ctrl_override <= buffer_mem_ctrl_override;
    end
  end

  assign buffer_mem_ctrl_en_s = {buffer_mem_ctrl_override, buffer_mem_ctrl_en[0]};
  
  generate
    for (genvar i = 0; i < LAYER_NUMBER_C; i++) begin

      dl_adaptor_data inst_dl_adaptor_data (
          .clk               (clk_491m_gating_dl_i),
          .compression_mode  (compression_mode),
          .buffer_rd_ctrl_i  (buffer_rd_ctrl[i]),
          .buffer_mem_addr_i (buffer_mem_addr_i[i]),
          .buffer_mem_ctrl_en(buffer_mem_ctrl_en_s),
          .buffer_mem_data_i (buffer_mem_data_i[i]),
          .buffer_mem_we     (buffer_mem_we[i]),
          .buffer_mem_data_o (buffer_mem_data_o[i]),
          .data_i            (dl_data_i[i]),
          .sof_i             (dl_data_sof_i),
          .sop_i             (dl_data_sop_i),
          .valid_i           (dl_data_valid_i[i]),
          .re_no_i           (re_no_i[i]),
          .idata_o           (dl_di_o[i]),
          .qdata_o           (dl_dq_o[i])
      );
    end
  endgenerate

endmodule

`default_nettype wire
