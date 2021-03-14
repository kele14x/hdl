// File: axis_vip_master.sv
// Brief: AXI4-Stream Verification IP. This simulation only module is used to
//        act as AXI Stream master for test bench to drive active stimulus.

`timescale 1 ns / 1 ps `default_nettype none

module axis_vip_master #(
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
    input var                      aclk,
    input var                      aresetn,
    input var                      aclken,
    //
    output var [  TDATA_WIDTH-1:0] m_axis_tdata,
    output var [  TDEST_WIDTH-1:0] m_axis_tdest,
    output var [    TID_WIDTH-1:0] m_axis_tid,
    output var [TDATA_WIDTH/8-1:0] m_axis_tkeep,
    output var                     m_axis_tlast,
    output var                     m_axis_tvalid,
    output var [TDATA_WIDTH/8-1:0] m_axis_tstrb,
    output var [  TUSER_WIDTH-1:0] m_axis_tuser,
    input var                      m_axis_tready
);

  axis_if #(
      .TDATA_WIDTH(TDATA_WIDTH),
      .TUSER_WIDTH(TUSER_WIDTH),
      .TID_WIDTH  (TID_WIDTH),
      .TDEST_WIDTH(TDEST_WIDTH),
      .HAS_TREADY (HAS_TREADY),
      .HAS_TSTRB  (HAS_TSTRB),
      .HAS_TKEEP  (HAS_TKEEP),
      .HAS_TLAST  (HAS_TLAST),
      .HAS_ARESETN(HAS_ARESETN),
      .HAS_ACLKEN (HAS_ACLKEN)
  ) IF (
      .aclk   (aclk),
      .aresetn(aresetn),
      .aclken (aclken)
  );

  assign m_axis_tdata = IF.tdata;

  initial begin
    $display("Found axis_vip_master at: \"%m\"");
  end

endmodule

`default_nettype wire
