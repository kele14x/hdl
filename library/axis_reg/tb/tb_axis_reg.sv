// File: tb_axi4l_ipif.sv
// Brief: Testbench for module axi4l_ipif
`timescale 1 ns / 100 ps
//
`default_nettype none

import uvm_pkg::*;
`include "uvm_macros.svh"

module tb_axis_reg;

  import axis_reg_test_list::*;

  parameter int HAS_TKEEP = 0;
  parameter int HAS_TLAST = 0;
  parameter int HAS_TREADY = 1;
  parameter int HAS_TSTRB = 0;
  parameter int TDATA_WIDTH = 8;
  parameter int TDEST_WIDTH = 0;
  parameter int TID_WIDTH = 0;
  parameter int TUSER_WIDTH = 0;

  bit aclk;
  bit aclken;
  bit aresetn;

  // Virtual interface
  axi4s_if #(
      .HAS_TKEEP  (HAS_TKEEP),
      .HAS_TLAST  (HAS_TLAST),
      .HAS_TREADY (HAS_TREADY),
      .HAS_TSTRB  (HAS_TSTRB),
      .TDATA_WIDTH(TDATA_WIDTH),
      .TDEST_WIDTH(TDEST_WIDTH),
      .TID_WIDTH  (TID_WIDTH),
      .TUSER_WIDTH(TUSER_WIDTH)
  ) mst_vif (
      .aclk   (aclk),
      .aclken (aclken),
      .aresetn(aresetn)
  );

  axi4s_if #(
      .HAS_TKEEP  (HAS_TKEEP),
      .HAS_TLAST  (HAS_TLAST),
      .HAS_TREADY (HAS_TREADY),
      .HAS_TSTRB  (HAS_TSTRB),
      .TDATA_WIDTH(TDATA_WIDTH),
      .TDEST_WIDTH(TDEST_WIDTH),
      .TID_WIDTH  (TID_WIDTH),
      .TUSER_WIDTH(TUSER_WIDTH)
  ) slv_vif (
      .aclk   (aclk),
      .aclken (aclken),
      .aresetn(aresetn)
  );

  // Connects the interface to DUT
  axis_reg #(
      .HAS_TKEEP  (HAS_TKEEP),
      .HAS_TLAST  (HAS_TLAST),
      .HAS_TREADY (HAS_TREADY),
      .HAS_TSTRB  (HAS_TSTRB),
      .TDATA_WIDTH(TDATA_WIDTH),
      .TDEST_WIDTH(TDEST_WIDTH),
      .TID_WIDTH  (TID_WIDTH),
      .TUSER_WIDTH(TUSER_WIDTH)
  ) DUT (
      .aclk          (aclk),
      .aclken        (aclken),
      .aresetn       (aresetn),
      //
      .s_axis_tdata  (mst_vif.tdata),
      .s_axis_tdest  (mst_vif.tdest),
      .s_axis_tid    (mst_vif.tid),
      .s_axis_tkeep  (mst_vif.tkeep),
      .s_axis_tlast  (mst_vif.tlast),
      .s_axis_tvalid (mst_vif.tvalid),
      .s_axis_tstrb  (mst_vif.tstrb),
      .s_axis_tuser  (mst_vif.tuser),
      .s_axis_tready (mst_vif.tready),
      // IP i/f
      //=======
      .m_axis_tdata  (slv_vif.tdata),
      .m_axis_tdest  (slv_vif.tdest),
      .m_axis_tid    (slv_vif.tid),
      .m_axis_tkeep  (slv_vif.tkeep),
      .m_axis_tlast  (slv_vif.tlast),
      .m_axis_tvalid (slv_vif.tvalid),
      .m_axis_tstrb  (slv_vif.tstrb),
      .m_axis_tuser  (slv_vif.tuser),
      .m_axis_tready (slv_vif.tready)
  );

  // Stimulation
  initial begin
    aclk = 0;
    forever begin
      #5 aclk = ~aclk;
    end
  end

  initial begin
    aclken = 1;
  end

  initial begin
    aresetn = 0;
    #100;
    aresetn = 1;
  end

  initial begin
    $display("********************");
    $display("Simulation started");
    // Register the interface in the UVM configuration block
    uvm_config_db#(virtual axi4s_if)::set(uvm_root::get(), "tb_axis_reg", "mst_vif", mst_vif);
    uvm_config_db#(virtual axi4s_if)::set(uvm_root::get(), "tb_axis_reg", "slv_vif", slv_vif);
    // Execute the test
    run_test();
  end

  final begin
    $display("********************");
    $display("%t, simulation ended.", $time());
  end

endmodule

`default_nettype wire
