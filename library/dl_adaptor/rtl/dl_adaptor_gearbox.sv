// File: dl_adaptor_gearbox.sv
// Brief: Downlink PDxCH (DL U-Plane data) adaptor gearbox.
`timescale 1 ns / 1 ps `default_nettype none

module dl_adaptor_gearbox #(
    parameter int NUM_CC = 2,
    parameter int NUM_DL_LAYER = 16
) (
    // Interface with XORIF
    //=====================
    input var         clk_400m,
    input var         rst_400m,
    // Shared by CCs
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
    // Separated CCs
    output var [63:0] gb_data              [      NUM_CC][NUM_DL_LAYER],
    output var        gb_valid             [      NUM_CC][NUM_DL_LAYER],
    output var [11:0] gb_re                [      NUM_CC][NUM_DL_LAYER],
    // Control Interface
    //==================
    input var  [ 1:0] ctrl_compression_mode[      NUM_CC]
);


  logic [ 1:0] compression_mode;

  logic [63:0] m_axis_tdata      [NUM_DL_LAYER];
  logic [ 7:0] m_axis_tkeep      [NUM_DL_LAYER];
  logic        m_axis_tvalid     [NUM_DL_LAYER];
  logic        m_axis_tlast      [NUM_DL_LAYER];
  logic [30:0] m_axis_tuser      [NUM_DL_LAYER];
  logic        m_axis_tready     [NUM_DL_LAYER];

  logic        m_axis_tready_raw [NUM_DL_LAYER];
  logic        m_axis_tready_bfp9[NUM_DL_LAYER];

  logic [63:0] gb_data_raw       [NUM_DL_LAYER][      NUM_CC];
  logic        gb_valid_raw      [NUM_DL_LAYER][      NUM_CC];
  logic [11:0] gb_re_raw         [NUM_DL_LAYER][      NUM_CC];

  logic [63:0] gb_data_bfp9      [NUM_DL_LAYER][      NUM_CC];
  logic        gb_valid_bfp9     [NUM_DL_LAYER][      NUM_CC];
  logic [11:0] gb_re_bfp9        [NUM_DL_LAYER][      NUM_CC];

  always_ff @(posedge clk_491m52) begin
    compression_mode <= ctrl_compression_mode[0];
  end

  generate
    for (genvar i = 0; i < NUM_DL_LAYER; i++) begin: g_ly

      dl_adaptor_fifo i_dl_adaptor_fifo (
          // Writer side
          .s_axis_aclk   (clk_400m),
          .s_axis_aresetn(~rst_400m),
          //
          .s_axis_tdata  (s_defm_data_tdata[i]),
          .s_axis_tkeep  (s_defm_data_tkeep[i]),
          .s_axis_tvalid (s_defm_data_tvalid[i]),
          .s_axis_tlast  (s_defm_data_tlast[i]),
          .s_axis_tready (s_defm_data_tready[i]),
          .s_axis_tuser  (s_defm_data_tuser[i]),
          // Reader side
          .m_axis_aclk   (clk_491m52),
          //
          .m_axis_tdata  (m_axis_tdata[i]),
          .m_axis_tkeep  (m_axis_tkeep[i]),
          .m_axis_tvalid (m_axis_tvalid[i]),
          .m_axis_tlast  (m_axis_tlast[i]),
          .m_axis_tready (m_axis_tready[i]),
          .m_axis_tuser  (m_axis_tuser[i])
      );

      assign m_axis_tready[i] = (compression_mode == 0) ? m_axis_tready_raw[i] :
                              (compression_mode == 1) ? m_axis_tready_bfp9[i] :
                              1'b1;

      dl_adaptor_gearbox_raw #(
          .NUM_CC(NUM_CC)
      ) i_dl_adaptor_gearbox_raw (
          // Interface with DFE
          //===================
          .clk          (clk_491m52),
          .rst          (rst_491m52),
          //
          .s_axis_tdata (m_axis_tdata[i]),
          .s_axis_tkeep (m_axis_tkeep[i]),
          .s_axis_tvalid(m_axis_tvalid[i]),
          .s_axis_tlast (m_axis_tlast[i]),
          .s_axis_tready(m_axis_tready_raw[i]),
          .s_axis_tuser (m_axis_tuser[i]),
          // Shared by CC0 and CC1
          .gb_data      (gb_data_raw[i]),
          .gb_valid     (gb_valid_raw[i]),
          .gb_re        (gb_re_raw[i])
      );

      dl_adaptor_gearbox_bfp9 #(
          .NUM_CC(NUM_CC)
      ) i_dl_adaptor_gearbox_bfp9 (
          // Interface with DFE
          //===================
          .clk          (clk_491m52),
          .rst          (rst_491m52),
          //
          .s_axis_tdata (m_axis_tdata[i]),
          .s_axis_tkeep (m_axis_tkeep[i]),
          .s_axis_tvalid(m_axis_tvalid[i]),
          .s_axis_tlast (m_axis_tlast[i]),
          .s_axis_tready(m_axis_tready_bfp9[i]),
          .s_axis_tuser (m_axis_tuser[i]),
          // Shared by CC0 and CC1
          .gb_data      (gb_data_bfp9[i]),
          .gb_valid     (gb_valid_bfp9[i]),
          .gb_re        (gb_re_bfp9[i])
      );

    end
  endgenerate

  generate
    for (genvar i = 0; i < NUM_DL_LAYER; i++) begin

      for (genvar j = 0; j < NUM_CC; j++) begin
        assign gb_data[j][i] = (compression_mode == 0) ? gb_data_raw[i][j] :
                        (compression_mode == 1) ? gb_data_bfp9[i][j] : {'0};

        assign gb_valid[j][i] = (compression_mode == 0) ? gb_valid_raw[i][j] :
                            (compression_mode == 1) ? gb_valid_bfp9[i][j] : {'0};

        assign gb_re[j][i] = (compression_mode == 0) ? gb_re_raw[i][j] :
                        (compression_mode == 1) ? gb_re_bfp9[i][j] : {'0};
      end

    end
  endgenerate

endmodule

`default_nettype wire
