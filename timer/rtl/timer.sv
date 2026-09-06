`timescale 1 ns / 1 ps
//
`default_nettype none

module timer #(
    parameter int FREQ_MODE    = 0,  // 0: 400 MHz, 1: 491.52 MHz
    parameter int SIM_SPEED_UP = 0
) (
    input var         s_axi_aclk,
    input var         s_axi_aresetn,
    //
    /* verilator lint_off UNUSED */
    input var  [15:0] s_axi_awaddr,
    /* verilator lint_on UNUSED */
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
    /* verilator lint_off UNUSED */
    input var  [15:0] s_axi_araddr,
    /* verilator lint_on UNUSED */
    input var  [ 2:0] s_axi_arprot,
    input var         s_axi_arvalid,
    output var        s_axi_arready,
    //
    output var [31:0] s_axi_rdata,
    output var [ 1:0] s_axi_rresp,
    output var        s_axi_rvalid,
    input var         s_axi_rready,
    //
    input var         clk,
    input var         rst,
    //
    input var         pps_in,
    //
    output var [47:0] tod_sec,
    output var [31:0] tod_ns,
    //
    output var        pps_out,
    output var        pps_pad,
    //
    output var        rfs_out,
    output var        rfs_pad
);

  wire        ctrl_rtc_offset_valid;
  //
  wire [31:0] ctrl_rtc_offset_ns;
  wire [47:0] ctrl_rtc_offset_sec;
  //
  wire        ctrl_rtc_current_snap;
  //
  wire [31:0] stat_rtc_current_ns;
  wire [47:0] stat_rtc_current_sec;

  wire [22:0] ctrl_rfs_offset;

  wire        pps_s;

  wire [47:0] tod_sec_s;
  wire [31:0] tod_ns_s;

  timer_regs i_regs (
      .s_axi_aclk              (s_axi_aclk),
      .s_axi_aresetn           (s_axi_aresetn),
      //
      .s_axi_awaddr            (s_axi_awaddr[8:0]),
      .s_axi_awprot            (s_axi_awprot),
      .s_axi_awvalid           (s_axi_awvalid),
      .s_axi_awready           (s_axi_awready),
      //
      .s_axi_wdata             (s_axi_wdata),
      .s_axi_wstrb             (s_axi_wstrb),
      .s_axi_wvalid            (s_axi_wvalid),
      .s_axi_wready            (s_axi_wready),
      //
      .s_axi_bresp             (s_axi_bresp),
      .s_axi_bvalid            (s_axi_bvalid),
      .s_axi_bready            (s_axi_bready),
      //
      .s_axi_araddr            (s_axi_araddr[8:0]),
      .s_axi_arprot            (s_axi_arprot),
      .s_axi_arvalid           (s_axi_arvalid),
      .s_axi_arready           (s_axi_arready),
      //
      .s_axi_rdata             (s_axi_rdata),
      .s_axi_rresp             (s_axi_rresp),
      .s_axi_rvalid            (s_axi_rvalid),
      .s_axi_rready            (s_axi_rready),
      // rtc_offset_ns.val,
      .rtc_offset_ns_val_out   (ctrl_rtc_offset_ns),
      // rtc_offset_sec_l.val,
      .rtc_offset_sec_l_val_out(ctrl_rtc_offset_sec[31:0]),
      // rtc_offset_sec_h.val,
      .rtc_offset_sec_h_val_out(ctrl_rtc_offset_sec[47:32]),
      // rtc_offset_valid.val,
      .rtc_offset_valid_val_in (1'b0),
      .rtc_offset_valid_val_out(ctrl_rtc_offset_valid),
      // rtc_current_ns.val,
      .rtc_current_ns_val_in   (stat_rtc_current_ns),
      // rtc_current_sec_l.val,
      .rtc_current_sec_l_val_in(stat_rtc_current_sec[31:0]),
      // rtc_current_sec_h.val,
      .rtc_current_sec_h_val_in(stat_rtc_current_sec[47:32]),
      // rtc_current_snap.val,
      .rtc_current_snap_val_in (1'b0),
      .rtc_current_snap_val_out(ctrl_rtc_current_snap),
      // rfs_offset.val,
      .rfs_offset_val_out      (ctrl_rfs_offset)
  );

  generate
    if (FREQ_MODE == 0) begin : g_400

      timer_core_400 #(
          .SIM_SPEED_UP(SIM_SPEED_UP)
      ) i_core (
          .clk                  (clk),
          .rst                  (rst),
          //
          .pps_in               (pps_in),
          .pps_out              (pps_s),
          //
          .tod_sec              (tod_sec_s),
          .tod_ns               (tod_ns_s),
          //
          .ctrl_clk             (s_axi_aclk),
          .ctrl_rst             (~s_axi_aresetn),
          //
          .ctrl_rtc_offset_valid(ctrl_rtc_offset_valid),
          .ctrl_rtc_offset_ns   (ctrl_rtc_offset_ns),
          .ctrl_rtc_offset_sec  (ctrl_rtc_offset_sec),
          //
          .ctrl_rtc_current_snap(ctrl_rtc_current_snap),
          //
          .stat_rtc_current_ns  (stat_rtc_current_ns),
          .stat_rtc_current_sec (stat_rtc_current_sec)
      );

    end else begin : g_491p52

      timer_core_491p52 #(
          .SIM_SPEED_UP(SIM_SPEED_UP)
      ) i_core (
          .clk                  (clk),
          .rst                  (rst),
          //
          .pps_in               (pps_in),
          .pps_out              (pps_s),
          //
          .tod_sec              (tod_sec_s),
          .tod_ns               (tod_ns_s),
          //
          .ctrl_clk             (s_axi_aclk),
          .ctrl_rst             (~s_axi_aresetn),
          //
          .ctrl_rtc_offset_valid(ctrl_rtc_offset_valid),
          .ctrl_rtc_offset_ns   (ctrl_rtc_offset_ns),
          .ctrl_rtc_offset_sec  (ctrl_rtc_offset_sec),
          //
          .ctrl_rtc_current_snap(ctrl_rtc_current_snap),
          //
          .stat_rtc_current_ns  (stat_rtc_current_ns),
          .stat_rtc_current_sec (stat_rtc_current_sec)
      );

    end
  endgenerate

  delay #(
      .WIDTH(80),
      .DEPTH(2)
  ) i_delay_tod (
      .clk (clk),
      .rst (rst),
      .cen (1'b1),
      .din ({tod_sec_s, tod_ns_s}),
      .dout({tod_sec, tod_ns})
  );

  timer_pps #(
      .FREQ_MODE(FREQ_MODE)
  ) i_pps (
      .clk    (clk),
      .rst    (rst),
      //
      .pps_in (pps_s),
      //
      .pps_out(pps_out),
      .pps_pad(pps_pad)
  );

  timer_rfs #(
      .FREQ_MODE(FREQ_MODE)
  ) i_rfs (
      .clk            (clk),
      .rst            (rst),
      //
      .pps_in         (pps_s),
      //
      .rfs_out        (rfs_out),
      .rfs_pad        (rfs_pad),
      //
      .ctrl_rfs_offset(ctrl_rfs_offset)
  );

endmodule

`default_nettype wire
