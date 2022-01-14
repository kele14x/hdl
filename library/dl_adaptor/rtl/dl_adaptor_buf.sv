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
    input var  [63:0] dl_data_i                       [LAYER_NUMBER_C],
    input var         dl_data_valid_i                 [LAYER_NUMBER_C],
    input var  [11:0] re_no_i                         [LAYER_NUMBER_C],
    // DL data output to DFE
    output var        dl_sof_o,
    output var        dl_sop_o,
    output var        dl_sof_ahead_9_o,
    output var        dl_sop_ahead_9_o,
    output var [15:0] dl_di_o                         [LAYER_NUMBER_C],
    output var [15:0] dl_dq_o                         [LAYER_NUMBER_C],
    output var        dl_valid_o,
    //
    // Control Interface
    //==================
    // Clock & reset
    input var         clk_axi,
    input var         rst_axi,
    //eq gain mem configuration interface
    input var  [10:0] dl_eq_gain_mem_addr,
    input var  [31:0] dl_eq_gain_mem_wdata,
    input var         dl_eq_gain_mem_we,
    output var [31:0] dl_eq_gain_mem_rdata,
    // TODO: not used
    input var         s0_rd_trig_i,
    input var         s0_rd_trig_en,
    // RAT and bandwidth configuration
    input var  [ 3:0] bw_mode_i,
    input var  [ 1:0] rat_mode_i,
    input var  [ 1:0] compression_mode                [LAYER_NUMBER_C],
    // Buffer access
    input var  [ 1:0] buffer_mem_ctrl_en,
    input var  [ 8:0] dfe_dl_adaptor_mem_symbol_no_sel,
    input var  [11:0] buffer_mem_addr_i               [LAYER_NUMBER_C],
    input var  [31:0] buffer_mem_data_i               [LAYER_NUMBER_C],
    input var         buffer_mem_we                   [LAYER_NUMBER_C],
    output var [31:0] buffer_mem_data_o               [LAYER_NUMBER_C]
);

  logic [14:0] buffer_rd_ctrl           [             4];
  logic [ 2:0] decomp_ctrl              [             4];
  logic [ 9:0] eq_gain;
  logic [ 1:0] buffer_mem_ctrl_en_s;
  logic        buffer_mem_ctrl_override;
  logic [ 8:0] symbol_no_s;

  logic [63:0] dl_data_s                [LAYER_NUMBER_C];
  logic        dl_data_valid_s          [LAYER_NUMBER_C];
  logic [11:0] re_no_s                  [LAYER_NUMBER_C];
  logic        dl_data_sop_s            [LAYER_NUMBER_C];
  logic        dl_data_sof_s;
  logic [31:0] buffer_data              [            16];


  generate
    for (genvar i = 0; i < LAYER_NUMBER_C; i++) begin
      always_ff @(posedge clk_491m_i) begin
        dl_data_s[i]       <= dl_data_i[i];
        dl_data_valid_s[i] <= dl_data_valid_i[i];
        re_no_s[i]         <= re_no_i[i];
        dl_data_sop_s[i]   <= dl_data_sop_i;
      end
    end
  endgenerate

  always_ff @(posedge clk_491m_i) begin
    dl_data_sof_s <= dl_data_sof_i;
  end


  dl_adaptor_ctrl inst_dl_adaptor_ctrl (
      .clka              (clk_axi),
      .clk               (clk_491m_i),
      .bw_sel_i          (bw_mode_i),
      .rat_mode_i        (rat_mode_i),
      .eq_bypass_i       (1'b0),
      .eq_gain_mem_addr  (dl_eq_gain_mem_addr),
      .eq_gain_mem_data_i(dl_eq_gain_mem_wdata),
      .eq_gain_mem_we    (dl_eq_gain_mem_we),
      .eq_gain_mem_data_o(dl_eq_gain_mem_rdata),
      //
      .s0_read_trig      (s0_rd_trig_i),
      .s0_read_trig_en   (s0_rd_trig_en),
      .sof0_i            (dl_data_sof_s),
      .sof_o             (dl_sof_o),
      .sop_o             (dl_sop_o),
      .sof_ahead_9_o     (dl_sof_ahead_9_o),
      .sop_ahead_9_o     (dl_sop_ahead_9_o),
      .valid_o           (dl_valid_o),
      .subframe_no_o     (  /* Not used */),
      .symbol_no_o       (symbol_no_s),
      .buffer_rd_ctrl0   (buffer_rd_ctrl[0]),
      .buffer_rd_ctrl1   (buffer_rd_ctrl[1]),
      .buffer_rd_ctrl2   (buffer_rd_ctrl[2]),
      .buffer_rd_ctrl3   (buffer_rd_ctrl[3]),
      //
      .decomp_ctrl_0     (decomp_ctrl[0]),
      .decomp_ctrl_1     (decomp_ctrl[1]),
      .decomp_ctrl_2     (decomp_ctrl[2]),
      .decomp_ctrl_3     (decomp_ctrl[3]),
      .eq_gain_o         (eq_gain)
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
          .buffer_rd_ctrl_i  (buffer_rd_ctrl[i/4]),
          .buffer_mem_addr_i (buffer_mem_addr_i[i]),
          .buffer_mem_ctrl_en(buffer_mem_ctrl_en_s),
          .buffer_mem_data_i (buffer_mem_data_i[i]),
          .buffer_mem_we     (buffer_mem_we[i]),
          .buffer_mem_data_o (buffer_mem_data_o[i]),
          .data_i            (dl_data_s[i]),
          .sof_i             (dl_data_sof_s),
          .sop_i             (dl_data_sop_s[i]),
          .valid_i           (dl_data_valid_s[i]),
          .re_no_i           (re_no_s[i]),
          .data_o            (buffer_data[i])
      );
    end
  endgenerate

  generate
    for (genvar i = 0; i < LAYER_NUMBER_C / 4; i++) begin

      dl_decompression inst_dl_decompression (
          .clk               (clk_491m_gating_dl_i),
          .compression_mode0 (compression_mode[4*i+0]),
          .compression_mode1 (compression_mode[4*i+1]),
          .compression_mode2 (compression_mode[4*i+2]),
          .compression_mode3 (compression_mode[4*i+3]),
          .compression_scale (16'h7fff),
          .decomp_ctrl_i     (decomp_ctrl[i]),
          .eq_gain_i         (eq_gain),
          .data0_i           (buffer_data[4*i+0]),
          .data1_i           (buffer_data[4*i+1]),
          .data2_i           (buffer_data[4*i+2]),
          .data3_i           (buffer_data[4*i+3]),
          .idata0_o          (dl_di_o[4*i+0]),
          .qdata0_o          (dl_dq_o[4*i+0]),
          .idata1_o          (dl_di_o[4*i+1]),
          .qdata1_o          (dl_dq_o[4*i+1]),
          .idata2_o          (dl_di_o[4*i+2]),
          .qdata2_o          (dl_dq_o[4*i+2]),
          .idata3_o          (dl_di_o[4*i+3]),
          .qdata3_o          (dl_dq_o[4*i+3])
      );
    end
  endgenerate


endmodule

`default_nettype wire
