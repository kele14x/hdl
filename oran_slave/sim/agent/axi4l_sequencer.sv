`ifndef __AXI4L_SEQUENCER__
`define __AXI4L_SEQUENCER__

`timescale 1 ns / 1 ps
//
`default_nettype none

import uvm_pkg::*;
`include "uvm_macros.svh"

`include "axi4l_transaction.sv"


class axi4l_sequencer extends uvm_sequencer #(axi4l_transaction);

  // Macro

  `uvm_component_utils(axi4l_sequencer)

  // Constructor

  function new(input string name = "unnamed_axi4l_sequencer", input uvm_component parent = null);
    super.new(.name(name), .parent(parent));
  endfunction : new

endclass

`default_nettype wire

`endif
