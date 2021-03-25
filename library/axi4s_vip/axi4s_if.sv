// File: axis_if.sv
// Brief: AXI4-Stream interface definition.
`timescale 1 ns / 1 ps `default_nettype none

interface axi4s_if #(
    parameter int HAS_ACLKEN  = 0,
    parameter int HAS_ARESETN = 1,
    parameter int HAS_TKEEP   = 0,
    parameter int HAS_TLAST   = 0,
    parameter int HAS_TREADY  = 1,
    parameter int HAS_TSTRB   = 0,
    parameter int HAS_TVALID  = 1,
    parameter int TDATA_WIDTH = 32,
    parameter int TDEST_WIDTH = 0,
    parameter int TID_WIDTH   = 0,
    parameter int TUSER_WIDTH = 0
) (
    input tri aclk,
    input tri aclken,
    input tri aresetn
);

  // Blow signals are declared as tri, since multiply driver is need to solve
  // the mux.
  tri [                    (TDATA_WIDTH == 0 ? 0 : (TDATA_WIDTH-1)):0] tdata;
  tri [                    (TDEST_WIDTH == 0 ? 0 : (TDEST_WIDTH-1)):0] tdest;
  tri [                        (TID_WIDTH == 0 ? 0 : (TID_WIDTH-1)):0] tid;
  tri [(TDATA_WIDTH == 0 || HAS_TKEEP == 0 ? 0 : (TDATA_WIDTH/8-1)):0] tkeep;
  tri                                                                  tlast;
  tri                                                                  tvalid;
  tri [(TDATA_WIDTH == 0 || HAS_TSTRB == 0 ? 0 : (TDATA_WIDTH/8-1)):0] tstrb;
  tri [                    (TUSER_WIDTH == 0 ? 0 : (TUSER_WIDTH-1)):0] tuser;
  tri                                                                  tready;

  modport master(
      input aclk, aresetn, aclken, tready,
      output tdata, tdest, tid, tkeep, tlast, tvalid, tstrb, tuser
  );

  modport slave(
      input aclk, aresetn, aclken, tdata, tdest, tid, tkeep, tlast, tvalid, tstrb, tuser,
      output tready
  );

  modport monitor(
      input aclk, aresetn, aclken, tdata, tdest, tid, tkeep, tlast, tvalid, tstrb, tuser, tready
  );

endinterface

`default_nettype wire
