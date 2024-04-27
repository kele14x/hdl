`ifndef __AXI4L_AGENT__
`define __AXI4L_AGENT__

`timescale 1 ns / 1 ps
//
`default_nettype none

import uvm_pkg::*;
`include "uvm_macros.svh"

`include "axi4l_config.sv"
`include "axi4l_master_driver.sv"
`include "axi4l_monitor.sv"
`include "axi4l_sequencer.sv"


class axi4l_agent extends uvm_agent;

  // Fields

  axi4l_config        cfg;

  axi4l_master_driver driver;
  axi4l_sequencer     sequencer;
  axi4l_monitor       monitor;

  // Macro

  `uvm_component_utils(axi4l_agent)

  // Constructor

  function new(input string name = "unnamed_axi4l_agent", input uvm_component parent = null);
    super.new(.name(name), .parent(parent));
  endfunction : new

  // UVM

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(.phase(phase));

    if (!uvm_config_db#(axi4l_config)::get(this, "", "cfg", cfg)) begin
      `uvm_fatal("", "Could not get config object")
    end
    if (this.cfg == null) begin
      `uvm_fatal("", "Config object is NULL")
    end

    if (this.get_is_active()) begin
      // Active (master or slave) agent
      driver = axi4l_master_driver::type_id::create("driver", this);
      driver.cfg = this.cfg;
      sequencer = axi4l_sequencer::type_id::create("sequencer", this);
    end
    // Passive monitor
    monitor     = axi4l_monitor::type_id::create("monitor", this);
    monitor.cfg = this.cfg;
  endfunction : build_phase

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(.phase(phase));
    if (this.get_is_active()) begin
      driver.seq_item_port.connect(sequencer.seq_item_export);
    end
  endfunction : connect_phase

endclass : axi4l_agent

`default_nettype wire

`endif
