// File: axis_mst_driver.sv
// Brief: AXI4-Stream Master UVM Driver

`ifndef AXIS_MST_DRIVER
`define AXIS_MST_DRIVER

import uvm_pkg::*;
`include "uvm_macros.svh"

class axis_mst_driver extends uvm_driver #(axis_transaction);
  `uvm_component_utils(axis_mst_driver)

  virtual axi4s_if vif;

  function new(string name = "axis_mst_driver", uvm_component parent = null);
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
    vif.tdata  <= req.tdata;
    vif.tdest  <= req.tdest;
    vif.tid    <= req.tid;
    vif.tkeep  <= req.tkeep;
    vif.tlast  <= req.tlast;
    vif.tstrb  <= req.tstrb;
    vif.tuser  <= req.tuser;
    //
    vif.tvalid <= 1'b1;
    forever begin
      @(posedge vif.aclk);
      if (vif.tready) begin
        vif.tvalid <= 1'b0;
        break;
      end
    end
  endtask

  task reset();
    vif.tdata  <= '0;
    vif.tdest  <= '0;
    vif.tid    <= '0;
    vif.tkeep  <= '0;
    vif.tlast  <= '0;
    vif.tstrb  <= '0;
    vif.tuser  <= '0;
    //
    vif.tvalid <= '0;
  endtask

endclass

`endif
