// File: axis_vip_master.sv
// Brief: AXI4-Stream Verification IP. This simulation only module is used to
//        act as AXI Stream master for test bench to drive active stimulus.

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
    input var                                                                   aclk,
    input var                                                                   aclken,
    input var                                                                   aresetn,
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

  // Slave Side Connection
  //----------------------

  assign IF.tdata = s_axis_tdata;
  assign IF.tdest = s_axis_tdest;
  assign IF.tid = s_axis_tid;
  assign IF.tkeep = s_axis_tkeep;
  assign IF.tlast = s_axis_tlast;
  assign IF.tvalid = s_axis_tvalid;
  assign IF.tstrb = s_axis_tstrb;
  assign IF.tuser = s_axis_tuser;
  assign s_axis_tready = IF.tready;

  // Master Side Connection
  //-----------------------

  assign m_axis_tdata = IF.tdata;
  assign m_axis_tdest = IF.tdest;
  assign m_axis_tid = IF.tid;
  assign m_axis_tkeep = IF.tkeep;
  assign m_axis_tlast = IF.tlast;
  assign m_axis_tvalid = IF.tvalid;
  assign m_axis_tstrb = IF.tstrb;
  assign m_axis_tuser = IF.tuser;
  assign IF.tready = m_axis_tready;

  initial begin
    $display("Found axi4s_vip at: \"%m\"");
  end

endmodule

`default_nettype wire
