// File: axis_monitor.sv
// Brief: AXI4-Stream UVM Monitor

`ifndef AXIS_MONITOR
`define AXIS_MONITOR

import uvm_pkg::*;
`include "uvm_macros.svh"

class axis_monitor extends uvm_monitor;
  `uvm_component_utils(axis_monitor)

  uvm_analysis_port #(axis_transaction) mon2sb_port;

  axis_transaction trans;

  virtual axis_if vif;

  // Constructor
  function new(string name = "axis_monitor", uvm_component parent = null);
    super.new(name, parent);
    mon2sb_port = new("mon2sb_port", this);
    trans = new("trans");
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(axis_if)::get(this, "axis_monitor", "vif", vif)) begin
      `uvm_fatal(get_full_name(), $sformatf("vif not found"));
    end
  endfunction

  task run_phase(uvm_phase phase);
    wait (vif.aresetn == 1'b1 || !HAS_ARESETN);
    forever begin
      @(vif.aclk);
      if (vif.tvalid && vif.tready && (!HAS_ACLKEN || vif.aclken)) begin
        trans.tdata = vif.tdata;
        trans.tdest = vif.tdest;
        trans.tid   = vif.tid;
        trans.tkeep = vif.tkeep;
        trans.tlast = vif.tlast;
        trans.tstrb = vif.tstrb;
        trans.tuser = vif.tuser;
        mon2sb_port.write(trans);
      end
    end
  endtask

  function void set_vif(axis_if vif);
    this.vif = vif;
  endfunction

endclass

`endif
