// File: axis_reg_sequence.sv
// Brief: UVM Sequence for test axis_reg module.

`ifndef AXIS_REG_SEQUENCE
`define AXIS_REG_SEQUENCE

import uvm_pkg::*;
`include "uvm_macros.svh"

class axis_reg_sequence extends uvm_sequence #(axis_transaction);
  `uvm_object_utils(axis_reg_sequence)

  function new(string name = "axis_reg_sequence");
    super.new(name);
  endfunction

  virtual task body();
    for (int i = 0; i < 100; i++) begin
      `uvm_do(req)
    end
  endtask

endclass

`endif
