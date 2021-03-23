// File: axi4l_vip.sv
// Brief: AXI4-Lite Verification IP. It can be used to verify connectivity and
//        basic functionality of AXI4-Lite masters and slaves during simulation.
//        During synthesis, this core is just wire connection so you can easy
//        inject this core to any AXI4-Lite interface without worry the design
//        function impact.
`timescale 1 ns / 1 ps `default_nettype none

module axi4l_vip #(
    parameter int C_ADDR_WIDTH = 32,
    parameter int C_DATA_WIDTH = 32
) (
    input var                       aclk,
    input var                       aresetn,
    // Slave side interface
    //---------------------
    input var  [  C_ADDR_WIDTH-1:0] s_axi_awaddr,
    input var  [               2:0] s_axi_awprot,
    input var                       s_axi_awvalid,
    output var                      s_axi_awready,
    //
    input var  [  C_DATA_WIDTH-1:0] s_axi_wdata,
    input var  [C_DATA_WIDTH/8-1:0] s_axi_wstrb,
    input var                       s_axi_wvalid,
    output var                      s_axi_wready,
    //
    output var [               1:0] s_axi_bresp,
    output var                      s_axi_bvalid,
    input var                       s_axi_bready,
    //
    input var  [  C_ADDR_WIDTH-1:0] s_axi_araddr,
    input var  [               2:0] s_axi_arprot,
    input var                       s_axi_arvalid,
    output var                      s_axi_arready,
    //
    output var [  C_DATA_WIDTH-1:0] s_axi_rdata,
    output var [               1:0] s_axi_rresp,
    output var                      s_axi_rvalid,
    input var                       s_axi_rready,
    // Master side interface
    //----------------------
    output var [  C_ADDR_WIDTH-1:0] m_axi_awaddr,
    output var [               2:0] m_axi_awprot,
    output var                      m_axi_awvalid,
    input var                       m_axi_awready,
    //
    output var [  C_DATA_WIDTH-1:0] m_axi_wdata,
    output var [C_DATA_WIDTH/8-1:0] m_axi_wstrb,
    output var                      m_axi_wvalid,
    input var                       m_axi_wready,
    //
    input var  [               1:0] m_axi_bresp,
    input var                       m_axi_bvalid,
    output var                      m_axi_bready,
    //
    output var [  C_ADDR_WIDTH-1:0] m_axi_araddr,
    output var [               2:0] m_axi_arprot,
    output var                      m_axi_arvalid,
    input var                       m_axi_arready,
    //
    input var  [  C_DATA_WIDTH-1:0] m_axi_rdata,
    input var  [               1:0] m_axi_rresp,
    input var                       m_axi_rvalid,
    output var                      m_axi_rready
);

  axi4l_if #(
      .C_ADDR_WIDTH(C_ADDR_WIDTH),
      .C_DATA_WIDTH(C_DATA_WIDTH)
  ) IF (
      .aclk   (aclk),
      .aresetn(aresetn)
  );

  initial begin
    $display("axi4l_vip found on path %m");
  end

  // Slave side connection

  assign IF.awaddr = s_axi_awaddr;
  assign IF.awprot = s_axi_awprot;
  assign IF.awvalid = s_axi_awvalid;
  assign s_axi_awready = IF.awready;

  assign IF.wdata = s_axi_wdata;
  assign IF.wstrb = s_axi_wstrb;
  assign IF.wvalid = s_axi_wvalid;
  assign s_axi_wready = IF.wready;

  assign s_axi_bresp = IF.bresp;
  assign s_axi_bvalid = IF.bvalid;
  assign IF.bready = s_axi_bready;

  assign IF.araddr = s_axi_araddr;
  assign IF.arprot = s_axi_arprot;
  assign IF.arvalid = s_axi_arvalid;
  assign s_axi_arready = IF.arready;

  assign s_axi_rdata = IF.rdata;
  assign s_axi_rresp = IF.rresp;
  assign s_axi_rvalid = IF.rvalid;
  assign IF.rready = s_axi_rready;

  // Master side connection

  assign m_axi_awaddr = IF.awaddr;
  assign m_axi_awprot = IF.awprot;
  assign m_axi_awvalid = IF.awvalid;
  assign IF.awready = m_axi_awready;

  assign m_axi_wdata = IF.wdata;
  assign m_axi_wstrb = IF.wstrb;
  assign m_axi_wvalid = IF.wvalid;
  assign IF.wready = m_axi_wready;

  assign IF.bresp = m_axi_bresp;
  assign IF.bvalid = m_axi_bvalid;
  assign m_axi_bready = IF.bready;

  assign m_axi_araddr = IF.araddr;
  assign m_axi_arprot = IF.arprot;
  assign m_axi_arvalid = IF.arvalid;
  assign IF.arready = m_axi_arready;

  assign IF.rdata = m_axi_rdata;
  assign IF.rresp = m_axi_rresp;
  assign IF.rvalid = m_axi_rvalid;
  assign m_axi_rready = IF.rready;

endmodule

`default_nettype wire
