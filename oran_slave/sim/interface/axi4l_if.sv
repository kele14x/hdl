`ifndef __AXI4L_IF__
`define __AXI4L_IF__

`timescale 1 ns / 1 ps
//
`default_nettype none

`define MAX_ADDR_WIDTH 32
`define MAX_DATA_WIDTH 32

interface axi4l_if (
    input var aclk,
    input var aclken,
    input var aresetn
);

  logic [  `MAX_ADDR_WIDTH-1:0] awaddr;
  logic [                  2:0] awprot;
  logic                         awvalid;
  logic                         awready;

  logic [  `MAX_DATA_WIDTH-1:0] wdata;
  logic [`MAX_DATA_WIDTH/8-1:0] wstrb;
  logic                         wvalid;
  logic                         wready;

  logic [                  1:0] bresp;
  logic                         bvalid;
  logic                         bready;

  logic [  `MAX_ADDR_WIDTH-1:0] araddr;
  logic [                  2:0] arprot;
  logic                         arvalid;
  logic                         arready;

  logic [  `MAX_DATA_WIDTH-1:0] rdata;
  logic [                  1:0] rresp;
  logic                         rvalid;
  logic                         rready;

endinterface : axi4l_if

`default_nettype wire

`endif
