// File: axis_vip_master.sv
// Brief: AXI4-Stream Verification IP. This module can be configure as AXI4
//        Stream master (source) or slave (sink) during simulation. It provides
//        some simulation only function to actively drive stimulation or check
//        the protocol.
`timescale 1 ns / 1 ps `default_nettype none

module axi4s_vip #(
    parameter logic [1:0] INIT_MODE = 3,
    parameter int HAS_ACLKEN = 0,
    parameter int HAS_ARESETN = 1,
    parameter int HAS_TKEEP = 0,
    parameter int HAS_TLAST = 0,
    parameter int HAS_TREADY = 1,
    parameter int HAS_TSTRB = 0,
    parameter int TDATA_WIDTH = 32,
    parameter int TDEST_WIDTH = 0,
    parameter int TID_WIDTH = 0,
    parameter int TUSER_WIDTH = 0
) (
    input tri                                                                   aclk,
    input tri                                                                   aclken,
    input tri                                                                   aresetn,
    // Slave Side Interface
    //---------------------
    input tri  [                    (TDATA_WIDTH == 0 ? 0 : (TDATA_WIDTH-1)):0] s_axis_tdata,
    input tri  [                    (TDEST_WIDTH == 0 ? 0 : (TDEST_WIDTH-1)):0] s_axis_tdest,
    input tri  [                        (TID_WIDTH == 0 ? 0 : (TID_WIDTH-1)):0] s_axis_tid,
    input tri  [(TDATA_WIDTH == 0 || HAS_TKEEP == 0 ? 0 : (TDATA_WIDTH/8-1)):0] s_axis_tkeep,
    input tri                                                                   s_axis_tlast,
    input tri                                                                   s_axis_tvalid,
    input tri  [(TDATA_WIDTH == 0 || HAS_TSTRB == 0 ? 0 : (TDATA_WIDTH/8-1)):0] s_axis_tstrb,
    input tri  [                    (TUSER_WIDTH == 0 ? 0 : (TUSER_WIDTH-1)):0] s_axis_tuser,
    output tri                                                                  s_axis_tready,
    // Master Side Interface
    //----------------------
    output tri [                    (TDATA_WIDTH == 0 ? 0 : (TDATA_WIDTH-1)):0] m_axis_tdata,
    output tri [                    (TDEST_WIDTH == 0 ? 0 : (TDEST_WIDTH-1)):0] m_axis_tdest,
    output tri [                        (TID_WIDTH == 0 ? 0 : (TID_WIDTH-1)):0] m_axis_tid,
    output tri [(TDATA_WIDTH == 0 || HAS_TKEEP == 0 ? 0 : (TDATA_WIDTH/8-1)):0] m_axis_tkeep,
    output tri                                                                  m_axis_tlast,
    output tri                                                                  m_axis_tvalid,
    output tri [(TDATA_WIDTH == 0 || HAS_TSTRB == 0 ? 0 : (TDATA_WIDTH/8-1)):0] m_axis_tstrb,
    output tri [                    (TUSER_WIDTH == 0 ? 0 : (TUSER_WIDTH-1)):0] m_axis_tuser,
    input tri                                                                   m_axis_tready
);

  axi4s_if #(
      .HAS_ACLKEN (HAS_ACLKEN),
      .HAS_ARESETN(HAS_ARESETN),
      .HAS_TKEEP  (HAS_TKEEP),
      .HAS_TLAST  (HAS_TLAST),
      .HAS_TREADY (HAS_TREADY),
      .HAS_TSTRB  (HAS_TSTRB),
      .TDATA_WIDTH(TDATA_WIDTH),
      .TDEST_WIDTH(TDEST_WIDTH),
      .TID_WIDTH  (TID_WIDTH),
      .TUSER_WIDTH(TUSER_WIDTH)
  ) IF (
      .aclk   (aclk),
      .aclken (aclken),
      .aresetn(aresetn)
  );

  // Monitor mode = is_master && is_slave
  logic is_master = INIT_MODE[0];
  logic is_slave = INIT_MODE[1];

  // Slave Side Connection
  //----------------------

  assign IF.tdata = is_slave ? s_axis_tdata : 'z;
  assign IF.tdest = is_slave ? s_axis_tdest : 'z;
  assign IF.tid = is_slave ? s_axis_tid : 'z;
  assign IF.tkeep = is_slave ? s_axis_tkeep : 'z;
  assign IF.tlast = is_slave ? s_axis_tlast : 'z;
  assign IF.tvalid = is_slave ? s_axis_tvalid : 'z;
  assign IF.tstrb = is_slave ? s_axis_tstrb : 'z;
  assign IF.tuser = is_slave ? s_axis_tuser : 'z;
  assign s_axis_tready = is_slave ? IF.tready : 1'b1;

  // Master Side Connection
  //-----------------------

  assign m_axis_tdata = is_master ? IF.tdata : '0;
  assign m_axis_tdest = is_master ? IF.tdest : '0;
  assign m_axis_tid = is_master ? IF.tid : '0;
  assign m_axis_tkeep = is_master ? IF.tkeep : '0;
  assign m_axis_tlast = is_master ? IF.tlast : '0;
  assign m_axis_tvalid = is_master ? IF.tvalid : '0;
  assign m_axis_tstrb = is_master ? IF.tstrb : '0;
  assign m_axis_tuser = is_master ? IF.tuser : '0;
  assign IF.tready = is_master ? m_axis_tready : 'z;

 // synthesis translate_off

  initial begin
    $display("Found axi4s_vip at: \"%m\"");
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
