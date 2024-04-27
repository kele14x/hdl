`ifndef __AXI4S_IF__
`define __AXI4S_IF__

`timescale 1 ns / 1 ps
//
`default_nettype none

`define MAX_TDATA_WIDTH 512
`define MAX_TUSER_WIDTH 128
`define MAX_TID_WIDTH 64
`define MAX_TDEST_WIDTH 64

interface axi4s_if (
    input var aclk,
    input var aclken,
    input var aresetn
);

  logic                          tvalid;
  logic                          tready = 1'b1;
  logic                          tlast;

  logic [  `MAX_TDATA_WIDTH-1:0] tdata;
  logic [`MAX_TDATA_WIDTH/8-1:0] tkeep;
  logic [`MAX_TDATA_WIDTH/8-1:0] tstrb;
  logic [  `MAX_TUSER_WIDTH-1:0] tuser;
  logic [    `MAX_TID_WIDTH-1:0] tid;
  logic [    `MAX_TDEST_WIDTH:0] tdest;

endinterface

`default_nettype wire

`endif
