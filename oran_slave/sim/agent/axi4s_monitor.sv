`ifndef __AXI4S_MONITOR__
`define __AXI4S_MONITOR__

`timescale 1 ns / 1 ps
//
`default_nettype none

import uvm_pkg::*;
`include "uvm_macros.svh"

`include "axi4s_if.sv"
`include "axi4s_transaction.sv"


class axi4s_monitor extends uvm_monitor;

  // Fields

  axi4s_config cfg;

  uvm_analysis_port #(axi4s_transaction) analysis_port;

  // Macro

  `uvm_component_utils(axi4s_monitor)

  // Constructor

  function new(input string name = "unnamed_axi4s_monitor", input uvm_component parent = null);
    super.new(.name(name), .parent(parent));
    analysis_port = new("analysis_port", this);
  endfunction : new

  // UVM

  virtual function void build_phase(input uvm_phase phase);
    super.build_phase(phase);
  endfunction : build_phase

  virtual task run_phase(uvm_phase phase);
    axi4s_transaction item;
    int w;
    bit [7:0] bytes[];
    super.run_phase(.phase(phase));

    w = this.cfg.tdata_width / 8;

    // Wait reset done
    wait (this.cfg.vif.aresetn == 1'b1);
    item = axi4s_transaction::type_id::create("item");

    @(posedge this.cfg.vif.aclk);
    forever begin
      if (this.cfg.vif.tvalid) begin
        for (int i = 0; i < w; i++) begin
          if (this.cfg.vif.tkeep[i]) begin
            bytes = {bytes, this.cfg.vif.tdata[i*8+7-:8]};
          end
        end
        if (this.cfg.vif.tlast) begin
          item = axi4s_transaction::type_id::create("item");
          item.append(bytes);
          bytes = new[0];
          analysis_port.write(item);
        end
      end
      @(posedge this.cfg.vif.aclk);
    end
  endtask : run_phase

endclass : axi4s_monitor

`default_nettype none

`endif
