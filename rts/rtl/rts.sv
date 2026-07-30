`timescale 1 ns / 1 ps
//
`default_nettype none

module rts (
    input  wire         s_axi_aclk,
    input  wire         s_axi_aresetn,
    //
    input  wire [ 16:0] s_axi_awaddr,
    input  wire [  2:0] s_axi_awprot,
    input  wire         s_axi_awvalid,
    output wire         s_axi_awready,
    //
    input  wire [ 31:0] s_axi_wdata,
    input  wire [  3:0] s_axi_wstrb,
    input  wire         s_axi_wvalid,
    output wire         s_axi_wready,
    //
    output wire [  1:0] s_axi_bresp,
    output wire         s_axi_bvalid,
    input  wire         s_axi_bready,
    //
    input  wire [ 16:0] s_axi_araddr,
    input  wire [  2:0] s_axi_arprot,
    input  wire         s_axi_arvalid,
    output wire         s_axi_arready,
    //
    output wire [ 31:0] s_axi_rdata,
    output wire [  1:0] s_axi_rresp,
    output wire         s_axi_rvalid,
    input  wire         s_axi_rready,
    // Internal interfaces
    //--------------------
    input  wire         clk,
    input  wire         clk_l,
    input  wire         rst,
    //
    input  wire         rfs_in,
    // Coe ports
    output wire [767:0] m_axis_tdata,
    output wire [  7:0] m_axis_tuser,
    output wire         m_axis_tlast,
    output wire         m_axis_tvalid,
    input  wire         m_axis_tready,
    //
    input  wire [767:0] s_axis_tdata,
    input  wire [  7:0] s_axis_tuser,
    input  wire         s_axis_tlast,
    input  wire         s_axis_tvalid,
    output wire         s_axis_tready
);

  // Parameters

  localparam integer NumCc = 24;

  // CSR signals

  wire [      NumCc*6-1:0] ctrl_src_sel;

  wire [              2:0] ctrl_ram_mode;

  wire [             19:0] ctrl_cw0_freq;
  wire [             15:0] ctrl_cw0_pow;
  wire [             19:0] ctrl_cw1_freq;
  wire [             15:0] ctrl_cw1_pow;

  wire [             19:0] ctrl_ram0_offset;
  wire [             19:0] ctrl_ram1_offset;
  wire [             19:0] ctrl_ram2_offset;

  wire [              6:0] ctrl_injt_ram_addr_msb;

  wire [             12:0] ctrl_injt_ram_addr;
  wire                     ctrl_injt_ram_en;
  wire                     ctrl_injt_ram_we;
  wire [             31:0] ctrl_injt_ram_din;
  wire [             31:0] ctrl_injt_ram_dout;
  wire                     ctrl_injt_ram_valid;

  wire [              5:0] ctrl_cap_cc_sel;
  wire                     unused_ctrl_cap_cc_sel_msb = ctrl_cap_cc_sel[5];
  wire                     ctrl_cap_pos_sel;
  wire [              1:0] ctrl_cap_mode;
  wire [             18:0] ctrl_cap_offset;
  wire [              4:0] ctrl_cap_len;
  wire                     ctrl_cap_trigger;
  wire                     ctrl_cap_force;

  wire                     stat_cap_status;

  wire [              3:0] ctrl_cap_ram_addr_msb;

  wire [             12:0] ctrl_cap_ram_addr;
  wire                     ctrl_cap_ram_en;
  wire                     ctrl_cap_ram_we;
  wire [             31:0] ctrl_cap_ram_din;
  wire [             31:0] ctrl_cap_ram_dout;
  wire                     ctrl_cap_ram_valid;

  // Signals

  logic                      rfs_d;

  wire [             31:0] mux_axis_tdata;
  wire [              7:0] mux_axis_tuser;
  wire                     mux_axis_tlast;
  wire                     mux_axis_tvalid;

  //

  wire [             15:0] cw_cos;
  wire [             15:0] cw_sin;

  wire [             31:0] cw_data;
  wire [             31:0] ram0_data;
  wire [             31:0] ram1_data;
  wire [             31:0] ram2_data;

  // Main

  rts_regs i_regs (
      .s_axi_aclk               (s_axi_aclk),
      .s_axi_aresetn            (s_axi_aresetn),
      //
      .s_axi_awaddr             (s_axi_awaddr),
      .s_axi_awprot             (s_axi_awprot),
      .s_axi_awvalid            (s_axi_awvalid),
      .s_axi_awready            (s_axi_awready),
      //
      .s_axi_wdata              (s_axi_wdata),
      .s_axi_wstrb              (s_axi_wstrb),
      .s_axi_wvalid             (s_axi_wvalid),
      .s_axi_wready             (s_axi_wready),
      //
      .s_axi_bresp              (s_axi_bresp),
      .s_axi_bvalid             (s_axi_bvalid),
      .s_axi_bready             (s_axi_bready),
      //
      .s_axi_araddr             (s_axi_araddr),
      .s_axi_arprot             (s_axi_arprot),
      .s_axi_arvalid            (s_axi_arvalid),
      .s_axi_arready            (s_axi_arready),
      //
      .s_axi_rdata              (s_axi_rdata),
      .s_axi_rresp              (s_axi_rresp),
      .s_axi_rvalid             (s_axi_rvalid),
      .s_axi_rready             (s_axi_rready),
      // src_sel_0.cc0,
      .src_sel_0_cc0_out        (ctrl_src_sel[5:0]),
      // src_sel_0.cc1,
      .src_sel_0_cc1_out        (ctrl_src_sel[11:6]),
      // src_sel_0.cc2,
      .src_sel_0_cc2_out        (ctrl_src_sel[17:12]),
      // src_sel_0.cc3,
      .src_sel_0_cc3_out        (ctrl_src_sel[23:18]),
      // src_sel_1.cc4,
      .src_sel_1_cc0_out        (ctrl_src_sel[29:24]),
      // src_sel_1.cc5,
      .src_sel_1_cc1_out        (ctrl_src_sel[35:30]),
      // src_sel_1.cc6,
      .src_sel_1_cc2_out        (ctrl_src_sel[41:36]),
      // src_sel_1.cc7,
      .src_sel_1_cc3_out        (ctrl_src_sel[47:42]),
      // src_sel_2.cc8,
      .src_sel_2_cc0_out        (ctrl_src_sel[53:48]),
      // src_sel_2.cc9,
      .src_sel_2_cc1_out        (ctrl_src_sel[59:54]),
      // src_sel_2.cc10,
      .src_sel_2_cc2_out        (ctrl_src_sel[65:60]),
      // src_sel_2.cc11,
      .src_sel_2_cc3_out        (ctrl_src_sel[71:66]),
      // src_sel_3.cc0,
      .src_sel_3_cc0_out        (ctrl_src_sel[77:72]),
      // src_sel_3.cc1,
      .src_sel_3_cc1_out        (ctrl_src_sel[83:78]),
      // src_sel_3.cc2,
      .src_sel_3_cc2_out        (ctrl_src_sel[89:84]),
      // src_sel_3.cc3,
      .src_sel_3_cc3_out        (ctrl_src_sel[95:90]),
      // src_sel_4.cc0,
      .src_sel_4_cc0_out        (ctrl_src_sel[101:96]),
      // src_sel_4.cc1,
      .src_sel_4_cc1_out        (ctrl_src_sel[107:102]),
      // src_sel_4.cc2,
      .src_sel_4_cc2_out        (ctrl_src_sel[113:108]),
      // src_sel_4.cc3,
      .src_sel_4_cc3_out        (ctrl_src_sel[119:114]),
      // src_sel_5.cc0,
      .src_sel_5_cc0_out        (ctrl_src_sel[125:120]),
      // src_sel_5.cc1,
      .src_sel_5_cc1_out        (ctrl_src_sel[131:126]),
      // src_sel_5.cc2,
      .src_sel_5_cc2_out        (ctrl_src_sel[137:132]),
      // src_sel_5.cc3,
      .src_sel_5_cc3_out        (ctrl_src_sel[143:138]),
      // ram_mode.val,
      .ram_mode_val_out         (ctrl_ram_mode),
      // cw0_freq.val,
      .cw0_freq_val_out         (ctrl_cw0_freq),
      // cw0_pow.val,
      .cw0_pow_val_out          (ctrl_cw0_pow),
      // cw1_freq.val,
      .cw1_freq_val_out         (ctrl_cw1_freq),
      // cw1_pow.val,
      .cw1_pow_val_out          (ctrl_cw1_pow),
      // injt_ram_addr_msb_val_out.val,
      .injt_ram_addr_msb_val_out(ctrl_injt_ram_addr_msb),
      // ram0_offset.val,
      .ram0_offset_val_out      (ctrl_ram0_offset),
      // ram1_offset.val,
      .ram1_offset_val_out      (ctrl_ram1_offset),
      // ram2_offset.val,
      .ram2_offset_val_out      (ctrl_ram2_offset),
      // cap_sel.cc,
      .cap_sel_cc_out           (ctrl_cap_cc_sel),
      // cap_sel.pos,
      .cap_sel_pos_out          (ctrl_cap_pos_sel),
      // cap_mode.val,
      .cap_mode_val_out         (ctrl_cap_mode),
      // cap_offset.val,
      .cap_offset_val_out       (ctrl_cap_offset),
      // cap_len.val,
      .cap_len_val_out          (ctrl_cap_len),
      // cap_ctrl.trigger,
      .cap_ctrl_trigger_out     (ctrl_cap_trigger),
      .cap_ctrl_trigger_in      (1'b0),
      // cap_ctrl.force,
      .cap_ctrl_force_out       (ctrl_cap_force),
      .cap_ctrl_force_in        (1'b0),
      // cap_ctrl.status,
      .cap_ctrl_status_in       (stat_cap_status),
      // cap_ram_addr_msb.val,
      .cap_ram_addr_msb_val_out (ctrl_cap_ram_addr_msb),
      // injt_ram,
      .injt_ram_addr            (ctrl_injt_ram_addr),
      .injt_ram_en              (ctrl_injt_ram_en),
      .injt_ram_we              (ctrl_injt_ram_we),
      .injt_ram_din             (ctrl_injt_ram_din),
      .injt_ram_dout            (ctrl_injt_ram_dout),
      .injt_ram_valid           (ctrl_injt_ram_valid),
      // cap_ram,
      .cap_ram_addr             (ctrl_cap_ram_addr),
      .cap_ram_en               (ctrl_cap_ram_en),
      .cap_ram_we               (ctrl_cap_ram_we),
      .cap_ram_din              (ctrl_cap_ram_din),
      .cap_ram_dout             (ctrl_cap_ram_dout),
      .cap_ram_valid            (ctrl_cap_ram_valid)
  );

  // Main

  assign s_axis_tready = 1'b1;

  always_ff @(posedge clk) begin
    rfs_d <= rfs_in;
  end

  // CW

  rts_cw i_cw (
      .clk          (clk),
      .rst          (rst),
      //
      .sync         (rfs_d),
      //
      .cw_cos       (cw_cos),
      .cw_sin       (cw_sin),
      //
      .ctrl_cw0_freq(ctrl_cw0_freq),
      .ctrl_cw0_pow (ctrl_cw0_pow),
      .ctrl_cw1_freq(ctrl_cw1_freq),
      .ctrl_cw1_pow (ctrl_cw1_pow)
  );

  assign cw_data = {cw_sin, cw_cos};

  rts_ram i_playback_ram (
      .clk              (clk),
      .clk_l            (clk_l),
      .rst              (rst),
      //
      .sync             (rfs_d),
      //
      .dout0            (ram0_data),
      .dout1            (ram1_data),
      .dout2            (ram2_data),
      //
      .ctrl_clk         (s_axi_aclk),
      .ctrl_rst         (~s_axi_aresetn),
      //
      .ctrl_ram_mode    (ctrl_ram_mode),
      //
      .ctrl_ram0_offset (ctrl_ram0_offset),
      .ctrl_ram1_offset (ctrl_ram1_offset),
      .ctrl_ram2_offset (ctrl_ram2_offset),
      //
      .ctrl_ram_addr_msb(ctrl_injt_ram_addr_msb),
      //
      .ctrl_ram_addr    (ctrl_injt_ram_addr),
      .ctrl_ram_en      (ctrl_injt_ram_en),
      .ctrl_ram_we      (ctrl_injt_ram_we),
      .ctrl_ram_din     (ctrl_injt_ram_din),
      .ctrl_ram_dout    (ctrl_injt_ram_dout),
      .ctrl_ram_valid   (ctrl_injt_ram_valid)
  );

  rts_mux #(
      .NUM_CC(NumCc)
  ) i_injt_mux (
      .clk          (clk),
      .rst          (rst),
      //
      .sync         (rfs_d),
      //
      .cw_data      (cw_data),
      .ram0_data    (ram0_data),
      .ram1_data    (ram1_data),
      .ram2_data    (ram2_data),
      //
      .m_axis_tdata (m_axis_tdata),
      .m_axis_tuser (m_axis_tuser),
      .m_axis_tlast (m_axis_tlast),
      .m_axis_tvalid(m_axis_tvalid),
      .m_axis_tready(m_axis_tready),
      //
      .ctrl_src_sel (ctrl_src_sel)
  );

  // Data capture

  rts_cap_mux #(
      .NUM_CC(NumCc)
  ) i_cap_mux (
      .clk           (clk),
      .rst           (rst),
      // monitor interface
      .s0_axis_tdata (m_axis_tdata),
      .s0_axis_tuser (m_axis_tuser),
      .s0_axis_tlast (m_axis_tlast),
      .s0_axis_tvalid(m_axis_tvalid),
      .s0_axis_tready(m_axis_tready),
      //
      .s1_axis_tdata (s_axis_tdata),
      .s1_axis_tuser (s_axis_tuser),
      .s1_axis_tlast (s_axis_tlast),
      .s1_axis_tvalid(s_axis_tvalid),
      .s1_axis_tready(s_axis_tready),
      //
      .m_axis_tdata  (mux_axis_tdata),
      .m_axis_tuser  (mux_axis_tuser),
      .m_axis_tlast  (mux_axis_tlast),
      .m_axis_tvalid (mux_axis_tvalid),
      //
      .ctrl_pos_sel  (ctrl_cap_pos_sel),
      .ctrl_cc_sel   (ctrl_cap_cc_sel[$clog2(NumCc)-1:0])
  );

  rts_cap_ram i_cap_ram (
      .clk              (clk),
      .clk_l            (clk_l),
      .rst              (rst),
      //
      .sync             (rfs_d),
      //
      .s_axis_tdata     (mux_axis_tdata),
      .s_axis_tuser     (mux_axis_tuser),
      .s_axis_tlast     (mux_axis_tlast),
      .s_axis_tvalid    (mux_axis_tvalid),
      //
      .ctrl_clk         (s_axi_aclk),
      .ctrl_rst         (~s_axi_aresetn),
      //
      .ctrl_cap_trigger (ctrl_cap_trigger),
      .ctrl_cap_force   (ctrl_cap_force),
      .ctrl_cap_mode    (ctrl_cap_mode),
      .ctrl_cap_len     (ctrl_cap_len),
      .ctrl_cap_offset  (ctrl_cap_offset),
      //
      .stat_cap_status  (stat_cap_status),
      //
      .ctrl_ram_addr_msb(ctrl_cap_ram_addr_msb),
      //
      .ctrl_ram_addr    (ctrl_cap_ram_addr),
      .ctrl_ram_en      (ctrl_cap_ram_en),
      .ctrl_ram_we      (ctrl_cap_ram_we),
      .ctrl_ram_din     (ctrl_cap_ram_din),
      .ctrl_ram_dout    (ctrl_cap_ram_dout),
      .ctrl_ram_valid   (ctrl_cap_ram_valid)
  );

endmodule

`default_nettype wire
