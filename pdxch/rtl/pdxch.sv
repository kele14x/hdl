`timescale 1 ns / 1 ps
//
`default_nettype none

module pdxch #(
    parameter int NUM_CC     = 3,
    parameter int NUM_ANT    = 4,
    parameter bit HALF_BLOCK = 1'b1,
    parameter bit HALF_FFT   = 1'b1
) (
    input  wire        s_axi_aclk,
    input  wire        s_axi_aresetn,
    //
    input  wire [ 8:0] s_axi_awaddr,
    input  wire [ 2:0] s_axi_awprot,
    input  wire        s_axi_awvalid,
    output wire        s_axi_awready,
    //
    input  wire [31:0] s_axi_wdata,
    input  wire [ 3:0] s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output wire        s_axi_wready,
    //
    output wire [ 1:0] s_axi_bresp,
    output wire        s_axi_bvalid,
    input  wire        s_axi_bready,
    //
    input  wire [ 8:0] s_axi_araddr,
    input  wire [ 2:0] s_axi_arprot,
    input  wire        s_axi_arvalid,
    output wire        s_axi_arready,
    //
    output wire [31:0] s_axi_rdata,
    output wire [ 1:0] s_axi_rresp,
    output wire        s_axi_rvalid,
    input  wire        s_axi_rready,
    // Radio I/F
    //----------
    input  wire        clk,
    input  wire        rst,
    //
    output wire [31:0] m_axis_tdata         [ NUM_CC][NUM_ANT],
    output wire [ 7:0] m_axis_tuser         [ NUM_CC][NUM_ANT],
    output wire        m_axis_tlast         [ NUM_CC][NUM_ANT],
    output wire        m_axis_tvalid        [ NUM_CC][NUM_ANT],
    input  wire        m_axis_tready        [ NUM_CC][NUM_ANT],
    // O-RAN
    //------
    input  wire        clk_eth_xran,
    input  wire        rst_eth_xran,
    //
    input  wire        sync_in,
    //
    output wire        defm_radio_start_10ms[ NUM_CC],
    input  wire [11:0] s_dl_sym_num         [ NUM_CC],
    // U-Plane
    input  wire [63:0] s_defm_data_tdata    [NUM_ANT],
    input  wire [ 7:0] s_defm_data_tkeep    [NUM_ANT],
    input  wire        s_defm_data_tvalid   [NUM_ANT],
    input  wire        s_defm_data_tlast    [NUM_ANT],
    output wire        s_defm_data_tready   [NUM_ANT],
    input  wire [90:0] s_defm_data_tuser    [NUM_ANT],
    input  wire [ 4:0] s_defm_data_tdest    [NUM_ANT]
);

  // Signals

  logic [ 3:0] ctrl_ud_comp_meth;
  logic [ 3:0] ctrl_ud_iq_width;
  logic [ 3:0] ctrl_fs_offset;
  //
  logic [ 3:0] ctrl_en               [NUM_CC];
  //
  logic [ 1:0] ctrl_rat              [NUM_CC];
  logic [ 3:0] ctrl_rat_regs         [NUM_CC];
  //
  logic [ 3:0] ctrl_bist             [NUM_CC];
  //
  logic [ 3:0] ctrl_bw               [NUM_CC];
  logic [ 8:0] ctrl_nprb             [NUM_CC];
  //
  logic [22:0] ctrl_rfs_offset       [NUM_CC];
  //
  logic [16:0] ctrl_gain             [NUM_CC] [NUM_ANT];

  logic [ 5:0] ctrl_phase_comp_addr;
  logic        ctrl_phase_comp_en;
  logic        ctrl_phase_comp_we;
  logic [31:0] ctrl_phase_comp_din;
  logic [31:0] ctrl_phase_comp_dout;
  logic        ctrl_phase_comp_valid;

  // Main

  /* verilator lint_off SELRANGE */
  // pdxch_regs is fixed 3CC x 4ANT; gain array is NUM_ANT-parameterized,
  // so NUM_ANT<4 instantiations index out of range (benign: ant>=NUM_ANT unused).
  pdxch_regs i_regs (
      .s_axi_aclk             (s_axi_aclk),
      .s_axi_aresetn          (s_axi_aresetn),
      //
      .s_axi_awaddr           ({3'b000, s_axi_awaddr}),
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
      .s_axi_araddr           ({3'b000, s_axi_araddr}),
      .s_axi_arprot           (s_axi_arprot),
      .s_axi_arvalid          (s_axi_arvalid),
      .s_axi_arready          (s_axi_arready),
      //
      .s_axi_rdata            (s_axi_rdata),
      .s_axi_rresp            (s_axi_rresp),
      .s_axi_rvalid           (s_axi_rvalid),
      .s_axi_rready           (s_axi_rready),
      // dl_en.cc0,
      .dl_en_cc0_out          (ctrl_en[0]),
      // dl_en.cc1,
      .dl_en_cc1_out          (ctrl_en[1]),
      // dl_en.cc2,
      .dl_en_cc2_out          (ctrl_en[2]),
      // dl_rat.cc0,
      .dl_rat_cc0_out         (ctrl_rat_regs[0]),
      // dl_rat.cc1,
      .dl_rat_cc1_out         (ctrl_rat_regs[1]),
      // dl_rat.cc2,
      .dl_rat_cc2_out         (ctrl_rat_regs[2]),
      // dl_bist.cc0,
      .dl_bist_cc0_out        (ctrl_bist[0]),
      // dl_bist.cc1,
      .dl_bist_cc1_out        (ctrl_bist[1]),
      // dl_bist.cc2,
      .dl_bist_cc2_out        (ctrl_bist[2]),
      // dl_bw.cc0,
      .dl_bw_cc0_out          (ctrl_bw[0]),
      // dl_bw.cc1,
      .dl_bw_cc1_out          (ctrl_bw[1]),
      // dl_bw.cc2,
      .dl_bw_cc2_out          (ctrl_bw[2]),
      // dl_nprb_0.val,
      .dl_nprb_0_val_out      (ctrl_nprb[0]),
      // dl_nprb_1.val,
      .dl_nprb_1_val_out      (ctrl_nprb[1]),
      // dl_nprb_2.val,
      .dl_nprb_2_val_out      (ctrl_nprb[2]),
      // dl_rfs_offset_0.val,
      .dl_rfs_offset_0_val_out(ctrl_rfs_offset[0]),
      // dl_rfs_offset_1.val,
      .dl_rfs_offset_1_val_out(ctrl_rfs_offset[1]),
      // dl_rfs_offset_2.val,
      .dl_rfs_offset_2_val_out(ctrl_rfs_offset[2]),
      // dl_ud.comp_meth,
      .dl_ud_comp_meth_out    (ctrl_ud_comp_meth),
      // dl_ud.iq_width,
      .dl_ud_iq_width_out     (ctrl_ud_iq_width),
      // dl_ud.fs_offset,
      .dl_ud_fs_offset_out    (ctrl_fs_offset),
      // dl_gain_0_0.val,
      .dl_gain_0_0_val_out    (ctrl_gain[0][0]),
      // dl_gain_0_1.val,
      .dl_gain_0_1_val_out    (ctrl_gain[0][1]),
      // dl_gain_0_2.val,
      .dl_gain_0_2_val_out    (ctrl_gain[0][2]),
      // dl_gain_0_3.val,
      .dl_gain_0_3_val_out    (ctrl_gain[0][3]),
      // dl_gain_1_0.val,
      .dl_gain_1_0_val_out    (ctrl_gain[1][0]),
      // dl_gain_1_1.val,
      .dl_gain_1_1_val_out    (ctrl_gain[1][1]),
      // dl_gain_1_2.val,
      .dl_gain_1_2_val_out    (ctrl_gain[1][2]),
      // dl_gain_1_3.val,
      .dl_gain_1_3_val_out    (ctrl_gain[1][3]),
      // dl_gain_2_0.val,
      .dl_gain_2_0_val_out    (ctrl_gain[2][0]),
      // dl_gain_2_1.val,
      .dl_gain_2_1_val_out    (ctrl_gain[2][1]),
      // dl_gain_2_2.val,
      .dl_gain_2_2_val_out    (ctrl_gain[2][2]),
      // dl_gain_2_3.val,
      .dl_gain_2_3_val_out    (ctrl_gain[2][3]),
      // dl_phase_comp,
      .dl_phase_comp_addr     (ctrl_phase_comp_addr),
      .dl_phase_comp_en       (ctrl_phase_comp_en),
      .dl_phase_comp_we       (ctrl_phase_comp_we),
      .dl_phase_comp_din      (ctrl_phase_comp_din),
      .dl_phase_comp_dout     (ctrl_phase_comp_dout),
      .dl_phase_comp_valid    (ctrl_phase_comp_valid)
  );
  /* verilator lint_on SELRANGE */


  generate
    for (genvar rat_idx = 0; rat_idx < NUM_CC; rat_idx++) begin : g_ctrl_rat
      assign ctrl_rat[rat_idx] = ctrl_rat_regs[rat_idx][1:0];
    end
  endgenerate

  pdxch_top #(
      .NUM_CC    (NUM_CC),
      .NUM_ANT   (NUM_ANT),
      .HALF_BLOCK(HALF_BLOCK),
      .HALF_FFT  (HALF_FFT)
  ) i_pdxch_top (
      // Radio I/F
      .clk                  (clk),
      .rst                  (rst),
      //
      .sync_in              (sync_in),
      //
      .m_axis_tdata         (m_axis_tdata),
      .m_axis_tuser         (m_axis_tuser),
      .m_axis_tlast         (m_axis_tlast),
      .m_axis_tvalid        (m_axis_tvalid),
      .m_axis_tready        (m_axis_tready),
      // O-RAN
      .clk_eth_xran         (clk_eth_xran),
      .rst_eth_xran         (rst_eth_xran),
      //
      .defm_radio_start_10ms(defm_radio_start_10ms),
      .s_dl_sym_num         (s_dl_sym_num),
      // U-Plane
      .s_defm_data_tdata    (s_defm_data_tdata),
      .s_defm_data_tkeep    (s_defm_data_tkeep),
      .s_defm_data_tvalid   (s_defm_data_tvalid),
      .s_defm_data_tlast    (s_defm_data_tlast),
      .s_defm_data_tready   (s_defm_data_tready),
      .s_defm_data_tuser    (s_defm_data_tuser),
      .s_defm_data_tdest    (s_defm_data_tdest),
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
      .ctrl_gain            (ctrl_gain),
      //
      .ctrl_phase_comp_addr (ctrl_phase_comp_addr),
      .ctrl_phase_comp_en   (ctrl_phase_comp_en),
      .ctrl_phase_comp_we   (ctrl_phase_comp_we),
      .ctrl_phase_comp_din  (ctrl_phase_comp_din),
      .ctrl_phase_comp_dout (ctrl_phase_comp_dout),
      .ctrl_phase_comp_valid(ctrl_phase_comp_valid)
  );

endmodule

`default_nettype wire
