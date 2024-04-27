`timescale 1 ns / 1 ps
//
`default_nettype none

import uvm_pkg::*;
`include "uvm_macros.svh"

`include "axi4s_if.sv"
`include "axi4s_agent.sv"
`include "axi4s_scoreboard.sv"
`include "ecpri_transaction.sv"


//
// Basic test sequence
//
class test_sequence extends uvm_sequence #(ecpri_concat_message);

  // Macro

  `uvm_object_utils(test_sequence)

  // Constructor

  function new(input string name = "unnamed_test_sequence");
    super.new(.name(name));
  endfunction : new

  // UVM

  virtual task body();
    repeat (100) begin
      `uvm_do(req)
    end
  endtask : body

endclass : test_sequence


//
// Test Reference Model
//
class test_ref_model extends uvm_component;

  // Fields

  uvm_analysis_imp #(axi4s_transaction, test_ref_model) analysis_export;  // in
  uvm_analysis_port #(ecpri_common_header)              analysis_header_port;  // out
  uvm_analysis_port #(axi4s_transaction)                analysis_payload_port;  // out
  // Macro

  `uvm_component_utils(test_ref_model)

  // Constructor

  function new(input string name = "unnamed_test_ref_model", input uvm_component parent = null);
    super.new(.name(name), .parent(parent));
  endfunction

  // UVM

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(.phase(phase));
    analysis_export       = new("analysis_export", this);
    analysis_header_port  = new("analysis_header_port", this);
    analysis_payload_port = new("analysis_payload_port", this);
  endfunction : build_phase

  // analysis_export implementation

  virtual function void write(axi4s_transaction item);
    ecpri_common_header        res;
    axi4s_transaction          payload;
    int                        i;
    bit                 [ 7:0] bytes         [];
    bit                 [ 3:0] version;
    bit                 [ 2:0] reserved;
    bit                        concatenation;
    bit                 [ 7:0] message_type;
    bit                 [15:0] payload_size;

    item.get_bytes(bytes);

    i = 0;
    while (i < bytes.size()) begin
      // Parse and build
      {version, reserved, concatenation, message_type, payload_size} = {
        bytes[i], bytes[i+1], bytes[i+2], bytes[i+3]
      };

      res = ecpri_common_header::type_id::create("res");
      res.version = version;
      res.reserved = reserved;
      res.concatenation = concatenation;
      res.message_type = message_type;
      res.payload_size = payload_size;
      analysis_header_port.write(res);

      payload = axi4s_transaction::type_id::create("payload");
      payload.set_size(payload_size);
      for (int c = 0; c < payload_size; c++) begin
        payload.set_byte(c, bytes[i+4+c]);
      end
      analysis_payload_port.write(payload);

      // Go next message
      i = i + 4 + ((payload_size + 3) / 4) * 4;
    end
  endfunction : write

endclass : test_ref_model


//
// Scoreboard
//
class test_scoreboard extends uvm_scoreboard;

  // Fields

  uvm_tlm_analysis_fifo #(ecpri_common_header) analysis_expect_fifo;
  uvm_tlm_analysis_fifo #(ecpri_common_header) analysis_actual_fifo;

  int collected_item = 0;
  int mismatched_item = 0;

  // Macro

  `uvm_component_utils(test_scoreboard)

  // Constructor

  function new(input string name = "unnamed_test_scoreboard", input uvm_component parent = null);
    super.new(.name(name), .parent(parent));
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(.phase(phase));
    analysis_expect_fifo = new("analysis_expect_fifo", this);
    analysis_actual_fifo = new("analysis_actual_fifo", this);
  endfunction : build_phase

  virtual task run_phase(uvm_phase phase);
    ecpri_common_header expected;
    ecpri_common_header actual;
    super.run_phase(.phase(phase));

    forever begin
      this.analysis_expect_fifo.get(expected);
      this.analysis_actual_fifo.get(actual);
      this.collected_item++;
      if (!expected.compare(actual)) begin
        this.mismatched_item++;
        `uvm_error("", "Expected result and actual result mismatch!")
        `uvm_info("", $sformatf("Expected: %s", expected.sprint()), UVM_LOW);
        `uvm_info("", $sformatf("Actual: %s", actual.sprint()), UVM_LOW);
      end
    end
  endtask : run_phase

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(.phase(phase));
    `uvm_info("", $sformatf("Collected eCPRI header item: %d", this.collected_item), UVM_LOW)
    `uvm_info("", $sformatf("Mismatched eCPRI header item: %d", this.mismatched_item), UVM_LOW)
  endfunction : report_phase

endclass : test_scoreboard


/**
 * eCPRI common header parse port
 */
interface ecpri_hdr_if (
    input var clk,
    input var rst
);

  bit        header_valid;
  bit        concat;
  bit [ 7:0] messagetype;
  bit [15:0] payloadsize;

endinterface : ecpri_hdr_if


//
// eCPRI common header parse port monitor
//
class test_monitor extends uvm_monitor;

  virtual ecpri_hdr_if vif;

  uvm_analysis_port #(ecpri_common_header) analysis_port;

  // Macro

  `uvm_component_utils(test_monitor)

  // Constructor

  function new(input string name = "unnamed_test_monitor", input uvm_component parent = null);
    super.new(.name(name), .parent(parent));
  endfunction : new

  virtual function void build_phase(input uvm_phase phase);
    super.build_phase(phase);
    analysis_port = new("analysis_port", this);
    if (!uvm_config_db#(virtual ecpri_hdr_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("", "Could not get handler to vif!")
    end
  endfunction : build_phase

  virtual task run_phase(uvm_phase phase);
    ecpri_common_header item;
    super.run_phase(.phase(phase));

    // Wait reset done
    wait (this.vif.rst == 1'b0);


    @(posedge this.vif.clk);
    forever begin
      if (this.vif.header_valid) begin
        item = ecpri_common_header::type_id::create("item");
        item.concatenation = vif.concat;
        item.message_type = vif.messagetype;
        item.payload_size = vif.payloadsize;
        analysis_port.write(item);
      end
      @(posedge this.vif.clk);
    end
  endtask : run_phase

endclass : test_monitor


//
// Test Environment
//
class test_env extends uvm_env;

  // Fields

  axi4s_agent      master_agent;
  axi4s_agent      slave_agent;
  test_monitor     monitor;
  test_ref_model   ref_model;
  test_scoreboard  header_scoreboard;
  axi4s_scoreboard payload_scoreboard;

  // Macro

  `uvm_component_utils(test_env)

  // Constructor

  function new(input string name = "unnamed_test_env", input uvm_component parent = null);
    super.new(.name(name), .parent(parent));
    uvm_config_int::set(this, "slave_agent", "is_active", UVM_PASSIVE);
  endfunction : new

  // UVM

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(.phase(phase));
    master_agent       = axi4s_agent::type_id::create("master_agent", this);
    slave_agent        = axi4s_agent::type_id::create("slave_agent", this);
    monitor            = test_monitor::type_id::create("monitor", this);
    ref_model          = test_ref_model::type_id::create("ref_model", this);
    header_scoreboard  = test_scoreboard::type_id::create("header_scoreboard", this);
    payload_scoreboard = axi4s_scoreboard::type_id::create("payload_scoreboard", this);
  endfunction : build_phase

  //
  // Master -> Reference Model -> Header Scoreboard
  //            Output Monitor -> Header Scoreboard
  function void connect_phase(uvm_phase phase);
    master_agent.monitor.analysis_port.connect(ref_model.analysis_export);
    // Header Checker
    monitor.analysis_port.connect(header_scoreboard.analysis_actual_fifo.analysis_export);
    ref_model.analysis_header_port.connect(header_scoreboard.analysis_expect_fifo.analysis_export);
    // Playload Checker
    slave_agent.monitor.analysis_port.connect(
        payload_scoreboard.analysis_actual_fifo.analysis_export);
    ref_model.analysis_payload_port.connect(
        payload_scoreboard.analysis_expect_fifo.analysis_export);
  endfunction : connect_phase

endclass : test_env


//
// Basic Test
//
class basic_test extends uvm_test;

  // Fields

  test_env             env;
  test_sequence        seq;

  virtual axi4s_if     slave_vif;
  virtual axi4s_if     master_vif;
  virtual ecpri_hdr_if hdr_vif;

  // Macro

  `uvm_component_utils(basic_test)

  // Constructor

  function new(input string name = "unnamed_basic_test", input uvm_component parent = null);
    super.new(.name(name), .parent(parent));
  endfunction : new

  // UVM

  virtual function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    uvm_top.print_topology();
  endfunction : end_of_elaboration_phase

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(.phase(phase));
    env = test_env::type_id::create("env", this);
    seq = test_sequence::type_id::create("seq", this);
  endfunction : build_phase

  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    seq.start(env.master_agent.sequencer);
    #100;
    phase.drop_objection(this);
  endtask : run_phase

endclass : basic_test


//
// Testbench
//
module tb_oran_deframer_eth_ecpri_common;

  //   signals
  //------------

  bit clk;
  bit rst;

  axi4s_if i_slave_axi4s_if (
      .aclk   (clk),
      .aclken (1'b1),
      .aresetn(~rst)
  );

  axi4s_if i_master_axi4s_if (
      .aclk   (clk),
      .aclken (1'b1),
      .aresetn(~rst)
  );

  ecpri_hdr_if i_ecpri_hdr_if (
      .clk(clk),
      .rst(rst)
  );

  logic        m_ecpri_header_valid;
  logic        m_ecpri_concat;
  logic [ 7:0] m_ecpri_messagetype;
  logic [15:0] m_ecpri_payloadsize;

  // Clocks
  //-------

  initial begin
    clk = 0;
    forever begin
      #(5) clk = ~clk;
    end
  end

  initial begin
    rst = 1;
    #100;
    @(posedge clk) rst <= 0;
  end


  // DUT
  //----

  oran_deframer_eth_ecpri_common DUT (
      // AXI
      //----
      .clk                 (clk),
      .rst                 (rst),
      // RX
      .s_axis_tdata        (i_slave_axi4s_if.tdata[63:0]),
      .s_axis_tkeep        (i_slave_axi4s_if.tkeep[7:0]),
      .s_axis_tlast        (i_slave_axi4s_if.tlast),
      .s_axis_tvalid       (i_slave_axi4s_if.tvalid),
      // TX
      .m_axis_tdata        (i_master_axi4s_if.tdata[63:0]),
      .m_axis_tkeep        (i_master_axi4s_if.tkeep[7:0]),
      .m_axis_tlast        (i_master_axi4s_if.tlast),
      .m_axis_tvalid       (i_master_axi4s_if.tvalid),
      .m_axis_tdest        (i_master_axi4s_if.tdest[1:0]),
      // DL
      .m_ecpri_header_valid(i_ecpri_hdr_if.header_valid),
      .m_ecpri_concat      (i_ecpri_hdr_if.concat),
      .m_ecpri_messagetype (i_ecpri_hdr_if.messagetype),
      .m_ecpri_payloadsize (i_ecpri_hdr_if.payloadsize)
  );


  // Tests
  //------

  initial begin
    axi4s_config cfg0;
    axi4s_config cfg1;
    `uvm_info("", "Simulation starts", UVM_LOW)

    cfg0 = axi4s_config::type_id::create("cfg0");
    cfg0.vif = i_slave_axi4s_if;
    cfg0.tdata_width = 64;
    cfg0.has_tready = 0;

    cfg1 = axi4s_config::type_id::create("cfg1");
    cfg1.vif = i_master_axi4s_if;
    cfg1.tdata_width = 64;
    cfg1.has_tready = 0;

    // Set IF to uvm_config_db
    uvm_config_db#(axi4s_config)::set(.cntxt(null),  //
                                              .inst_name("uvm_test_top.env.master_agent"),
                                              .field_name("cfg"), .value(cfg0));
    uvm_config_db#(axi4s_config)::set(.cntxt(null),  //
                                              .inst_name("uvm_test_top.env.slave_agent"),
                                              .field_name("cfg"), .value(cfg1));
    uvm_config_db#(virtual ecpri_hdr_if)::set(.cntxt(null),  //
                                              .inst_name("uvm_test_top.env.monitor"),
                                              .field_name("vif"), .value(i_ecpri_hdr_if));
    //
    run_test("basic_test");
    #1000;
    $finish;
  end

  final begin
    `uvm_info("", "Simulation ends", UVM_LOW)
  end

endmodule

`default_nettype wire
