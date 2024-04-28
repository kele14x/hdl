`ifndef __AXI4L_MASTER_DRIVER__
`define __AXI4L_MASTER_DRIVER__

`timescale 1 ns / 1 ps
//
`default_nettype none

import uvm_pkg::*;
`include "uvm_macros.svh"

`include "axi4l_if.sv"
`include "axi4l_transaction.sv"


class axi4l_master_driver extends uvm_driver #(axi4l_transaction);

  // Fields

  axi4l_config cfg;

  // Macro

  `uvm_component_utils(axi4l_master_driver)

  // Constructor

  function new(input string name = "unnamed_axi4l_master_driver",
               input uvm_component parent = null);
    super.new(.name(name), .parent(parent));
  endfunction : new

  // UVM

  virtual function void build_phase(input uvm_phase phase);
    super.build_phase(phase);
  endfunction : build_phase

  virtual task run_phase(uvm_phase phase);
    axi4l_transaction req_item;
    super.run_phase(.phase(phase));

    // Wait reset done
    reset();
    wait (this.cfg.vif.aresetn == 1'b1);
    @(posedge this.cfg.vif.aclk);

    forever begin
      seq_item_port.get_next_item(req_item);

      // Drive the sequence item
      if (req_item.wrn == 1'b0) begin
        drive_write(req_item);
      end else begin
        drive_read(req_item);
      end

      seq_item_port.item_done();
    end
  endtask : run_phase

  // Helper functions

  // Reset interface
  virtual task reset();
    this.cfg.vif.awaddr  <= '0;
    this.cfg.vif.awprot  <= '0;
    this.cfg.vif.awvalid <= 1'b0;
    //
    this.cfg.vif.wdata   <= '0;
    this.cfg.vif.wstrb   <= '0;
    this.cfg.vif.wvalid  <= 1'b0;
    //
    this.cfg.vif.bready  <= 1'b0;
    //
    this.cfg.vif.araddr  <= '0;
    this.cfg.vif.arprot  <= '0;
    this.cfg.vif.arvalid <= 1'b0;
    //
    this.cfg.vif.rready  <= 1'b0;
  endtask : reset

  // AXI Write
  virtual task drive_write(axi4l_transaction req_item);
    fork
      begin : aw_p
        this.cfg.vif.awaddr  <= req_item.addr;
        this.cfg.vif.awprot  <= '0;
        this.cfg.vif.awvalid <= 1'b1;
        // wait awready
        @(posedge this.cfg.vif.aclk);
        while (this.cfg.vif.awready == 1'b0) begin
          @(posedge this.cfg.vif.aclk);
        end
        this.cfg.vif.awaddr  <= '0;
        this.cfg.vif.awprot  <= '0;
        this.cfg.vif.awvalid <= 1'b0;
      end : aw_p

      begin : w_p
        this.cfg.vif.wdata  <= req_item.data;
        this.cfg.vif.wstrb  <= '1;
        this.cfg.vif.wvalid <= 1'b1;
        // wait wready
        @(posedge this.cfg.vif.aclk);
        while (this.cfg.vif.wready == 1'b0) begin
          @(posedge this.cfg.vif.aclk);
        end
        this.cfg.vif.wdata  <= '0;
        this.cfg.vif.wstrb  <= '0;
        this.cfg.vif.wvalid <= 1'b0;
      end : w_p

      begin : b_p
        this.cfg.vif.bready <= '1;
        // wait bvalid
        @(posedge this.cfg.vif.aclk);
        while (this.cfg.vif.bvalid == 1'b0) begin
          @(posedge this.cfg.vif.aclk);
        end
        this.cfg.vif.bready <= '0;
        req_item.resp = this.cfg.vif.bresp;
      end : b_p
    join
  endtask : drive_write

  // AXI Read
  virtual task drive_read(axi4l_transaction req_item);
    fork
      begin : ar_p
        this.cfg.vif.araddr  <= req_item.addr;
        this.cfg.vif.arprot  <= '0;
        this.cfg.vif.arvalid <= 1'b1;
        // wait arready
        @(posedge this.cfg.vif.aclk);
        while (this.cfg.vif.arready == 1'b0) begin
          @(posedge this.cfg.vif.aclk);
        end
        this.cfg.vif.araddr  <= '0;
        this.cfg.vif.arprot  <= '0;
        this.cfg.vif.arvalid <= 1'b0;
      end : ar_p

      begin : r_p
        this.cfg.vif.rready <= '1;
        // wait rvalid
        @(posedge this.cfg.vif.aclk);
        while (this.cfg.vif.rvalid == 1'b0) begin
          @(posedge this.cfg.vif.aclk);
        end
        this.cfg.vif.rready <= '0;
        req_item.data = this.cfg.vif.rdata;
        req_item.resp = this.cfg.vif.rresp;
      end : r_p
    join
  endtask : drive_read

endclass : axi4l_master_driver

`default_nettype wire

`endif
