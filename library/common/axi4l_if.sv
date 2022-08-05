// File: axi4l_if.sv
// Brief: Interface of AXI4-Lite interface.
`timescale 1 ns / 1 ps
//
`default_nettype none

interface axi4l_if #(
    parameter int HAS_ACLKEN  = 0,
    parameter int TADDR_WIDTH = 32,
    parameter int TDATA_WIDTH = 32
) (
    input var aclk,
    input var aclken,
    input var aresetn
);

  logic [  TADDR_WIDTH-1:0] awaddr;
  logic [              2:0] awprot;
  logic                     awvalid;
  logic                     awready;
  //
  logic [  TDATA_WIDTH-1:0] wdata;
  logic [TDATA_WIDTH/8-1:0] wstrb;
  logic                     wvalid;
  logic                     wready;
  //
  logic [              1:0] bresp;
  logic                     bvalid;
  logic                     bready;
  //
  logic [  TADDR_WIDTH-1:0] araddr;
  logic [              2:0] arprot;
  logic                     arvalid;
  logic                     arready;
  //
  logic [  TDATA_WIDTH-1:0] rdata;
  logic [              1:0] rresp;
  logic                     rvalid;
  logic                     rready;

  modport master(
      input aclk, aclken, aresetn,
      input awready, wready, bresp, bvalid, arready, rdata, rresp, rvalid,
      output awaddr, awprot, awvalid, wdata, wstrb, wvalid, bready, araddr, arprot, arvalid, rready
  );

  modport slave(
      input aclk, aclken, aresetn,
      input awaddr, awprot, awvalid, wdata, wstrb, wvalid, bready, araddr, arprot, arvalid, rready,
      output awready, wready, bresp, bvalid, arready, rdata, rresp, rvalid
  );

  modport monitor(
      input aclk, aclken, aresetn,
      input awaddr, awprot, awvalid, wdata, wstrb, wvalid, bready, araddr, arprot, arvalid, rready,
      input awready, wready, bresp, bvalid, arready, rdata, rresp, rvalid
  );

endinterface  // axi4l_if

`default_nettype wire
