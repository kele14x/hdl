// File: dl_adaptor_gearbox.sv
// Brief: Downlink PDxCH (DL U-Plane data) adaptor gearbox. It is designed to
//        read incoming Ethernet like stream (which from XORIF DL data) and put
//        them into a more convenient interface. The gearbox module is designed
//        to handle two format: raw and BFP9. Note due to the gearbox is shared
//        between 2 CCs, 2 CCs need to be in same compression format. This is
//        a limitation of this module.
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


  logic [63:0] m_axis_tdata      [NUM_DL_LAYER];
  logic [ 7:0] m_axis_tkeep      [NUM_DL_LAYER];
  logic        m_axis_tvalid     [NUM_DL_LAYER];
  logic        m_axis_tlast      [NUM_DL_LAYER];
  logic [30:0] m_axis_tuser      [NUM_DL_LAYER];
  logic        m_axis_tready     [NUM_DL_LAYER];

  logic        m_axis_tready_raw [NUM_DL_LAYER];
  logic        m_axis_tready_bfp9[NUM_DL_LAYER];

  logic [63:0] gb_data_raw       [NUM_DL_LAYER] [NUM_CC];
  logic        gb_valid_raw      [NUM_DL_LAYER] [NUM_CC];
  logic [11:0] gb_re_raw         [NUM_DL_LAYER] [NUM_CC];

  logic [63:0] gb_data_bfp9      [NUM_DL_LAYER] [NUM_CC];
  logic        gb_valid_bfp9     [NUM_DL_LAYER] [NUM_CC];
  logic [11:0] gb_re_bfp9        [NUM_DL_LAYER] [NUM_CC];


  generate
    for (genvar i = 0; i < NUM_DL_LAYER; i++) begin : g_ly

      // DL packets are firstly feed into a FIFO. This is FIFO is used to do the
      // backward press across two time domain. It's a little bit complex, so
      // use Xilinx's IP core and hope it can do well.
      //
      // Note tkeep and tuser is not need to be feed into FIFO since they are
      // stable during the packet. But we still do this.
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

      assign m_axis_tready[i] = (ctrl_compression_mode[0] == 0) ? m_axis_tready_raw[i] :
                              (ctrl_compression_mode[0] == 1) ? m_axis_tready_bfp9[i] :
                              1'b1;

      // We have two modules to handle different compression format. To save
      // resource, remove raw module.

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

        always_ff @(posedge clk_400m) begin
          gb_data[j][i] <= (ctrl_compression_mode[0] == 0) ? gb_data_raw[i][j] :
                          (ctrl_compression_mode[0] == 1) ? gb_data_bfp9[i][j] : {
            '0
          };

          gb_valid[j][i] <= (ctrl_compression_mode[0] == 0) ? gb_valid_raw[i][j] :
                              (ctrl_compression_mode[0] == 1) ? gb_valid_bfp9[i][j] : {
            '0
          };

          gb_re[j][i] <= (ctrl_compression_mode[0] == 0) ? gb_re_raw[i][j] :
                          (ctrl_compression_mode[0] == 1) ? gb_re_bfp9[i][j] : {
            '0
          };
        end

      end

    end
  endgenerate

  // synthesis translate_off

  int fifo_wr_cnt, fifo_rd_cnt;

  always_ff @(posedge clk_400m) begin
    if (rst_400m) begin
      fifo_wr_cnt = 0;
    end else begin
      if (s_defm_data_tready[0] && s_defm_data_tvalid[0]) begin
        fifo_wr_cnt++;
        if (s_defm_data_tlast[0]) begin
          $display("%m: write %d words to FIFO", fifo_wr_cnt);
          fifo_wr_cnt = 0;
        end
      end
    end
  end

  always_ff @(posedge clk_491m52) begin
    if (rst_491m52) begin
      fifo_rd_cnt = 0;
    end else begin
      if (m_axis_tvalid[0] && m_axis_tready[0]) begin
        fifo_rd_cnt++;
        if (m_axis_tlast[0]) begin
          $display("%m: read %d words from FIFO", fifo_rd_cnt);
          fifo_rd_cnt = 0;
        end
      end
    end
  end

  // synthesis translate_on

endmodule

`default_nettype wire
