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
    input var                          aclk,
    input var                          aresetn,
    // Due to a bug in Vivado 2020.2, I need to declare all posts below to type tri
    // Slave side interface
    //---------------------
    input     tri [  C_ADDR_WIDTH-1:0] s_axi_awaddr,
    input     tri [               2:0] s_axi_awprot,
    input     tri                      s_axi_awvalid,
    output    tri                      s_axi_awready,
    //
    input     tri [  C_DATA_WIDTH-1:0] s_axi_wdata,
    input     tri [C_DATA_WIDTH/8-1:0] s_axi_wstrb,
    input     tri                      s_axi_wvalid,
    output    tri                      s_axi_wready,
    //
    output    tri [               1:0] s_axi_bresp,
    output    tri                      s_axi_bvalid,
    input     tri                      s_axi_bready,
    //
    input     tri [  C_ADDR_WIDTH-1:0] s_axi_araddr,
    input     tri [               2:0] s_axi_arprot,
    input     tri                      s_axi_arvalid,
    output    tri                      s_axi_arready,
    //
    output    tri [  C_DATA_WIDTH-1:0] s_axi_rdata,
    output    tri [               1:0] s_axi_rresp,
    output    tri                      s_axi_rvalid,
    input     tri                      s_axi_rready,
    // Master side interface
    //----------------------
    output    tri [  C_ADDR_WIDTH-1:0] m_axi_awaddr,
    output    tri [               2:0] m_axi_awprot,
    output    tri                      m_axi_awvalid,
    input     tri                      m_axi_awready,
    //
    output    tri [  C_DATA_WIDTH-1:0] m_axi_wdata,
    output    tri [C_DATA_WIDTH/8-1:0] m_axi_wstrb,
    output    tri                      m_axi_wvalid,
    input     tri                      m_axi_wready,
    //
    input     tri [               1:0] m_axi_bresp,
    input     tri                      m_axi_bvalid,
    output    tri                      m_axi_bready,
    //
    output    tri [  C_ADDR_WIDTH-1:0] m_axi_araddr,
    output    tri [               2:0] m_axi_arprot,
    output    tri                      m_axi_arvalid,
    input     tri                      m_axi_arready,
    //
    input     tri [  C_DATA_WIDTH-1:0] m_axi_rdata,
    input     tri [               1:0] m_axi_rresp,
    input     tri                      m_axi_rvalid,
    output    tri                      m_axi_rready
);

  axi4l_if #(
      .C_ADDR_WIDTH(C_ADDR_WIDTH),
      .C_DATA_WIDTH(C_DATA_WIDTH)
  ) IF (
      .aclk   (aclk),
      .aresetn(aresetn)
  );

  logic is_master = 0;
  logic is_slave = 0;

  // Slave side connection

  assign IF.awaddr = is_slave ? s_axi_awaddr : 'z;
  assign IF.awprot = is_slave ? s_axi_awprot : 'z;
  assign IF.awvalid = is_slave ? s_axi_awvalid : 'z;
  assign s_axi_awready = is_slave ? IF.awready : '1;

  assign IF.wdata = is_slave ? s_axi_wdata : 'z;
  assign IF.wstrb = is_slave ? s_axi_wstrb : 'z;
  assign IF.wvalid = is_slave ? s_axi_wvalid : 'z;
  assign s_axi_wready = is_slave ? IF.wready : '1;

  assign s_axi_bresp = is_slave ? IF.bresp : '0;
  assign s_axi_bvalid = is_slave ? IF.bvalid : '0;
  assign IF.bready = is_slave ? s_axi_bready : 'z;

  assign IF.araddr = is_slave ? s_axi_araddr : 'z;
  assign IF.arprot = is_slave ? s_axi_arprot : 'z;
  assign IF.arvalid = is_slave ? s_axi_arvalid : 'z;
  assign s_axi_arready = is_slave ? IF.arready : '1;

  assign s_axi_rdata = is_slave ? IF.rdata : '0;
  assign s_axi_rresp = is_slave ? IF.rresp : '0;
  assign s_axi_rvalid = is_slave ? IF.rvalid : '0;
  assign IF.rready = is_slave ? s_axi_rready : 'z;

  // Master side connection

  assign m_axi_awaddr = is_master ? IF.awaddr : '0;
  assign m_axi_awprot = is_master ? IF.awprot : '0;
  assign m_axi_awvalid = is_master ? IF.awvalid : '0;
  assign IF.awready = is_master ? m_axi_awready : 'z;

  assign m_axi_wdata = is_master ? IF.wdata : '0;
  assign m_axi_wstrb = is_master ? IF.wstrb : '0;
  assign m_axi_wvalid = is_master ? IF.wvalid : '0;
  assign IF.wready = is_master ? m_axi_wready : 'z;

  assign IF.bresp = is_master ? m_axi_bresp : 'z;
  assign IF.bvalid = is_master ? m_axi_bvalid : 'z;
  assign m_axi_bready = is_master ? IF.bready : '0;

  assign m_axi_araddr = is_master ? IF.araddr : '0;
  assign m_axi_arprot = is_master ? IF.arprot : '0;
  assign m_axi_arvalid = is_master ? IF.arvalid : '0;
  assign IF.arready = is_master ? m_axi_arready : 'z;

  assign IF.rdata = is_master ? m_axi_rdata : 'z;
  assign IF.rresp = is_master ? m_axi_rresp : 'z;
  assign IF.rvalid = is_master ? m_axi_rvalid : 'z;
  assign m_axi_rready = is_master ? IF.rready : '0;

  // synthesis translate_off

  initial begin
    $display("axi4l_vip found on path %m");
  end

  // Set the interface to master mode
  function automatic void set_master_mode();
    is_master = 1;
    is_slave  = 0;
    IF.intf_set_master();
  endfunction

  // Set the interface to slave mode
  function automatic void set_slave_mode();
    is_master = 0;
    is_slave  = 1;
    IF.intf_set_slave();
  endfunction

  // Set the interface to monitor mode
  function automatic void set_monitor_mode();
    is_master = 1;
    is_slave  = 1;
    IF.intf_set_monitor();
  endfunction

  // Set the interface to autistic  mode
  function automatic void set_autistic_mode();
    is_master = 0;
    is_slave  = 0;
    IF.intf_set_monitor();
  endfunction

  // synthesis translate_on

endmodule

`default_nettype wire
