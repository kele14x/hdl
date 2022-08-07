// File: axis_monitor.sv
// Brief: AXI4-Stream UVM Monitor

`ifndef AXIS_MONITOR
`define AXIS_MONITOR

import uvm_pkg::*;
`include "uvm_macros.svh"

class axis_monitor extends uvm_monitor;

  uvm_analysis_port #(axis_transaction) mon2sb_port;

  axis_transaction trans;

  virtual axi4s_if vif;

`uvm_component_utils(axis_monitor)
  
  // Constructor
  function new(string name = "axis_monitor", uvm_component parent = null);
    super.new(name, parent);
    mon2sb_port = new("mon2sb_port", this);
    trans = new("trans");
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction

  task run_phase(uvm_phase phase);
    wait (vif.aresetn == 1'b1);
    forever begin
      @(vif.aclk);
      if (vif.tvalid && vif.tready && vif.aclken) begin
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

  function void set_vif(virtual axi4s_if vif);
    this.vif = vif;
  endfunction

endclass

`endif
