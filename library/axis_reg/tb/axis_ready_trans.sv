// File: axis_ready_trans.sv
// Brief: AXI4-Stream Ready UVM Transaction

`ifndef AXIS_READY_TRANS
`define AXIS_READY_TRANS

import uvm_pkg::*;
`include "uvm_macros.svh"

class axis_ready_trans extends uvm_sequence_item;
  `uvm_object_utils_begin(axis_ready_trans)
  `uvm_object_utils_end

  function new(string name = "axis_ready_gen");
    super.new(name);
  endfunction

endclass

`endif
