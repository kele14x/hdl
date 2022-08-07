// File: axis_slv_driver.sv
// Brief: AXI4-Stream Slave UVM Driver

`ifndef AXIS_SLV_DRIVER
`define AXIS_SLV_DRIVER

import uvm_pkg::*;
`include "uvm_macros.svh"

class axis_slv_driver extends uvm_driver #(axis_ready_trans);
  `uvm_component_utils(axis_slv_driver)

  virtual axi4s_if vif;

  function new(string name = "axis_slv_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction

  virtual task run_phase(uvm_phase phase);
    reset();
    forever begin
      seq_item_port.get_next_item(req);
      drive();
      seq_item_port.item_done(req);
    end
  endtask

  function void set_vif(virtual axi4s_if vif);
    this.vif = vif;
  endfunction

  task drive();
    wait (vif.aresetn);
    @(posedge vif.aclk);
    vif.tready <= 1'b1;
    forever begin
      @(posedge vif.aclk);
      if (vif.tvalid) begin
        vif.tready <= 1'b0;
        break;
      end
    end
  endtask

  task reset();
    vif.tready <= 1'b0;
  endtask

endclass

`endif
