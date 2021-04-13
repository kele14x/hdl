// File: dl_adaptor.sv
// Brief: Downlink PDxCH (DL U-Plane data) adaptor. Input is 4 branch (4 dl
//        layer) stream from XORIF ip core, each stream contains all CCs' data.
//        However, output has different share structure. Each stream contains 4
//        layer interleaved data. Also each CC has separated port, resulting
//        8 streams for 4 branches/layers and 2 CCs.
`timescale 1 ns / 1 ps `default_nettype none

module dl_adaptor #(
    parameter int NUM_CC = 2,
    parameter int NUM_DL_LAYER = 16
) (
    // Interface with XORIF
    //=====================
    input var         clk_400m,
    input var         rst_400m,
    // Timing ports
    input var         defm_radio_start_10ms,
    input var         s_dl_update          [      NUM_CC],
    // 4 branch/layer stream, CC shared
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
    // DL symbol timing
    input var         dl_radio_start_10ms,
    input var         dl_sym_update        [      NUM_CC],
    input var         dl_sym_num           [      NUM_CC],
    // 2 CC port, each will have interleaved 4 layer data
    output var        dl_sof               [NUM_DL_LAYER][NUM_CC],
    output var        dl_sos               [NUM_DL_LAYER][NUM_CC],
    output var [31:0] dl_data              [NUM_DL_LAYER][NUM_CC],
    output var        dl_valid             [NUM_DL_LAYER][NUM_CC],
    output var [11:0] dl_num               [NUM_DL_LAYER][NUM_CC],
    // Control Interface
    input var  [ 1:0] ctrl_numerology      [      NUM_CC],
    input var  [ 1:0] ctrl_compression_mode[      NUM_CC]
);


  logic [63:0] gb_data [NUM_DL_LAYER][NUM_CC];
  logic        gb_valid[NUM_DL_LAYER][NUM_CC];
  logic        gb_sof  [NUM_DL_LAYER][NUM_CC];
  logic        gb_sos  [NUM_DL_LAYER][NUM_CC];
  logic [11:0] gb_re   [NUM_DL_LAYER][NUM_CC];

  logic [63:0] wr_data [NUM_DL_LAYER][NUM_CC];
  logic [11:0] wr_addr [NUM_DL_LAYER][NUM_CC];
  logic        wr_en   [NUM_DL_LAYER][NUM_CC];

  logic [63:0] rd_data [NUM_DL_LAYER][NUM_CC];
  logic [11:0] rd_addr [NUM_DL_LAYER][NUM_CC];
  logic        rd_en   [NUM_DL_LAYER][NUM_CC];

  generate
    for (genvar i = 0; i < NUM_DL_LAYER; i++) begin : g_ly

      dl_adaptor_gearbox i_dl_adaptor_gearbox (
          // Interface with XORIF
          //=====================
          .clk_400m             (clk_400m),
          .rst_400m             (rst_400m),
          //
          .defm_radio_start_10ms(defm_radio_start_10ms),
          .s_dl_update          (s_dl_update),
          //
          .s_defm_data_tdata    (s_defm_data_tdata[i]),
          .s_defm_data_tkeep    (s_defm_data_tkeep[i]),
          .s_defm_data_tvalid   (s_defm_data_tvalid[i]),
          .s_defm_data_tlast    (s_defm_data_tlast[i]),
          .s_defm_data_tready   (s_defm_data_tready[i]),
          .s_defm_data_tuser    (s_defm_data_tuser[i]),
          // Interface with DFE
          //===================
          .clk_491m52           (clk_491m52),
          .rst_491m52           (rst_491m52),
          // Shared by CC0 and CC1
          .gb_data              (gb_data[i]),  // {Q, I}
          .gb_valid             (gb_valid[i]),
          .gb_sof               (gb_sof[i]),  // Start of a radio frame
          .gb_sos               (gb_sos[i]),  // start of a symbol
          .gb_re                (gb_re[i]),  // RE number, 0 ~ 3275
          // Control Interface
          //==================
          .ctrl_compression_mode(ctrl_compression_mode)
      );

      for (genvar j = 0; j < NUM_CC; j++) begin : g_cc

        dl_adaptor_writer i_dl_adaptor_writer (
            // Interface with DFE
            //===================
            .clk     (clk_491m52),
            .rst     (rst_491m52),
            // Separated CCs
            .gb_sof  (gb_sof[i][j]),
            .gb_sos  (gb_sos[i][j]),
            .gb_data (gb_data[i][j]),
            .gb_valid(gb_valid[i][j]),
            .gb_re   (gb_re[i][j]),  // 0 ~
            //
            .wr_data (wr_data[i][j]),
            .wr_addr (wr_addr[i][j]),
            .wr_en   (wr_en[i][j])
        );

        dl_adaptor_buffer i_dl_adaptor_buffer (
            // Interface with DFE
            //===================
            .clk    (clk_491m52),
            .rst    (rst_491m52),
            // Separated CCs
            .wr_addr(wr_addr[i][j]),
            .wr_en  (wr_en[i][j]),
            .wr_data(wr_data[i][j]),
            //
            .rd_addr(rd_addr[i][j]),
            .rd_en  (rd_en[i][j]),
            .rd_data(rd_data[i][j])
        );

      end
    end
  endgenerate


  generate
    for (genvar j = 0; j < NUM_CC; j++) begin : g_rd

      dl_adaptor_reader i_dl_adaptor_reader (
          .clk                (clk_491m52),
          .rst                (rst_491m52),
          //
          .dl_radio_start_10ms(dl_radio_start_10ms),
          .dl_sym_update      (dl_sym_update[j]),
          // Read
          .rd_addr            ('{rd_addr[0][j], rd_addr[1][j], rd_addr[2][j], rd_addr[3][j]}),
          .rd_en              ('{rd_en[0][j], rd_en[1][j], rd_en[2][j], rd_en[3][j]}),
          .rd_data            ('{rd_data[0][j], rd_data[1][j], rd_data[2][j], rd_data[3][j]}),
          //
          .dl_sof             (dl_sof[j]),
          .dl_sos             (dl_sos[j]),
          .dl_data            (dl_data[j]),
          .dl_valid           (dl_valid[j]),
          .dl_num             (dl_num[j])
      );

    end
  endgenerate

endmodule

`default_nettype wire
