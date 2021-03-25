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
  tri  [                    (TDATA_WIDTH == 0 ? 0 : (TDATA_WIDTH-1)):0] tdata;
  tri  [                    (TDEST_WIDTH == 0 ? 0 : (TDEST_WIDTH-1)):0] tdest;
  tri  [                        (TID_WIDTH == 0 ? 0 : (TID_WIDTH-1)):0] tid;
  tri  [(TDATA_WIDTH == 0 || HAS_TKEEP == 0 ? 0 : (TDATA_WIDTH/8-1)):0] tkeep;
  tri                                                                   tlast;
  tri                                                                   tvalid;
  tri  [(TDATA_WIDTH == 0 || HAS_TSTRB == 0 ? 0 : (TDATA_WIDTH/8-1)):0] tstrb;
  tri  [                    (TUSER_WIDTH == 0 ? 0 : (TUSER_WIDTH-1)):0] tuser;
  tri                                                                   tready;

  modport master(
      input aclk, aresetn, aclken, tready,
      output tdata, tdest, tid, tkeep, tlast, tvalid, tstrb, tuser
  );

  modport slave(
      input aclk, aresetn, aclken, tdata, tdest, tid, tkeep, tlast, tvalid, tstrb, tuser,
      output tready
  );

  // Interface internal signals
  // SystemVerilog seems does not provide way to make it "private"

  localparam int MaxWait = 100;

  logic intf_is_master = 0;
  logic intf_is_slave = 0;

  logic [                    (TDATA_WIDTH == 0 ? 0 : (TDATA_WIDTH-1)):0]  tdata_s;
  logic [                    (TDEST_WIDTH == 0 ? 0 : (TDEST_WIDTH-1)):0]  tdest_s;
  logic [                        (TID_WIDTH == 0 ? 0 : (TID_WIDTH-1)):0]  tid_s;
  logic [(TDATA_WIDTH == 0 || HAS_TKEEP == 0 ? 0 : (TDATA_WIDTH/8-1)):0]  tkeep_s;
  logic                                                                   tlast_s;
  logic                                                                   tvalid_s;
  logic [(TDATA_WIDTH == 0 || HAS_TSTRB == 0 ? 0 : (TDATA_WIDTH/8-1)):0]  tstrb_s;
  logic [                    (TUSER_WIDTH == 0 ? 0 : (TUSER_WIDTH-1)):0]  tuser_s;
  logic                                                                   tready_s;

  assign tdata  = intf_is_master ? tdata_s : 'z;
  assign tdest  = intf_is_master ? tdest_s : 'z;
  assign tid    = intf_is_master ? tid_s : 'z;
  assign tkeep  = intf_is_master ? tkeep_s : 'z;
  assign tlast  = intf_is_master ? tlast_s : 'z;
  assign tvalid = intf_is_master ? tvalid_s : 'z;
  assign tstrb  = intf_is_master ? tstrb_s : 'z;
  assign tuser  = intf_is_master ? tuser_s : 'z;
  assign tready = intf_is_slave  ? tready_s : 'z;

  // Set the interface to master mode
  function automatic void intf_set_master();
    intf_is_master = 1;
    intf_is_slave = 0;
  endfunction

  // Set the interface to slave mode
  function automatic void intf_set_slave();
    intf_is_master = 0;
    intf_is_slave = 1;
  endfunction

  // Set the interface to monitor mode
  function automatic void intf_set_monitor();
    intf_is_master = 0;
    intf_is_slave = 0;
  endfunction

  task automatic reset();
    tdata_s <= '0;
    tdest_s <= '0;
    tid_s <= '0;
    tkeep_s <= '0;
    tlast_s <= '0;
    tvalid_s <= '0;
    tstrb_s <= '0;
    tuser_s <= '0;
    tready_s <= '0;
  endtask

  task automatic master_send(input int cnt, input logic [TDATA_WIDTH-1:0] data[]);
    $info("Call of master_send()");
    wait(aresetn);

    for (int i = 0; i < cnt; i++) begin
      @(posedge aclk);
      while(i != 0 && tready == 0) begin
        @(posedge aclk);
      end
      tdata_s <= data[i];
      tvalid_s <= 1'b1;
    end
    @(posedge aclk);
    reset();
  endtask

endinterface

`default_nettype wire
