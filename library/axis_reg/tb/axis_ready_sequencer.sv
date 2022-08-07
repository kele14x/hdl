// File: axis_ready_sequencer.sv
// Brief: AXI4-Stream Ready UVM Sequencer

`ifndef AXIS_READY_SEQUENCER
`define AXIS_READY_SEQUENCER

import uvm_pkg::*;
`include "uvm_macros.svh"

class axis_ready_sequencer extends uvm_sequencer #(axis_ready_trans);
  `uvm_component_utils(axis_ready_sequencer)

  function new(string name = "axis_ready_sequencer", uvm_component parent = null);
    super.new(name, parent);
  endfunction

endclass

`endif
