`timescale 1 ns / 1 ps
//
`default_nettype none

module puxch #(
    parameter int NUM_CC     = 3,
    parameter int NUM_ANT    = 4,
    parameter int HAS_BFP    = 1,
    parameter int HALF_BLOCK = 1
) (
    input var         s_axi_aclk,
    input var         s_axi_aresetn,
    //
    input var  [11:0] s_axi_awaddr,
    input var  [ 2:0] s_axi_awprot,
    input var         s_axi_awvalid,
    output var        s_axi_awready,
    //
    input var  [31:0] s_axi_wdata,
    input var  [ 3:0] s_axi_wstrb,
    input var         s_axi_wvalid,
    output var        s_axi_wready,
    //
    output var [ 1:0] s_axi_bresp,
    output var        s_axi_bvalid,
    input var         s_axi_bready,
    //
    input var  [11:0] s_axi_araddr,
    input var  [ 2:0] s_axi_arprot,
    input var         s_axi_arvalid,
    output var        s_axi_arready,
    //
    output var [31:0] s_axi_rdata,
    output var [ 1:0] s_axi_rresp,
    output var        s_axi_rvalid,
    input var         s_axi_rready,
    // Clock & Reset
    //--------------
    input var         clk,
    input var         rst,
    //
    input var  [31:0] s_axis_tdata         [ NUM_CC][NUM_ANT],
    input var  [ 7:0] s_axis_tuser         [ NUM_CC][NUM_ANT],
    input var         s_axis_tlast         [ NUM_CC][NUM_ANT],
    input var         s_axis_tvalid        [ NUM_CC][NUM_ANT],
    output var        s_axis_tready        [ NUM_CC][NUM_ANT],
    // O-RAN U-Plane
    //--------------
    input var         clk_eth_xran,
    input var         rst_eth_xran,
    //
    input var         sync_in,
    //
    output var        fram_radio_start_10ms[ NUM_CC],
    //
    output var [63:0] m_fram_data_tdata    [NUM_ANT],
    output var [ 7:0] m_fram_data_tkeep    [NUM_ANT],
    output var        m_fram_data_tvalid   [NUM_ANT],
    output var        m_fram_data_tlast    [NUM_ANT],
    input var         m_fram_data_tready   [NUM_ANT],
    input var  [32:0] m_fram_data_req      [NUM_ANT]
);

  logic [ 3:0] ctrl_ud_comp_meth;
  logic [ 3:0] ctrl_ud_iq_width;
  logic [ 3:0] ctrl_fs_offset;
  //
  logic [ 3:0] ctrl_en               [NUM_CC];
  //
  logic [ 1:0] ctrl_rat              [NUM_CC];
  //
  logic [ 3:0] ctrl_bist             [NUM_CC];
  //
  logic [ 3:0] ctrl_bw               [NUM_CC];
  logic [ 8:0] ctrl_nprb             [NUM_CC];
  //
  logic [22:0] ctrl_rfs_offset       [NUM_CC];
  //
  logic [16:0] ctrl_gain             [NUM_CC] [NUM_ANT];
  //
  logic [ 5:0] ctrl_phase_comp_addr;
  logic        ctrl_phase_comp_en;
  logic        ctrl_phase_comp_we;
  logic [31:0] ctrl_phase_comp_din;
  logic [31:0] ctrl_phase_comp_dout;
  logic        ctrl_phase_comp_valid;
  logic [11:0] s_ul_sym_num          [NUM_CC];

  puxch_regs i_regs (
      .s_axi_aclk             (s_axi_aclk),
      .s_axi_aresetn          (s_axi_aresetn),
      //
      .s_axi_awaddr           (s_axi_awaddr),
      .s_axi_awprot           (s_axi_awprot),
      .s_axi_awvalid          (s_axi_awvalid),
      .s_axi_awready          (s_axi_awready),
      //
      .s_axi_wdata            (s_axi_wdata),
      .s_axi_wstrb            (s_axi_wstrb),
      .s_axi_wvalid           (s_axi_wvalid),
      .s_axi_wready           (s_axi_wready),
      //
      .s_axi_bresp            (s_axi_bresp),
      .s_axi_bvalid           (s_axi_bvalid),
      .s_axi_bready           (s_axi_bready),
      //
      .s_axi_araddr           (s_axi_araddr),
      .s_axi_arprot           (s_axi_arprot),
      .s_axi_arvalid          (s_axi_arvalid),
      .s_axi_arready          (s_axi_arready),
      //
      .s_axi_rdata            (s_axi_rdata),
      .s_axi_rresp            (s_axi_rresp),
      .s_axi_rvalid           (s_axi_rvalid),
      .s_axi_rready           (s_axi_rready),
      // ul_en.cc0,
      .ul_en_cc0_out          (ctrl_en[0]),
      // ul_en.cc1,
      .ul_en_cc1_out          (ctrl_en[1]),
      // ul_en.cc2,
      .ul_en_cc2_out          (ctrl_en[2]),
      // ul_rat.cc0,
      .ul_rat_cc0_out         (ctrl_rat[0]),
      // ul_rat.cc1,
      .ul_rat_cc1_out         (ctrl_rat[1]),
      // ul_rat.cc2,
      .ul_rat_cc2_out         (ctrl_rat[2]),
      // ul_bist.bist_cc0,
      .ul_bist_bist_cc0_out   (ctrl_bist[0]),
      // ul_bist.bist_cc1,
      .ul_bist_bist_cc1_out   (ctrl_bist[1]),
      // ul_bist.bist_cc2,
      .ul_bist_bist_cc2_out   (ctrl_bist[2]),
      // ul_bw.cc0,
      .ul_bw_cc0_out          (ctrl_bw[0]),
      // ul_bw.cc1,
      .ul_bw_cc1_out          (ctrl_bw[1]),
      // ul_bw.cc2,
      .ul_bw_cc2_out          (ctrl_bw[2]),
      // ul_nprb_0.val,
      .ul_nprb_0_val_out      (ctrl_nprb[0]),
      // ul_nprb_1.val,
      .ul_nprb_1_val_out      (ctrl_nprb[1]),
      // ul_nprb_2.val,
      .ul_nprb_2_val_out      (ctrl_nprb[2]),
      // ul_rfs_offset_0.val,
      .ul_rfs_offset_0_val_out(ctrl_rfs_offset[0]),
      // ul_rfs_offset_1.val,
      .ul_rfs_offset_1_val_out(ctrl_rfs_offset[1]),
      // ul_rfs_offset_2.val,
      .ul_rfs_offset_2_val_out(ctrl_rfs_offset[2]),
      // ul_ud.comp_meth,
      .ul_ud_comp_meth_out    (ctrl_ud_comp_meth),
      // ul_ud.iq_width,
      .ul_ud_iq_width_out     (ctrl_ud_iq_width),
      // ul_ud.fs_offset,
      .ul_ud_fs_offset_out    (ctrl_fs_offset),
      // ul_gain_0_0.val,
      .ul_gain_0_0_val_out    (ctrl_gain[0][0]),
      // ul_gain_0_1.val,
      .ul_gain_0_1_val_out    (ctrl_gain[0][1]),
      // ul_gain_0_2.val,
      .ul_gain_0_2_val_out    (ctrl_gain[0][2]),
      // ul_gain_0_3.val,
      .ul_gain_0_3_val_out    (ctrl_gain[0][3]),
      // ul_gain_1_0.val,
      .ul_gain_1_0_val_out    (ctrl_gain[1][0]),
      // ul_gain_1_1.val,
      .ul_gain_1_1_val_out    (ctrl_gain[1][1]),
      // ul_gain_1_2.val,
      .ul_gain_1_2_val_out    (ctrl_gain[1][2]),
      // ul_gain_1_3.val,
      .ul_gain_1_3_val_out    (ctrl_gain[1][3]),
      // ul_gain_2_0.val,
      .ul_gain_2_0_val_out    (ctrl_gain[2][0]),
      // ul_gain_2_1.val,
      .ul_gain_2_1_val_out    (ctrl_gain[2][1]),
      // ul_gain_2_2.val,
      .ul_gain_2_2_val_out    (ctrl_gain[2][2]),
      // ul_gain_2_3.val,
      .ul_gain_2_3_val_out    (ctrl_gain[2][3]),
      // ul_phase_comp,
      .ul_phase_comp_addr     (ctrl_phase_comp_addr),
      .ul_phase_comp_en       (ctrl_phase_comp_en),
      .ul_phase_comp_we       (ctrl_phase_comp_we),
      .ul_phase_comp_din      (ctrl_phase_comp_din),
      .ul_phase_comp_dout     (ctrl_phase_comp_dout),
      .ul_phase_comp_valid    (ctrl_phase_comp_valid)
  );

  puxch_top #(
      .NUM_CC    (NUM_CC),
      .NUM_ANT   (NUM_ANT),
      .HAS_BFP   (HAS_BFP),
      .HALF_BLOCK(HALF_BLOCK)
  ) i_puxch (
      .clk                  (clk),
      .rst                  (rst),
      //
      .s_axis_tdata         (s_axis_tdata),
      .s_axis_tuser         (s_axis_tuser),
      .s_axis_tlast         (s_axis_tlast),
      .s_axis_tvalid        (s_axis_tvalid),
      .s_axis_tready        (s_axis_tready),
      // ORAN
      .clk_eth_xran         (clk_eth_xran),
      .rst_eth_xran         (rst_eth_xran),
      //
      .sync_in              (sync_in),
      //
      .fram_radio_start_10ms(fram_radio_start_10ms),
      //
      .m_fram_data_tdata    (m_fram_data_tdata),
      .m_fram_data_tkeep    (m_fram_data_tkeep),
      .m_fram_data_tvalid   (m_fram_data_tvalid),
      .m_fram_data_tlast    (m_fram_data_tlast),
      .m_fram_data_tready   (m_fram_data_tready),
      .m_fram_data_req      (m_fram_data_req),
      .s_ul_sym_num         (s_ul_sym_num),
      // CSR
      .ctrl_clk             (s_axi_aclk),
      .ctrl_rst             (~s_axi_aresetn),
      //
      .ctrl_ud_comp_meth    (ctrl_ud_comp_meth),
      .ctrl_ud_iq_width     (ctrl_ud_iq_width),
      .ctrl_fs_offset       (ctrl_fs_offset),
      //
      .ctrl_en              (ctrl_en),
      .ctrl_rat             (ctrl_rat),
      .ctrl_bist            (ctrl_bist),
      .ctrl_bw              (ctrl_bw),
      .ctrl_nprb            (ctrl_nprb),
      .ctrl_rfs_offset      (ctrl_rfs_offset),
      //
      .ctrl_gain            (ctrl_gain),
      //
      .ctrl_phase_comp_addr (ctrl_phase_comp_addr),
      .ctrl_phase_comp_en   (ctrl_phase_comp_en),
      .ctrl_phase_comp_we   (ctrl_phase_comp_we),
      .ctrl_phase_comp_din  (ctrl_phase_comp_din),
      .ctrl_phase_comp_dout (ctrl_phase_comp_dout),
      .ctrl_phase_comp_valid(ctrl_phase_comp_valid)
  );

  assign s_ul_sym_num = '{NUM_CC{'0}};

endmodule

`default_nettype wire
