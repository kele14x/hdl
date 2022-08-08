// File: axis_ready_sequence.sv
// Brief: AXI4-Stream Ready UVM Sequence

`ifndef AXIS_REG_READY_SEQUENCE
`define AXIS_REG_READY_SEQUENCE

import uvm_pkg::*;
`include "uvm_macros.svh"

class axis_reg_ready_sequence extends uvm_sequence #(axis_ready_gen);
  `uvm_object_utils(axis_reg_ready_sequence)

  function new(string name = "axis_reg_ready_sequence");
    super.new(name);
  endfunction

  virtual task body();
    for (int i = 0; i < 100; i++) begin
      `uvm_do(req)
    end
  endtask

endclass

`endif
