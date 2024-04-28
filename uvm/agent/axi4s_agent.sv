`ifndef __AXI4S_AGENT__
`define __AXI4S_AGENT__

`timescale 1 ns / 1 ps
//
`default_nettype none

import uvm_pkg::*;
`include "uvm_macros.svh"

`include "axi4s_config.sv"
`include "axi4s_master_driver.sv"
`include "axi4s_monitor.sv"
`include "axi4s_sequencer.sv"


class axi4s_agent extends uvm_agent;

  // Fields

  axi4s_config        cfg;

  axi4s_master_driver driver;
  axi4s_sequencer     sequencer;
  axi4s_monitor       monitor;

  // Macro

  `uvm_component_utils(axi4s_agent)

  // Constructor

  function new(input string name = "unnamed_axi4s_agent", input uvm_component parent = null);
    super.new(.name(name), .parent(parent));
  endfunction : new

  // UVM

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(.phase(phase));

    if (!uvm_config_db#(axi4s_config)::get(this, "", "cfg", cfg)) begin
      `uvm_fatal("", "Could not get config object")
    end
    if (this.cfg == null) begin
      `uvm_fatal("", "Config object is NULL")
    end

    if (this.get_is_active()) begin
      // Active (master or slave) agent
      driver     = axi4s_master_driver::type_id::create("driver", this);
      driver.cfg = this.cfg;
      sequencer  = axi4s_sequencer::type_id::create("sequencer", this);
    end
    // Passive monitor
    monitor     = axi4s_monitor::type_id::create("monitor", this);
    monitor.cfg = this.cfg;
  endfunction : build_phase

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(.phase(phase));
    if (this.get_is_active()) begin
      driver.seq_item_port.connect(sequencer.seq_item_export);
    end
  endfunction : connect_phase

endclass : axi4s_agent

`default_nettype wire

`endif
