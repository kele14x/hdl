// File: axis_mst_agent.sv
// Brief: AXI4-Stream Master UVM Agent

`ifndef AXIS_MST_AGENT
`define AXIS_MST_AGENT

import uvm_pkg::*;
`include "uvm_macros.svh"

class axis_mst_agent extends uvm_agent;
  `uvm_component_utils(axis_mst_agent)

  virtual axi4s_if vif;

  // Components
  axis_mst_driver    driver;
  axis_mst_sequencer sequencer;
  axis_monitor       monitor;

  function new(string name = "axis_mst_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    driver    = axis_mst_driver::type_id::create("driver", this);
    sequencer = axis_mst_sequencer::type_id::create("sequencer", this);
    monitor   = axis_monitor::type_id::create("monitor", this);

    if (!uvm_config_db#(virtual axi4s_if)::get(this, "", "mst_vif", vif)) begin
      `uvm_fatal(get_full_name(), $sformatf("vif not found"));
    end
    driver.set_vif(vif);
    monitor.set_vif(vif);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    driver.seq_item_port.connect(sequencer.seq_item_export);
  endfunction

endclass

`endif
