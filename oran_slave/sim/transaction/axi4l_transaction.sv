`ifndef __AXI4L_TRANSACTION__
`define __AXI4L_TRANSACTION__

`timescale 1 ns / 1 ps
//
`default_nettype none

import uvm_pkg::*;
`include "uvm_macros.svh"


//
// AXI4-Stream transaction
//
class axi4l_transaction extends uvm_sequence_item;

  // Declaration of fields
  rand bit        wrn;
  rand bit [31:0] addr;
  rand bit [31:0] data;
  rand bit [ 3:0] strb;
  rand bit [ 1:0] resp;


  // Declaration of utility and field macros,

  `uvm_object_utils_begin(axi4l_transaction)
    `uvm_field_int(wrn, UVM_DEFAULT)
    `uvm_field_int(addr, UVM_DEFAULT)
    `uvm_field_int(data, UVM_DEFAULT)
    `uvm_field_int(strb, UVM_DEFAULT)
    `uvm_field_int(resp, UVM_DEFAULT)
  `uvm_object_utils_end

  // Constructor

  function new(input string name = "unnamed_axi4l_transaction");
    super.new(.name(name));
  endfunction : new

  virtual function void set_write(input bit [31:0] addr, input bit [31:0] data);
    this.wrn  = 1'b0;
    this.addr = addr;
    this.data = data;
    this.strb = 4'b1111;
    this.resp = '0;
  endfunction : set_write

  virtual function void set_read(input bit [31:0] addr);
    this.wrn  = 1'b1;
    this.addr = addr;
    this.data = '0;
    this.strb = 4'b1111;
    this.resp = '0;
  endfunction : set_read

endclass : axi4l_transaction

`default_nettype wire

`endif
