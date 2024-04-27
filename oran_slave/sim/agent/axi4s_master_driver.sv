`ifndef __AXI4S_MASTER_DRIVER__
`define __AXI4S_MASTER_DRIVER__

`timescale 1 ns / 1 ps
//
`default_nettype none

import uvm_pkg::*;
`include "uvm_macros.svh"

`include "axi4s_if.sv"
`include "axi4s_transaction.sv"


class axi4s_master_driver extends uvm_driver #(axi4s_transaction_base);

  // Fields

  axi4s_config cfg;

  // Macro

  `uvm_component_utils(axi4s_master_driver)

  // Constructor

  function new(input string name = "unnamed_axi4s_master_driver",
               input uvm_component parent = null);
    super.new(.name(name), .parent(parent));
  endfunction : new

  // UVM

  virtual function void build_phase(input uvm_phase phase);
    super.build_phase(phase);
  endfunction : build_phase

  virtual task run_phase(uvm_phase phase);
    axi4s_transaction_base req_item;
    super.run_phase(.phase(phase));

    // Wait reset done
    reset();
    wait (this.cfg.vif.aresetn == 1'b1);

    // Ensure that we drive the transaction at posedge of clock
    @(posedge this.cfg.vif.aclk);
    forever begin
      seq_item_port.try_next_item(req_item);
      if (req_item != null) begin
        drive(req_item);
        seq_item_port.item_done();
      end else begin
        @(posedge this.cfg.vif.aclk);
      end
    end
  endtask : run_phase

  // Helper functions

  virtual task reset();
    this.cfg.vif.tdata  <= '0;
    this.cfg.vif.tkeep  <= '0;
    this.cfg.vif.tvalid <= 1'b0;
    this.cfg.vif.tlast  <= 1'b0;
  endtask : reset

  virtual task drive(axi4s_transaction_base req_item);
    int bw;
    int size;
    int len;
    bit [7:0] bytes[];

    req_item.get_bytes(bytes);
    bw   = this.cfg.tdata_width / 8;
    size = bytes.size();
    len  = (size + bw - 1) / bw;  // ceil(size / bw)

    for (int t = 0; t < len; t++) begin
      // TDATA & TKEEP
      for (int i = 0; i < bw; i++) begin
        this.cfg.vif.tdata[i*8+7-:8] <= 8'b0;
        this.cfg.vif.tkeep[i]        <= 1'b0;
        if (t * bw + i < size) begin
          this.cfg.vif.tdata[i*8+7-:8] <= bytes[t*bw+i];
          this.cfg.vif.tkeep[i]        <= 1'b1;
        end
      end

      // TVALID
      this.cfg.vif.tvalid <= 1'b1;

      // TLAST
      this.cfg.vif.tlast  <= 1'b0;
      if (t == len - 1) begin
        this.cfg.vif.tlast <= 1'b1;
      end

      // wait TREADY
      @(posedge this.cfg.vif.aclk);
      while (this.cfg.vif.tready == 1'b0) begin
        @(posedge this.cfg.vif.aclk);
      end
      this.cfg.vif.tdata  <= '0;
      this.cfg.vif.tkeep  <= '0;
      this.cfg.vif.tvalid <= 1'b0;
      this.cfg.vif.tlast  <= 1'b0;
    end
  endtask : drive

endclass : axi4s_master_driver

`default_nettype wire

`endif
