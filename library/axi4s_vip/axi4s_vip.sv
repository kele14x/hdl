// File: axis_vip_master.sv
// Brief: AXI4-Stream Verification IP. This module can be configure as AXI4
//        Stream master (source) or slave (sink) during simulation. It provides
//        some simulation only function to actively drive stimulation or check
//        the protocol.
`timescale 1 ns / 1 ps `default_nettype none

module axi4s_vip #(
    parameter int HAS_ACLKEN  = 0,
    parameter int HAS_ARESETN = 1,
    parameter int HAS_TKEEP   = 0,
    parameter int HAS_TLAST   = 0,
    parameter int HAS_TREADY  = 1,
    parameter int HAS_TSTRB   = 0,
    parameter int TDATA_WIDTH = 32,
    parameter int TDEST_WIDTH = 0,
    parameter int TID_WIDTH   = 0,
    parameter int TUSER_WIDTH = 0
) (
    input var      aclk,
    input var      aclken,
    input var      aresetn,
    // Slave Side Interface
    //---------------------
    axi4s_if.slave s_axis,
    // Master Side Interface
    //----------------------
    axi4s_if.master m_axis
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
  ) mvip_if (
      .aclk   (aclk),
      .aclken (aclken),
      .aresetn(aresetn)
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
  ) svip_if (
      .aclk   (aclk),
      .aclken (aclken),
      .aresetn(aresetn)
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
  ) pc_if (
      .aclk   (aclk),
      .aclken (aclken),
      .aresetn(aresetn)
  );

  localparam int MaxWait = 100;

  // Monitor mode = is_master && is_slave
  logic                                                                  is_master = 1;
  logic                                                                  is_slave = 1;

  // Slave Side Connection
  //----------------------

  assign pc_if.tdata = is_slave ? s_axis.tdata : mvip_if.tdata;
  assign pc_if.tdest = is_slave ? s_axis.tdest : mvip_if.tdest;
  assign pc_if.tid = is_slave ? s_axis.tid : mvip_if.tid;
  assign pc_if.tkeep = is_slave ? s_axis.tkeep : mvip_if.tkeep;
  assign pc_if.tlast = is_slave ? s_axis.tlast : mvip_if.tlast;
  assign pc_if.tvalid = is_slave ? s_axis.tvalid : mvip_if.tvalid;
  assign pc_if.tstrb = is_slave ? s_axis.tstrb : mvip_if.tstrb;
  assign pc_if.tuser = is_slave ? s_axis.tuser : mvip_if.tuser;
  assign s_axis.tready = is_slave ? pc_if.tready : 1'b1;

  // Master Side Connection
  //-----------------------

  assign m_axis.tdata = is_master ? pc_if.tdata : '0;
  assign m_axis.tdest = is_master ? pc_if.tdest : '0;
  assign m_axis.tid = is_master ? pc_if.tid : '0;
  assign m_axis.tkeep = is_master ? pc_if.tkeep : '0;
  assign m_axis.tlast = is_master ? pc_if.tlast : '0;
  assign m_axis.tvalid = is_master ? pc_if.tvalid : '0;
  assign m_axis.tstrb = is_master ? pc_if.tstrb : '0;
  assign m_axis.tuser = is_master ? pc_if.tuser : '0;
  assign pc_if.tready = is_master ? m_axis.tready : svip_if.tready;

  axi4s_vip_master source (
      .ifa(mvip_if)
  );

  axi4s_vip_slave sink (
      .ifa(svip_if)
  );

  axi4s_vip_pc pc (
      .ifa(pc_if)
  );

  initial begin
    $display("Found axi4s_vip at: \"%m\"");
  end

  // Set the interface to master mode
  function automatic void set_master_mode();
    is_master = 1;
    is_slave  = 0;
  endfunction

  // Set the interface to slave mode
  function automatic void set_slave_mode();
    is_master = 0;
    is_slave  = 1;
  endfunction

  // Set the interface to monitor mode
  function automatic void set_monitor_mode();
    is_master = 1;
    is_slave  = 1;
  endfunction

  // Set the interface to autistic  mode
  function automatic void set_autistic_mode();
    is_master = 0;
    is_slave  = 0;
  endfunction

endmodule

module axi4s_vip_master #(
    parameter int HAS_ACLKEN  = 0,
    parameter int HAS_ARESETN = 1,
    parameter int HAS_TKEEP   = 0,
    parameter int HAS_TLAST   = 0,
    parameter int HAS_TREADY  = 1,
    parameter int HAS_TSTRB   = 0,
    parameter int TDATA_WIDTH = 32,
    parameter int TDEST_WIDTH = 0,
    parameter int TID_WIDTH   = 0,
    parameter int TUSER_WIDTH = 0
) (
  axi4s_if.master ifa
);

endmodule

module axi4s_vip_slave #(
    parameter int HAS_ACLKEN  = 0,
    parameter int HAS_ARESETN = 1,
    parameter int HAS_TKEEP   = 0,
    parameter int HAS_TLAST   = 0,
    parameter int HAS_TREADY  = 1,
    parameter int HAS_TSTRB   = 0,
    parameter int TDATA_WIDTH = 32,
    parameter int TDEST_WIDTH = 0,
    parameter int TID_WIDTH   = 0,
    parameter int TUSER_WIDTH = 0
) (
  axi4s_if.slave ifa
);

endmodule

module axi4s_vip_pc #(
    parameter int HAS_ACLKEN  = 0,
    parameter int HAS_ARESETN = 1,
    parameter int HAS_TKEEP   = 0,
    parameter int HAS_TLAST   = 0,
    parameter int HAS_TREADY  = 1,
    parameter int HAS_TSTRB   = 0,
    parameter int TDATA_WIDTH = 32,
    parameter int TDEST_WIDTH = 0,
    parameter int TID_WIDTH   = 0,
    parameter int TUSER_WIDTH = 0
) (
  axi4s_if.monitor ifa
);

endmodule

`default_nettype wire
