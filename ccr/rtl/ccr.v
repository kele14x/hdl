`timescale 1 ns / 1 ps
//
`default_nettype none

module ccr (
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
    input  wire        stat_mmcm0_locked,
    input  wire        stat_mmcm1_locked
);

  wire [31:0] stat_buildtime_0;
  wire [31:0] stat_buildtime_1;

  wire [31:0] stat_freq0;

  ccr_regs i_regs (
      .s_axi_aclk          (s_axi_aclk),
      .s_axi_aresetn       (s_axi_aresetn),
      //
      .s_axi_awaddr        (s_axi_awaddr),
      .s_axi_awprot        (s_axi_awprot),
      .s_axi_awvalid       (s_axi_awvalid),
      .s_axi_awready       (s_axi_awready),
      //
      .s_axi_wdata         (s_axi_wdata),
      .s_axi_wstrb         (s_axi_wstrb),
      .s_axi_wvalid        (s_axi_wvalid),
      .s_axi_wready        (s_axi_wready),
      //
      .s_axi_bresp         (s_axi_bresp),
      .s_axi_bvalid        (s_axi_bvalid),
      .s_axi_bready        (s_axi_bready),
      //
      .s_axi_araddr        (s_axi_araddr),
      .s_axi_arprot        (s_axi_arprot),
      .s_axi_arvalid       (s_axi_arvalid),
      .s_axi_arready       (s_axi_arready),
      //
      .s_axi_rdata         (s_axi_rdata),
      .s_axi_rresp         (s_axi_rresp),
      .s_axi_rvalid        (s_axi_rvalid),
      .s_axi_rready        (s_axi_rready),
      // buildtime_0.val,
      .buildtime_0_val_in  (stat_buildtime_0),
      // buildtime_1.val,
      .buildtime_1_val_in  (stat_buildtime_1),
      // stat.mmcm0_locked,
      .stat_mmcm0_locked_in(stat_mmcm0_locked),
      // stat.mmcm1_locked,
      .stat_mmcm1_locked_in(stat_mmcm1_locked),
      // freq.val,
      .freq_val_in         (stat_freq0)
  );

  ccr_buildtime i_build_time (
      .stat_buildtime_0(stat_buildtime_0),
      .stat_buildtime_1(stat_buildtime_1)
  );

  ccr_freq #(
      .FREQUENCY(100_000_000)
  ) i_freq (
      .clk       (clk),
      .rst       (rst),
      //
      .ctrl_clk  (s_axi_aclk),
      .ctrl_rst  (~s_axi_aresetn),
      //
      .stat_freq0(stat_freq0)
  );

endmodule

`default_nettype wire
