`ifndef __CONFIG_SEQUENCE__
`define __CONFIG_SEQUENCE__

`timescale 1 ns / 1 ps
//
`default_nettype none

import uvm_pkg::*;
`include "uvm_macros.svh"

`include "axi4l_transaction.sv"


//
// O-RAN slave AXI Configuration
//
class config_sequence extends uvm_sequence #(axi4l_transaction);

  // Macro

  `uvm_object_utils(config_sequence)

  // Constructor

  function new(input string name = "unnamed_config_sequence");
    super.new(.name(name));
  endfunction : new

  // UVM

  virtual task body();
    // DL Control
    `uvm_create(req)
    req.set_write(32'h100, 32'h000101);
    `uvm_send(req);

    // DL buffer
    for (int i = 0; i < 10; i++) begin
      `uvm_create(req)
      req.set_write(32'h110 + i * 4, 32'h0132 * i);
      `uvm_send(req);
    end

    // UL Control
    `uvm_create(req)
    req.set_write(32'h200, 32'h000001);
    `uvm_send(req);

    // UL RE config
    `uvm_create(req)
    req.set_write(32'h300, 32'h001E);
    `uvm_send(req);
    `uvm_create(req)
    req.set_write(32'h304, 32'h1E15);
    `uvm_send(req);

    // UL symbol mask
    for (int i = 0; i < 20; i++) begin
      `uvm_create(req)
      req.set_write(32'h380 + i * 4, 32'h3FFF);
      `uvm_send(req);
    end
    `uvm_info("", "Done configuration", UVM_LOW)
  endtask

endclass

`default_nettype wire

`endif
