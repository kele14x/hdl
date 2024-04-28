`ifndef __AXI4L_CONFIG__
`define __AXI4L_CONFIG__

`timescale 1 ns / 1 ps
//
`default_nettype none

import uvm_pkg::*;
`include "uvm_macros.svh"

`include "axi4l_if.sv"
`include "axi4l_transaction.sv"


class axi4l_config extends uvm_object;

  // Fields

  virtual axi4l_if vif;

  int              addr_width = 32;
  int              data_width = 32;

  // Macro

  `uvm_object_utils(axi4l_config)

  // Constructor

  function new(input string name = "unnamed_axi4l_config");
    super.new(.name(name));
  endfunction

endclass : axi4l_config

`default_nettype wire

`endif
