`ifndef __ETH_SEQUENCE__
`define __ETH_SEQUENCE__

`timescale 1 ns / 1 ps
//
`default_nettype none

import uvm_pkg::*;
`include "uvm_macros.svh"

`include "eth_transaction.sv"


class eth_sequence extends uvm_sequence #(eth_transaction);

  eth_transaction req;

  // Macro

  `uvm_object_utils_begin(eth_sequence)
    `uvm_field_object(req, UVM_DEFAULT)
  `uvm_object_utils_end

  // Constructor

  function new(input string name = "unnamed_eth_sequence");
    super.new(.name(name));
  endfunction : new

  // UVM

  virtual task body();
    repeat (10) begin
      `uvm_do_with(req,
                   {
        req.mac_hdr.dest_mac == 48'h001122334466;
        req.mac_hdr.src_mac == 48'h001122334455;
        req.mac_hdr.has_vlan == 1;
      })
    end
  endtask

endclass

`default_nettype wire

`endif
