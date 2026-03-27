`timescale 1 ns / 1 ps
//
`default_nettype none

// verilog_format: off
module ccr_wrapper (
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 s_axi_aclk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_RESET s_axi_aresetn, ASSOCIATED_BUSIF S_AXI, FREQ_HZ 100000000, FREQ_TOLERANCE_HZ 0" *)
    input  wire         s_axi_aclk,
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 s_axi_aresetn RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)
    input  wire         s_axi_aresetn,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWADDR" *)
    input  wire [ 15:0] s_axi_awaddr,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWPROT" *)
    input  wire [  2:0] s_axi_awprot,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWVALID" *)
    input  wire         s_axi_awvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWREADY" *)
    output wire         s_axi_awready,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WDATA" *)
    input  wire [ 31:0] s_axi_wdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WSTRB" *)
    input  wire [  3:0] s_axi_wstrb,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WVALID" *)
    input  wire         s_axi_wvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WREADY" *)
    output wire         s_axi_wready,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI BRESP" *)
    output wire [  1:0] s_axi_bresp,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI BVALID" *)
    output wire         s_axi_bvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI BREADY" *)
    input  wire         s_axi_bready,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARADDR" *)
    input  wire [ 15:0] s_axi_araddr,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARPROT" *)
    input  wire [  2:0] s_axi_arprot,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARVALID" *)
    input  wire         s_axi_arvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARREADY" *)
    output wire         s_axi_arready,
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RDATA" *)
    output wire [ 31:0] s_axi_rdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RRESP" *)
    output wire [  1:0] s_axi_rresp,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RVALID" *)
    output wire         s_axi_rvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RREADY" *)
    input  wire         s_axi_rready,
    //
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 clk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_RESET rstn, FREQ_HZ 491520000, FREQ_TOLERANCE_HZ 0" *)
    input  wire         clk,
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 rstn RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)
    input  wire         rstn,
    //
    input  wire         stat_mmcm0_locked,
    input  wire         stat_mmcm1_locked
);
// verilog_format: on

  ccr inst (
      .s_axi_aclk       (s_axi_aclk),
      .s_axi_aresetn    (s_axi_aresetn),
      //
      .s_axi_awaddr     (s_axi_awaddr),
      .s_axi_awprot     (s_axi_awprot),
      .s_axi_awvalid    (s_axi_awvalid),
      .s_axi_awready    (s_axi_awready),
      //
      .s_axi_wdata      (s_axi_wdata),
      .s_axi_wstrb      (s_axi_wstrb),
      .s_axi_wvalid     (s_axi_wvalid),
      .s_axi_wready     (s_axi_wready),
      //
      .s_axi_bresp      (s_axi_bresp),
      .s_axi_bvalid     (s_axi_bvalid),
      .s_axi_bready     (s_axi_bready),
      //
      .s_axi_araddr     (s_axi_araddr),
      .s_axi_arprot     (s_axi_arprot),
      .s_axi_arvalid    (s_axi_arvalid),
      .s_axi_arready    (s_axi_arready),
      //
      .s_axi_rdata      (s_axi_rdata),
      .s_axi_rresp      (s_axi_rresp),
      .s_axi_rvalid     (s_axi_rvalid),
      .s_axi_rready     (s_axi_rready),
      //
      .clk              (clk),
      .rst              (~rstn),
      //
      .stat_mmcm0_locked(stat_mmcm0_locked),
      .stat_mmcm1_locked(stat_mmcm1_locked)
  );

endmodule

`default_nettype wire
