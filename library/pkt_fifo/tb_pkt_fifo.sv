//-----------------------------------------------------------------------------
// File: tb_eth_if_pkt_filter.sv
// Brief: Testbench for module eth_if_pkt_filter
//-----------------------------------------------------------------------------
`timescale 1 ns / 1 ps `default_nettype none

module tb_eth_if_pkt_filter;

  import axi4stream_vip_pkg::*;
  import axi4stream_vip_mst_0_pkg::*;
  import axi4stream_vip_slv_0_pkg::*;

  parameter int ADDR_WIDTH = 12;

  axi4stream_vip_mst_0_mst_t mst_agent;
  axi4stream_vip_slv_0_slv_t slv_agent;

  axi4stream_transaction     wr_transaction;
  axi4stream_ready_gen       ready_gen;

  logic        aclk;
  logic        aresetn;
  //
  logic [63:0] s_axis_tdata;
  logic [ 7:0] s_axis_tkeep;
  logic        s_axis_tvalid;
  logic        s_axis_tlast;
  logic        s_axis_tready;
  //
  logic [63:0] m_axis_tdata;
  logic [ 7:0] m_axis_tkeep;
  logic        m_axis_tvalid;
  logic        m_axis_tlast;
  logic        m_axis_tready;

  initial begin
    forever begin
      #1 aclk = 0;
      #1 aclk = 1;
    end
  end

  initial begin
    aresetn = 0;
    repeat (16) @(posedge aclk);
    @(posedge aclk);
    aresetn <= 1;
  end


  initial begin
    $display("*** Simulation starts ***");

    mst_agent = new("master vip agent", i_mst.inst.IF);
    slv_agent = new("salve vip agent", i_slv.inst.IF);

    mst_agent.vif_proxy.set_dummy_drive_type(XIL_AXI4STREAM_VIF_DRIVE_NONE);
    slv_agent.vif_proxy.set_dummy_drive_type(XIL_AXI4STREAM_VIF_DRIVE_NONE);

    mst_agent.start_master();
    slv_agent.start_slave();

    wait(aresetn);

    fork
      begin
        for (int i = 0; i < 16; i++) begin
          wr_transaction = mst_agent.driver.create_transaction("write transcation");
          WR_TRANSACTION_FAIL: assert(wr_transaction.randomize());
          mst_agent.driver.send(wr_transaction);
        end
      end

      begin
        ready_gen = slv_agent.driver.create_ready("ready_gen");
        ready_gen.set_ready_policy(XIL_AXI4STREAM_READY_GEN_OSC);
        ready_gen.set_low_time(1);
        ready_gen.set_high_time(2);
        slv_agent.driver.send_tready(ready_gen);
      end
    join

    #1000;
    $display("*** Simulation ends ***");
    $finish();
  end

  axi4stream_vip_mst_0 i_mst (
      .aclk         (aclk),
      .aresetn      (aresetn),
      .m_axis_tdata (m_axis_tdata),
      .m_axis_tkeep (m_axis_tkeep),
      .m_axis_tlast (m_axis_tlast),
      .m_axis_tready(m_axis_tready),
      .m_axis_tuser (  /* open */),
      .m_axis_tvalid(m_axis_tvalid)
  );

  axi4stream_vip_slv_0 i_slv (
      .aclk         (aclk),
      .aresetn      (aresetn),
      .s_axis_tdata (s_axis_tdata),
      .s_axis_tkeep (s_axis_tkeep),
      .s_axis_tlast (s_axis_tlast),
      .s_axis_tready(s_axis_tready),
      .s_axis_tuser (1'b0),
      .s_axis_tvalid(s_axis_tvalid)
  );

  eth_if_pkt_filter #(
      .ADDR_WIDTH(ADDR_WIDTH)
  ) UUT (
      .aclk              (aclk),
      .aresetn           (aresetn),
      //
      .s_axis_tdata      (m_axis_tdata),
      .s_axis_tkeep      (m_axis_tkeep),
      .s_axis_tlast      (m_axis_tlast),
      .s_axis_tready     (m_axis_tready),
      .s_axis_tvalid     (m_axis_tvalid),
      // Sideband signal
      .s_mac_tuser       (1'b0),
      .s_mac_bad_fcs     (1'b0),
      .s_mac_tstamp_out  (80'b0),
      .s_mac_tstamp_valid(1'b0),
      // Output
      .m_axis_tdata      (s_axis_tdata),
      .m_axis_tkeep      (s_axis_tkeep),
      .m_axis_tlast      (s_axis_tlast),
      .m_axis_tready     (s_axis_tready),
      .m_axis_tvalid     (s_axis_tvalid),
      //
      .m_mac_tstamp_out  (  /* open */),
      .m_mac_tstamp_valid(  /* open */)
  );

endmodule

`default_nettype none
