// File: axis_ready_sequence.sv
// Brief: AXI4-Stream Ready UVM Sequence

`ifndef AXIS_REG_READY_SEQUENCE
`define AXIS_REG_READY_SEQUENCE

import uvm_pkg::*;
`include "uvm_macros.svh"

class axis_reg_ready_sequence extends uvm_sequence #(axis_ready_trans);
  `uvm_object_utils(axis_reg_ready_sequence)

  function new(string name = "axis_reg_ready_sequence");
    super.new(name);
  endfunction

  virtual task body();
    for (int i = 0; i < 100; i++) begin
      // T req is a pre-defined transaction object
      req = axis_ready_trans::type_id::create("req");
      start_item(req);
      assert (req.randomize());
      `uvm_info(get_full_name(), $sformatf("Randomized transaction from sequence"), UVM_LOW);
      req.print();
      finish_item(req);
    end
  endtask

endclass

`endif
