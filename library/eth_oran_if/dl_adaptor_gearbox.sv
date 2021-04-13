// File: dl_adaptor_gearbox.sv
// Brief: Downlink PDxCH (DL U-Plane data) adaptor gearbox.
`timescale 1 ns / 1 ps `default_nettype none

module dl_adaptor_gearbox #(
    parameter int NUM_CC = 2
) (
    // Interface with XORIF
    //=====================
    input var         clk_400m,
    input var         rst_400m,
    //
    input var         defm_radio_start_10ms,
    input var         s_dl_update          [NUM_CC],
    // Shared by CCs
    input var  [63:0] s_defm_data_tdata,
    input var  [ 7:0] s_defm_data_tkeep,
    input var         s_defm_data_tvalid,
    input var         s_defm_data_tlast,
    output var        s_defm_data_tready,
    input var  [30:0] s_defm_data_tuser,
    // Interface with DFE
    //===================
    input var         clk_491m52,
    input var         rst_491m52,
    // Separated CCs
    output var        gb_sof               [NUM_CC],
    output var        gb_sos               [NUM_CC],
    output var [63:0] gb_data              [NUM_CC],
    output var        gb_valid             [NUM_CC],
    output var [11:0] gb_re                [NUM_CC],
    // Control Interface
    //==================
    input var  [ 1:0] ctrl_compression_mode
);


  logic        defm_radio_start_10ms_sync;

  logic [63:0] m_axis_tdata;
  logic [ 7:0] m_axis_tkeep;
  logic        m_axis_tvalid;
  logic        m_axis_tlast;
  logic [30:0] m_axis_tuser;
  logic        m_axis_tready;

  logic        m_axis_tready_raw;
  logic        m_axis_tready_bfp9;

  logic [ 1:0] compression_mode;

  logic [63:0] gb_data_raw                [NUM_CC];
  logic        gb_valid_raw               [NUM_CC];
  logic [11:0] gb_re_raw                  [NUM_CC];

  logic [63:0] gb_data_bfp9               [NUM_CC];
  logic        gb_valid_bfp9              [NUM_CC];
  logic [11:0] gb_re_bfp9                 [NUM_CC];


  dl_adaptor_fifo i_dl_adaptor_fifo (
      // Writer side
      .s_axis_aclk   (clk_400m),
      .s_axis_aresetn(rst_400m),
      //
      .s_axis_tdata  (s_defm_data_tdata),
      .s_axis_tkeep  (s_defm_data_tkeep),
      .s_axis_tvalid (s_defm_data_tvalid),
      .s_axis_tlast  (s_defm_data_tlast),
      .s_axis_tready (s_defm_data_tready),
      .s_axis_tuser  (s_defm_data_tuser),
      // Reader side
      .m_axis_aclk   (clk_491m52),
      //
      .m_axis_tdata  (m_axis_tdata),
      .m_axis_tkeep  (m_axis_tkeep),
      .m_axis_tvalid (m_axis_tvalid),
      .m_axis_tlast  (m_axis_tlast),
      .m_axis_tready (m_axis_tready),
      .m_axis_tuser  (m_axis_tuser)
  );

  always_ff @(posedge clk_491m52) begin
    compression_mode <= ctrl_compression_mode;
  end

  assign m_axis_tready = (compression_mode == 0) ? m_axis_tready_raw :
                         (compression_mode == 1) ? m_axis_tready_bfp9 :
                         1'b1;

  assign gb_data = (compression_mode == 0) ? gb_data_raw :
                   (compression_mode == 1) ? gb_data_bfp9 : '{NUM_CC{'0}};

  assign gb_valid = (compression_mode == 0) ? gb_valid_raw :
                    (compression_mode == 1) ? gb_valid_bfp9 : '{NUM_CC{'0}};

  assign gb_re = (compression_mode == 0) ? gb_re_raw :
                 (compression_mode == 1) ? gb_re_bfp9 : '{NUM_CC{'0}};

  xpm_cdc_pulse #(
      .DEST_SYNC_FF  (2),
      .INIT_SYNC_FF  (0),
      .REG_OUTPUT    (1),
      .RST_USED      (1),
      .SIM_ASSERT_CHK(0)
  ) i_xpm_cdc_pulse_defm_radio_start_10ms (
      .src_clk   (clk_400m),
      .src_rst   (rst_400m),
      .src_pulse (defm_radio_start_10ms),
      .dest_clk  (clk_491m52),
      .dest_rst  (rst_491m52),
      .dest_pulse(defm_radio_start_10ms_sync)
  );


  generate
    for (genvar i = 0; i < NUM_CC; i++) begin

      assign gb_sof[i] = defm_radio_start_10ms_sync;

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

  dl_adaptor_gearbox_raw #(
      .NUM_CC(NUM_CC)
  ) i_dl_adaptor_gearbox_raw (
      // Interface with DFE
      //===================
      .clk          (clk_491m52),
      .rst          (rst_491m52),
      //
      .s_axis_tdata (m_axis_tdata),
      .s_axis_tkeep (m_axis_tkeep),
      .s_axis_tvalid(m_axis_tvalid),
      .s_axis_tlast (m_axis_tlast),
      .s_axis_tready(m_axis_tready_raw),
      .s_axis_tuser (m_axis_tuser),
      // Shared by CC0 and CC1
      .gb_data      (gb_data_raw),
      .gb_valid     (gb_valid_raw),
      .gb_re        (gb_re_raw)
  );

  dl_adaptor_gearbox_bfp9 #(
      .NUM_CC(NUM_CC)
  ) i_dl_adaptor_gearbox_bfp9 (
      // Interface with DFE
      //===================
      .clk          (clk_491m52),
      .rst          (rst_491m52),
      //
      .s_axis_tdata (m_axis_tdata),
      .s_axis_tkeep (m_axis_tkeep),
      .s_axis_tvalid(m_axis_tvalid),
      .s_axis_tlast (m_axis_tlast),
      .s_axis_tready(m_axis_tready_bfp9),
      .s_axis_tuser (m_axis_tuser),
      // Shared by CC0 and CC1
      .gb_data      (gb_data_bfp9),
      .gb_valid     (gb_valid_bfp9),
      .gb_re        (gb_re_bfp9)
  );


endmodule

`default_nettype wire
