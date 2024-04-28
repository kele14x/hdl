`ifndef __AXI4S_SEQUENCER__
`define __AXI4S_SEQUENCER__

`timescale 1 ns / 1 ps
//
`default_nettype none

import uvm_pkg::*;
`include "uvm_macros.svh"

`include "axi4s_transaction.sv"


class axi4s_sequencer extends uvm_sequencer #(axi4s_transaction_base);

  // Macro

  `uvm_component_utils(axi4s_sequencer)

  // Constructor

  function new(input string name = "unnamed_axi4s_sequencer", input uvm_component parent = null);
    super.new(.name(name), .parent(parent));
  endfunction : new

endclass

`default_nettype wire

`endif
