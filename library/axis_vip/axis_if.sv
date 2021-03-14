// File: axis_if.sv
// Brief: AXI4-Stream Interface.

`timescale 1 ns / 1 ps `default_nettype none

interface axis_if #(
    parameter int TDATA_WIDTH = 32,
    parameter int TUSER_WIDTH = 0,
    parameter int TID_WIDTH   = 0,
    parameter int TDEST_WIDTH = 0,
    parameter int HAS_TREADY  = 1,
    parameter int HAS_TSTRB   = 0,
    parameter int HAS_TKEEP   = 0,
    parameter int HAS_TLAST   = 0,
    parameter int HAS_ARESETN = 1,
    parameter int HAS_ACLKEN  = 0
) (
    input var aclk,
    input var aresetn,
    input var aclken
);

  logic [  TDATA_WIDTH-1:0] tdata;
  logic [  TDEST_WIDTH-1:0] tdest;
  logic [    TID_WIDTH-1:0] tid;
  logic [TDATA_WIDTH/8-1:0] tkeep;
  logic                     tlast;
  logic                     tvalid;
  logic [TDATA_WIDTH/8-1:0] tstrb;
  logic [  TUSER_WIDTH-1:0] tuser;
  logic                     tready;

  modport master(
      input aclk, aresetn, aclken, tready,
      output tdata, tdest, tid, tkeep, tlast, tvalid, tstrb, tuser
  );

  modport slave(
      input aclk, aresetn, aclken, tdata, tdest, tid, tkeep, tlast, tvalid, tstrb, tuser,
      output tready
  );

  task send_frame();
    int i = 0;
    wait(aresetn);

    repeat(16) begin
      @(posedge aclk);
      tdata <= i;
      i = i + 1;
      tvalid <= 1'b1;
    end
    @(posedge aclk);
    tdata <= 0;
    tvalid <= 1'b0;
  endtask

endinterface

`default_nettype wire
