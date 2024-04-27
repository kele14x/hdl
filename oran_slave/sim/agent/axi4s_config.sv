`ifndef __AXI4S_CONFIG__
`define __AXI4S_CONFIG__

`timescale 1 ns / 1 ps
//
`default_nettype none

import uvm_pkg::*;
`include "uvm_macros.svh"

`include "axi4s_if.sv"
`include "axi4s_transaction.sv"


class axi4s_config extends uvm_object;

  // Fields

  virtual axi4s_if vif;

  int              tdata_width = 64;
  int              tuser_width = 0;
  int              tid_width   = 0;
  int              tdest_width = 0;

  bit              has_tvalid  = 1;
  bit              has_tready  = 1;
  bit              has_tkeep   = 1;
  bit              has_tstrb   = 0;

  // Macro

  `uvm_object_utils(axi4s_config)

  // Constructor

  function new(input string name = "unnamed_axi4s_config");
    super.new(.name(name));
  endfunction

endclass : axi4s_config

`default_nettype wire

`endif
