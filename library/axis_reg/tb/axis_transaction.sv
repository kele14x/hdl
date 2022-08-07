// File: axis_transaction.sv
// Brief: AXI4-Stream UVM Transaction

`ifndef AXIS_TRANSACTION
`define AXIS_TRANSACTION

import uvm_pkg::*;
`include "uvm_macros.svh"

class axis_transaction #(
    parameter int HAS_TKEEP   = 0,
    parameter int HAS_TLAST   = 0,
    parameter int HAS_TREADY  = 1,
    parameter int HAS_TSTRB   = 0,
    parameter int TDATA_WIDTH = 8,
    parameter int TDEST_WIDTH = 0,
    parameter int TID_WIDTH   = 0,
    parameter int TUSER_WIDTH = 0
) extends uvm_sequence_item;

  rand bit [                    (TDATA_WIDTH == 0 ? 0 : (TDATA_WIDTH-1)):0] tdata;
  rand bit [                    (TDEST_WIDTH == 0 ? 0 : (TDEST_WIDTH-1)):0] tdest;
  rand bit [                        (TID_WIDTH == 0 ? 0 : (TID_WIDTH-1)):0] tid;
  rand bit [(TDATA_WIDTH == 0 || HAS_TKEEP == 0 ? 0 : (TDATA_WIDTH/8-1)):0] tkeep;
  rand bit                                                                  tlast;
  rand bit [(TDATA_WIDTH == 0 || HAS_TSTRB == 0 ? 0 : (TDATA_WIDTH/8-1)):0] tstrb;
  rand bit [                    (TUSER_WIDTH == 0 ? 0 : (TUSER_WIDTH-1)):0] tuser;

  `uvm_object_utils_begin(axis_transaction)
    `uvm_field_int(tdata, UVM_DEFAULT)
    `uvm_field_int(tdest, UVM_DEFAULT)
    `uvm_field_int(tid, UVM_DEFAULT)
    `uvm_field_int(tkeep, UVM_DEFAULT)
    `uvm_field_int(tlast, UVM_DEFAULT)
    `uvm_field_int(tstrb, UVM_DEFAULT)
    `uvm_field_int(tuser, UVM_DEFAULT)
  `uvm_object_utils_end

  function new(string name = "axis_transaction");
    super.new(name);
  endfunction

endclass

`endif
