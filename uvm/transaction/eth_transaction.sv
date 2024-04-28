`ifndef __ETH_TRANSACTION__
`define __ETH_TRANSACTION__

`timescale 1 ns / 1 ps
//
`default_nettype none

import uvm_pkg::*;
`include "uvm_macros.svh"

`include "axi4s_transaction.sv"


//
// MAC Header
//
class mac_header extends uvm_object;

  // Declaration of fields

  rand bit        has_vlan;

  rand bit [47:0] dest_mac;
  rand bit [47:0] src_mac;
  bit      [15:0] vlan_type  = 16'h8100;
  rand bit [15:0] vlan_tci;
  bit      [15:0] ethertype;

  // Declaration of utility and field macros

  `uvm_object_utils_begin(mac_header)
    `uvm_field_int(dest_mac, UVM_DEFAULT)
    `uvm_field_int(src_mac, UVM_DEFAULT)
    `uvm_field_int(has_vlan, UVM_DEFAULT)
    `uvm_field_int(vlan_type, UVM_DEFAULT)
    `uvm_field_int(vlan_tci, UVM_DEFAULT)
    `uvm_field_int(ethertype, UVM_DEFAULT)
  `uvm_object_utils_end

  // Constructor

  function new(input string name = "unnamed_mac_header");
    super.new(.name(name));
  endfunction : new

  // Helper functions

  virtual function int get_size();
    return 14 + this.has_vlan * 4;
  endfunction : get_size

  virtual function bit [7:0] get_byte(input int idx);
    bit [7:0] bytes[];
    this.get_bytes(bytes);
    return bytes[idx];
  endfunction : get_byte

  virtual function void get_bytes(ref bit [7:0] bytes[]);
    bit [7:0] temp[];
    if (this.has_vlan) begin
      temp = {>>{this.dest_mac, this.src_mac, this.vlan_type, this.vlan_tci, this.ethertype}};
    end else begin
      temp = {>>{this.dest_mac, this.src_mac, this.ethertype}};
    end
    bytes = {bytes, temp};
  endfunction : get_bytes

endclass : mac_header


//
// Ethernet MAC Packet
//
class eth_transaction extends axi4s_transaction_base;

  // Declaration of fieldsget_bytes

  rand mac_header mac_hdr;
  rand bit [7:0] payload[];

  // Declaration of utility and field macros

  `uvm_object_utils_begin(eth_transaction)
    `uvm_field_object(mac_hdr, UVM_DEFAULT)
  `uvm_object_utils_end

  // Constructor

  function new(input string name = "unnamed_eth_transaction");
    super.new(.name(name));
    this.mac_hdr = mac_header::type_id::create("mac_hdr");
  endfunction : new

  function void post_randomize();
    this.mac_hdr.ethertype = this.payload.size();
  endfunction

  // Helper functions

  virtual function int get_size();
    int c = 0;
    c = c + this.mac_hdr.get_size();
    c = c + this.payload.size();
    return c;
  endfunction : get_size

  virtual function bit [7:0] get_byte(input int idx);
    if (idx < this.mac_hdr.get_size()) begin
      return this.mac_hdr.get_byte(idx);
    end

    idx = idx - this.mac_hdr.get_size();
    if (idx < this.payload.size()) begin
      return this.payload[idx];
    end

    return 8'b0;
  endfunction : get_byte

  virtual function void get_bytes(ref bit [7:0] bytes[]);
    this.mac_hdr.get_bytes(bytes);
    bytes = {bytes, this.payload};
  endfunction : get_bytes

  virtual function bit [`MAX_TUSER_WIDTH-1:0] get_tuser();
    return '0;
  endfunction : get_tuser

  virtual function bit [`MAX_TID_WIDTH-1:0] get_tid();
    return '0;
  endfunction : get_tid

  virtual function bit [`MAX_TDEST_WIDTH-1:0] get_tdest();
    return '0;
  endfunction : get_tdest

endclass : eth_transaction

`default_nettype wire

`endif
