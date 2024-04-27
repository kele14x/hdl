`timescale 1 ns / 1 ps
//
`default_nettype none

import uvm_pkg::*;
`include "uvm_macros.svh"

`include "axi4l_if.sv"
`include "axi4l_agent.sv"
`include "axi4l_transaction.sv"
`include "axi4s_if.sv"
`include "axi4s_agent.sv"
`include "oran_fh_transaction.sv"

`include "config_sequence.sv"
`include "oran_fh_20_1_sequence.sv"
`include "oran_fh_20_1_bfp_sequence.sv"
`include "oran_fh_20_2_bfp_sequence.sv"


//
// Test Environment
//
class test_env extends uvm_env;

  // Fields

  axi4l_agent cfg_agent;
  axi4s_agent tx_agent;

  // Macro

  `uvm_component_utils(test_env)

  // Constructor

  function new(input string name = "unnamed_test_env", input uvm_component parent = null);
    super.new(.name(name), .parent(parent));
    // uvm_config_int::set(this, "cfg_agent", "is_active", UVM_ACTIVE);
    // uvm_config_int::set(this, "tx_agent", "is_active", UVM_ACTIVE);
  endfunction : new

  // UVM

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(.phase(phase));
    cfg_agent = axi4l_agent::type_id::create("cfg_agent", this);
    tx_agent  = axi4s_agent::type_id::create("tx_agent", this);
  endfunction : build_phase

endclass : test_env


//
// Basic Test
//
class basic_test extends uvm_test;

  // Fields

  test_env              env;
  oran_fh_20_1_sequence tx_seq;
  config_sequence       cfg_seq;

  virtual axi4l_if      cfg_vif;
  virtual axi4s_if      tx_vif;

  // Macro

  `uvm_component_utils(basic_test)

  // Constructor

  function new(input string name = "unnamed_test", input uvm_component parent = null);
    super.new(.name(name), .parent(parent));
  endfunction : new

  // UVM

  virtual function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    uvm_top.print_topology();
  endfunction : end_of_elaboration_phase

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(.phase(phase));
    env     = test_env::type_id::create("env", this);
    cfg_seq = config_sequence::type_id::create("cfg_seq", this);
    tx_seq  = oran_fh_20_1_sequence::type_id::create("tx_seq", this);
  endfunction : build_phase

  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    cfg_seq.start(env.cfg_agent.sequencer);
    tx_seq.start(env.tx_agent.sequencer);
    #100;
    phase.drop_objection(this);
  endtask : run_phase

endclass : basic_test


//
// Testbench
//
module tb_oran_top;

  parameter int ANT_NUM = 2;


  // DUT signals
  //------------

  // AXI
  bit        s_axi_aclk;
  bit        s_axi_aresetn;
  // Eth
  bit        eth_clk;
  bit        eth_rst;
  // DFE
  bit        clk;
  bit        rst;

  // IRQ
  bit        interrupt;

  // Timer
  bit        timer_sync;

  bit [ 7:0] timer_frame;
  bit        timer_sof;
  bit        timer_sos;
  bit [32:0] timer_frac;

  // lowphy
  // DL
  bit [ 7:0] dl_syml_frame [ANT_NUM];
  bit        dl_syml_sof   [ANT_NUM];
  bit        dl_syml_sos   [ANT_NUM];
  bit [32:0] dl_syml_frac  [ANT_NUM];
  bit [31:0] dl_syml_data  [ANT_NUM];
  bit        dl_syml_valid [ANT_NUM];
  // UL
  bit [ 7:0] ul_syml_frame [ANT_NUM];
  bit        ul_syml_sof   [ANT_NUM];
  bit        ul_syml_sos   [ANT_NUM];
  bit [31:0] ul_syml_data  [ANT_NUM];
  bit        ul_syml_valid [ANT_NUM];

  axi4l_if i_axi4l_if (
      .aclk   (s_axi_aclk),
      .aclken (1'b1),
      .aresetn(s_axi_aresetn)
  );

  axi4s_if i_tx_axi4s_if (
      .aclk   (eth_clk),
      .aclken (1'b1),
      .aresetn(~eth_rst)
  );

  axi4s_if i_rx_axi4s_if (
      .aclk   (eth_clk),
      .aclken (1'b1),
      .aresetn(~eth_rst)
  );

  assign ul_syml_frame = dl_syml_frame;
  assign ul_syml_sof   = dl_syml_sof;
  assign ul_syml_sos   = dl_syml_sos;
  assign ul_syml_data  = dl_syml_data;
  assign ul_syml_valid = dl_syml_valid;

  // Clocks
  //-------

  initial begin
    clk = 0;
    forever begin
      //#(1.017) clk = ~clk;  // 491.52 MHz
      #(4.069) clk = ~clk;  // 122.88 MHz
    end
  end

  initial begin
    eth_clk = 0;
    forever begin
      //#(3.2) eth_clk = ~eth_clk;  // 156.25 MHz
      #(4) eth_clk = ~eth_clk;  // 125 MHz
    end
  end

  initial begin
    s_axi_aclk = 0;
    forever begin
      #(5) s_axi_aclk = ~s_axi_aclk;  // 100 MHz
    end
  end


  // Resets
  //-------

  initial begin
    rst = 1;
    #1000;
    @(posedge clk) rst <= 0;
  end

  initial begin
    eth_rst = 1;
    #1000;
    @(posedge eth_clk) eth_rst <= 0;
  end

  initial begin
    s_axi_aresetn = 0;
    #1000;
    @(posedge s_axi_aclk) s_axi_aresetn <= 1;
  end


  // 10ms
  //-----

  initial begin
    timer_sync = 1'b0;
    #1200;
    @(posedge clk) timer_sync = 1'b1;
    @(posedge clk) timer_sync = 1'b0;
  end


  // DUT
  //----

  symbol_timer #(
      .MODE     (0),
      .FREQUENCY(1)
  ) i_symbol_timer (
      .clk                  (clk),
      .rst                  (rst),
      //
      .sync                 (timer_sync),
      .sync_frame           ('0),
      //
      .start_of_frame       (timer_sof),
      .start_of_symbol      (timer_sos),
      //
      .current_sample       (  /* not used */),
      .current_symbol       (  /* not used */),
      .current_subframe_slot(  /* not used */),
      .current_frame        (timer_frame),
      //
      .shift                ('0)
  );

  oran_top #(
      .ANT_NUM(ANT_NUM)
  ) DUT (
      // AXI
      //----
      .s_axi_aclk    (s_axi_aclk),
      .s_axi_aresetn (s_axi_aresetn),
      //
      .s_axi_awaddr  (i_axi4l_if.awaddr[31:0]),
      .s_axi_awprot  (i_axi4l_if.awprot),
      .s_axi_awvalid (i_axi4l_if.awvalid),
      .s_axi_awready (i_axi4l_if.awready),
      //
      .s_axi_wdata   (i_axi4l_if.wdata[31:0]),
      .s_axi_wstrb   (i_axi4l_if.wstrb),
      .s_axi_wvalid  (i_axi4l_if.wvalid),
      .s_axi_wready  (i_axi4l_if.wready),
      //
      .s_axi_bresp   (i_axi4l_if.bresp),
      .s_axi_bvalid  (i_axi4l_if.bvalid),
      .s_axi_bready  (i_axi4l_if.bready),
      //
      .s_axi_araddr  (i_axi4l_if.araddr[31:0]),
      .s_axi_arprot  (i_axi4l_if.arprot),
      .s_axi_arvalid (i_axi4l_if.arvalid),
      .s_axi_arready (i_axi4l_if.arready),
      //
      .s_axi_rdata   (i_axi4l_if.rdata[31:0]),
      .s_axi_rresp   (i_axi4l_if.rresp),
      .s_axi_rvalid  (i_axi4l_if.rvalid),
      .s_axi_rready  (i_axi4l_if.rready),
      //
      .interrupt     (interrupt),
      // Ethernet
      //---------
      .eth_clk       (eth_clk),
      .eth_rst       (eth_rst),
      // RX
      .rx_axis_tdata (i_rx_axi4s_if.tdata[63:0]),
      .rx_axis_tkeep (i_rx_axi4s_if.tkeep[7:0]),
      .rx_axis_tvalid(i_rx_axi4s_if.tvalid),
      .rx_axis_tlast (i_rx_axi4s_if.tlast),
      .rx_axis_tuser (i_rx_axi4s_if.tuser[79:0]),
      // TX
      .tx_axis_tdata (i_tx_axi4s_if.tdata[63:0]),
      .tx_axis_tkeep (i_tx_axi4s_if.tkeep[7:0]),
      .tx_axis_tvalid(i_tx_axi4s_if.tvalid),
      .tx_axis_tlast (i_tx_axi4s_if.tlast),
      .tx_axis_tready(i_tx_axi4s_if.tready),
      // Lowphy
      //-------
      .clk           (clk),
      .rst           (rst),
      // Timer
      .timer_frame   (timer_frame),
      .timer_sof     (timer_sof),
      .timer_sos     (timer_sos),
      .timer_frac    (timer_frac),
      // DL
      .dl_syml_frame (dl_syml_frame),
      .dl_syml_sof   (dl_syml_sof),
      .dl_syml_sos   (dl_syml_sos),
      .dl_syml_frac  (dl_syml_frac),
      .dl_syml_data  (dl_syml_data),
      .dl_syml_valid (dl_syml_valid),
      // UL
      .ul_syml_frame (ul_syml_frame),
      .ul_syml_sof   (ul_syml_sof),
      .ul_syml_sos   (ul_syml_sos),
      .ul_syml_data  (ul_syml_data),
      .ul_syml_valid (ul_syml_valid)
  );


  // Tests
  //------

  initial begin
    axi4l_config cfg0;
    axi4s_config cfg1;
    `uvm_info("", "Simulation starts", UVM_LOW)

    cfg0 = axi4l_config::type_id::create("cfg0");
    cfg0.vif = i_axi4l_if;
    cfg0.addr_width = 32;
    cfg0.data_width = 32;

    cfg1 = axi4s_config::type_id::create("cfg1");
    cfg1.vif = i_rx_axi4s_if;
    cfg1.tdata_width = 64;
    cfg1.has_tready = 0;

    // Set IF to uvm_config_db
    uvm_config_db#(axi4l_config)::set(.cntxt(null),  //
                                      .inst_name("uvm_test_top.env.cfg_agent"), .field_name("cfg"),
                                      .value(cfg0));
    uvm_config_db#(axi4s_config)::set(.cntxt(null),  //
                                      .inst_name("uvm_test_top.env.tx_agent"), .field_name("cfg"),
                                      .value(cfg1));
    run_test("basic_test");
    #1000;
    $finish;
  end

  final begin
    `uvm_info("", "Simulation ends", UVM_LOW)
  end

endmodule

`default_nettype wire
