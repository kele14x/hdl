`ifndef __AXI4S_TRANSACTION__
`define __AXI4S_TRANSACTION__

`timescale 1 ns / 1 ps
//
`default_nettype none

import uvm_pkg::*;
`include "uvm_macros.svh"

`define MAX_TUSER_WIDTH 128
`define MAX_TID_WIDTH 64
`define MAX_TDEST_WIDTH 64


//
// Basic AXI4-Stream transaction
//
virtual class axi4s_transaction_base extends uvm_sequence_item;

  function new(input string name = "unnamed_axi4s_transaction");
    super.new(.name(name));
  endfunction : new

  // Get the total size in bytes
  pure virtual function int get_size();

  // Get the byte at index `idx`
  pure virtual function bit [7:0] get_byte(input int idx);

  // Get the all bytes and append to `bytes`
  pure virtual function void get_bytes(ref bit [7:0] bytes[]);

  // Get the TUSER field
  pure virtual function bit [`MAX_TUSER_WIDTH-1:0] get_tuser();

  // Get the TID field
  pure virtual function bit [`MAX_TID_WIDTH-1:0] get_tid();

  // Get TDEST field
  pure virtual function bit [`MAX_TDEST_WIDTH-1:0] get_tdest();

endclass : axi4s_transaction_base


//
// AXI4-Stream transaction
//
class axi4s_transaction extends axi4s_transaction_base;

  // Fields

  rand bit [                 7:0] payload[];
  rand bit [`MAX_TUSER_WIDTH-1:0] tuser;
  rand bit [  `MAX_TID_WIDTH-1:0] tid;
  rand bit [`MAX_TDEST_WIDTH-1:0] tdest;

  // Macro

  `uvm_object_utils_begin(axi4s_transaction)
    `uvm_field_array_int(payload, UVM_DEFAULT)
    `uvm_field_int(tuser, UVM_DEFAULT)
    `uvm_field_int(tid, UVM_DEFAULT)
    `uvm_field_int(tdest, UVM_DEFAULT)
  `uvm_object_utils_end

  // Constructor

  function new(input string name = "unnamed_axi4s_transaction");
    super.new(.name(name));
  endfunction : new

  // Helper functions

  virtual function int get_size();
    return this.payload.size();
  endfunction : get_size

  virtual function void set_size(input int size);
    this.payload = new[size] (this.payload);
  endfunction : set_size

  virtual function bit [7:0] get_byte(input int idx);
    return this.payload[idx];
  endfunction : get_byte

  virtual function void set_byte(input int idx, input bit [7:0] data);
    this.payload[idx] = data;
  endfunction : set_byte

  virtual function void get_bytes(ref bit [7:0] bytes[]);
    bytes = {bytes, this.payload};
  endfunction

  virtual function void append(input bit [7:0] bytes[]);
    this.payload = {this.payload, bytes};
  endfunction : append

  virtual function bit [`MAX_TUSER_WIDTH-1:0] get_tuser();
    return this.tuser;
  endfunction : get_tuser

  virtual function void set_tuser(input bit [`MAX_TUSER_WIDTH-1:0] tuser);
    this.tuser = tuser;
  endfunction : set_tuser

  virtual function bit [`MAX_TID_WIDTH-1:0] get_tid();
    return this.tid;
  endfunction : get_tid

  virtual function set_tid(input bit [`MAX_TID_WIDTH-1:0] tid);
    this.tid = tid;
  endfunction : set_tid

  virtual function bit [`MAX_TDEST_WIDTH-1:0] get_tdest();
    return this.tdest;
  endfunction : get_tdest

  virtual function void set_tdest(bit [`MAX_TDEST_WIDTH-1:0] tdest);
    this.tdest = tdest;
  endfunction : set_tdest

endclass : axi4s_transaction

`default_nettype wire

`endif
