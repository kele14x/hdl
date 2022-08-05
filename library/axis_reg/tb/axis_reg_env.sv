// File: axis_reg_env.sv
// Brief: UVM Test Environment for axis_reg module.

`ifndef AXIS_REG_ENV
`define AXIS_REG_ENV

import uvm_pkg::*;
`include "uvm_macros.svh"

class axis_reg_env extends uvm_env;
  `uvm_component_utils(axis_reg_env)

  axis_mst_agent      mst_agent;
  axis_slv_agent      slv_agent;
  axis_reg_scoreboard scoreboard;

  function new(string name = "axis_reg_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  // Create the agent and scoreboard
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mst_agent = axis_mst_agent::type_id::create("mst_agent", this);
    slv_agent = axis_slv_agent::type_id::create("slv_agent", this);
    scoreboard = axis_reg_scoreboard::type_id::create("scoreboard", this);
  endfunction

  // Connect the agent and scoreboard
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    mst_agent.monitor.mon2sb_port.connect(sb0.sb_export_before);
    slv_agent.monitor.mon2sb_port.connect(sb0.sb_export_after);
  endfunction

endclass

`endif
