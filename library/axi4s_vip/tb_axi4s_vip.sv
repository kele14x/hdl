`timescale 1 ns / 1 ps `default_nettype none

module tb_axi4s_vip ();

  parameter int HAS_ACLKEN = 0;
  parameter int HAS_ARESETN = 1;
  parameter int HAS_TKEEP = 0;
  parameter int HAS_TLAST = 0;
  parameter int HAS_TREADY = 1;
  parameter int HAS_TSTRB = 0;
  parameter int TDATA_WIDTH = 32;
  parameter int TDEST_WIDTH = 0;
  parameter int TID_WIDTH = 0;
  parameter int TUSER_WIDTH = 0;

  logic                                                                  aclk;
  logic                                                                  aclken;
  logic                                                                  aresetn;
  //
  logic [                    (TDATA_WIDTH == 0 ? 0 : (TDATA_WIDTH-1)):0] s_axis_tdata;
  logic [                    (TDEST_WIDTH == 0 ? 0 : (TDEST_WIDTH-1)):0] s_axis_tdest;
  logic [                        (TID_WIDTH == 0 ? 0 : (TID_WIDTH-1)):0] s_axis_tid;
  logic [(TDATA_WIDTH == 0 || HAS_TKEEP == 0 ? 0 : (TDATA_WIDTH/8-1)):0] s_axis_tkeep;
  logic                                                                  s_axis_tlast;
  logic                                                                  s_axis_tvalid;
  logic [(TDATA_WIDTH == 0 || HAS_TSTRB == 0 ? 0 : (TDATA_WIDTH/8-1)):0] s_axis_tstrb;
  logic [                    (TUSER_WIDTH == 0 ? 0 : (TUSER_WIDTH-1)):0] s_axis_tuser;
  logic                                                                  s_axis_tready;
  //
  logic [                    (TDATA_WIDTH == 0 ? 0 : (TDATA_WIDTH-1)):0] m_axis_tdata;
  logic [                    (TDEST_WIDTH == 0 ? 0 : (TDEST_WIDTH-1)):0] m_axis_tdest;
  logic [                        (TID_WIDTH == 0 ? 0 : (TID_WIDTH-1)):0] m_axis_tid;
  logic [(TDATA_WIDTH == 0 || HAS_TKEEP == 0 ? 0 : (TDATA_WIDTH/8-1)):0] m_axis_tkeep;
  logic                                                                  m_axis_tlast;
  logic                                                                  m_axis_tvalid;
  logic [(TDATA_WIDTH == 0 || HAS_TSTRB == 0 ? 0 : (TDATA_WIDTH/8-1)):0] m_axis_tstrb;
  logic [                    (TUSER_WIDTH == 0 ? 0 : (TUSER_WIDTH-1)):0] m_axis_tuser;
  logic                                                                  m_axis_tready;

  axi4s_vip #(
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
  ) DUT (
      .*
  );

  // Simulation
  //===========

  logic [TDATA_WIDTH-1:0] data[100];

  initial begin
    for (int i = 0; i < 100; i++) begin
      data[i] = i + 100;
    end
  end

  initial begin
    aclk = 1'b0;
    forever begin
      #5 aclk = ~aclk;
    end
  end

  initial begin
    aclken = 1;
  end

  initial begin
    aresetn = 1'b0;
    repeat (16) @(posedge aclk);
    aresetn <= 1'b1;
  end

  initial begin
    tb_axi4s_vip.DUT.set_master_mode();
    tb_axi4s_vip.DUT.IF.reset();
    wait(aresetn);
    #100;
    tb_axi4s_vip.DUT.IF.master_send(100, data);
    #1000;
    $finish();
  end

endmodule

`default_nettype wire
