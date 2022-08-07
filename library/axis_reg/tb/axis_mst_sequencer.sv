// File axis_mst_sequencer.sv
// Brief: AXI4-Stream UVM Sequencer

`ifndef AXIS_MST_SEQUENCER
`define AXIS_MST_SEQUENCER

import uvm_pkg::*;
`include "uvm_macros.svh"

class axis_mst_sequencer extends uvm_sequencer #(axis_transaction);
  `uvm_component_utils(axis_mst_sequencer)

  function new(string name = "axis_mst_sequencer", uvm_component parent = null);
    super.new(name, parent);
  endfunction

endclass

`endif
