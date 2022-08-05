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
      // T req is a pre-defined transaction object
      req = axis_transaction::type_id::create("req");
      start_item(req);
      assert (req.randomize());
      `uvm_info(get_full_name(), $sformatf("Randomized transaction from sequence"), UVM_LOW);
      req.print();
      finish_item(req);
    end
  endtask

endclass

`endif
