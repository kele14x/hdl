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
  logic [                    (TDATA_WIDTH == 0 ? 0 : (TDATA_WIDTH-1)):0] tdata;
  logic [                    (TDEST_WIDTH == 0 ? 0 : (TDEST_WIDTH-1)):0] tdest;
  logic [                        (TID_WIDTH == 0 ? 0 : (TID_WIDTH-1)):0] tid;
  logic [(TDATA_WIDTH == 0 || HAS_TKEEP == 0 ? 0 : (TDATA_WIDTH/8-1)):0] tkeep;
  logic                                                                  tlast;
  logic                                                                  tvalid;
  logic [(TDATA_WIDTH == 0 || HAS_TSTRB == 0 ? 0 : (TDATA_WIDTH/8-1)):0] tstrb;
  logic [                    (TUSER_WIDTH == 0 ? 0 : (TUSER_WIDTH-1)):0] tuser;
  logic                                                                  tready;

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


  task automatic reset();
    tdata <= '0;
    tdest <= '0;
    tid <= '0;
    tkeep <= '0;
    tlast <= '0;
    tvalid <= '0;
    tstrb <= '0;
    tuser <= '0;
    tready <= '0;
  endtask

  task automatic master_send(input int cnt, input logic [TDATA_WIDTH-1:0] data[]);
    $info("Call of master_send()");
    wait(aresetn);

    for (int i = 0; i < cnt; i++) begin
      @(posedge aclk);
      while (i != 0 && IF.tready == 0) begin
        @(posedge aclk);
      end
      tdata  <= data[i];
      tvalid <= 1'b1;
    end
    @(posedge aclk);
    reset();
  endtask

endinterface

`default_nettype wire
