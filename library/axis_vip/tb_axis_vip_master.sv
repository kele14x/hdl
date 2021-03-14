`timescale 1 ns / 1 ps `default_nettype none

module tb_axis_vip_master ();

  parameter int TDATA_WIDTH = 32;
  parameter int TUSER_WIDTH = 0;
  parameter int TID_WIDTH = 0;
  parameter int TDEST_WIDTH = 0;
  parameter int HAS_TREADY = 1;
  parameter int HAS_TSTRB = 0;
  parameter int HAS_TKEEP = 0;
  parameter int HAS_TLAST = 0;
  parameter int HAS_ARESETN = 1;
  parameter int HAS_ACLKEN = 0;

  logic                     aclk;
  logic                     aresetn;
  logic                     aclken;
  //
  logic [  TDATA_WIDTH-1:0] m_axis_tdata;
  logic [  TDEST_WIDTH-1:0] m_axis_tdest;
  logic [    TID_WIDTH-1:0] m_axis_tid;
  logic [TDATA_WIDTH/8-1:0] m_axis_tkeep;
  logic                     m_axis_tlast;
  logic                     m_axis_tvalid;
  logic [TDATA_WIDTH/8-1:0] m_axis_tstrb;
  logic [  TUSER_WIDTH-1:0] m_axis_tuser;
  logic                     m_axis_tready;

  initial begin
    aclk = 1'b0;
    forever begin
      #5 aclk = ~aclk;
    end
  end

  initial begin
    aresetn = 1'b0;
    repeat (16) @(posedge aclk);
    @(posedge aclk) aresetn <= 1'b1;
  end

  axis_vip_master #(
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
  ) VIP_MASTER (
      .aclk         (aclk),
      .aresetn      (aresetn),
      .aclken       (aclken),
      .m_axis_tdata (m_axis_tdata),
      .m_axis_tdest (m_axis_tdest),
      .m_axis_tid   (m_axis_tid),
      .m_axis_tkeep (m_axis_tkeep),
      .m_axis_tlast (m_axis_tlast),
      .m_axis_tvalid(m_axis_tvalid),
      .m_axis_tstrb (m_axis_tstrb),
      .m_axis_tuser (m_axis_tuser),
      .m_axis_tready(m_axis_tready)
  );

   initial begin
       tb_axis_vip_master.VIP_MASTER.IF.send_frame();
       tb_axis_vip_master.VIP_MASTER.IF.send_frame();
   end

endmodule

`default_nettype wire
