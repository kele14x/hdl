`timescale 1 ns / 1 ps
//
`default_nettype none

module timer #(
    parameter integer FREQ_MODE    = 0,  // 0: 400 MHz, 1: 491.52 MHz
    parameter reg     SIM_SPEED_UP = 1'b0
) (
    input  wire        s_axi_aclk,
    input  wire        s_axi_aresetn,
    //
    input  wire [15:0] s_axi_awaddr,
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
    input  wire [15:0] s_axi_araddr,
    input  wire [ 2:0] s_axi_arprot,
    input  wire        s_axi_arvalid,
    output wire        s_axi_arready,
    //
    output wire [31:0] s_axi_rdata,
    output wire [ 1:0] s_axi_rresp,
    output wire        s_axi_rvalid,
    input  wire        s_axi_rready,
    //
    input  wire        clk,
    input  wire        rst,
    //
    input  wire        pps_in,
    //
    output wire [47:0] tod_sec,
    output wire [31:0] tod_ns,
    //
    output wire        pps_out,
    output wire        pps_pad,
    //
    output wire        rfs_out,
    output wire        rfs_pad
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

  wire unused_axi_addr_msb = &{1'b0, s_axi_awaddr[15:9], s_axi_araddr[15:9], 1'b0};

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
      .DEPTH(2),
      .INIT (0)
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
