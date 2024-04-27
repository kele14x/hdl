`ifndef __AXI4S_SEQUENCE__
`define __AXI4S_SEQUENCE__

`timescale 1 ns / 1 ps
//
`default_nettype none

import uvm_pkg::*;
`include "uvm_macros.svh"

`include "axi4s_transaction.sv"


class axi4s_sequence extends uvm_sequence #(axi4s_transaction);

  axi4s_transaction req;

  // Macro

  `uvm_object_utils_begin(axi4s_sequence)
    `uvm_field_object(req, UVM_DEFAULT)
  `uvm_object_utils_end

  // Constructor

  function new(input string name = "unnamed_axi4s_sequence");
    super.new(.name(name));
  endfunction : new

  // UVM

  virtual task body();
    repeat (10) begin
      `uvm_do(req)
    end
  endtask

endclass

`default_nettype wire

`endif
