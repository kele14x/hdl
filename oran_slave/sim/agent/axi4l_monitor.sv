`ifndef __AXI4L_MONITOR__
`define __AXI4L_MONITOR__

`timescale 1 ns / 1 ps
//
`default_nettype none

import uvm_pkg::*;
`include "uvm_macros.svh"

`include "axi4l_if.sv"
`include "axi4l_transaction.sv"


class axi4l_monitor extends uvm_monitor;

  // Fields

  axi4l_config                                                 cfg;

  uvm_analysis_port #(axi4l_transaction)                       analysis_port;

  logic                                  [`MAX_ADDR_WIDTH-1:0] waddr         [$];
  logic                                  [`MAX_DATA_WIDTH-1:0] wdata         [$];
  logic                                  [                1:0] wresp         [$];

  logic                                  [`MAX_ADDR_WIDTH-1:0] raddr         [$];
  logic                                  [`MAX_DATA_WIDTH-1:0] rdata         [$];
  logic                                  [                1:0] rresp         [$];

  // Macro

  `uvm_component_utils(axi4l_monitor)

  // Constructor

  function new(input string name = "unnamed_axi4l_monitor", input uvm_component parent = null);
    super.new(.name(name), .parent(parent));
    analysis_port = new("analysis_port", this);
  endfunction : new

  // UVM

  virtual function void build_phase(input uvm_phase phase);
    super.build_phase(phase);
  endfunction : build_phase

  virtual task run_phase(uvm_phase phase);
    axi4l_transaction witem;
    axi4l_transaction ritem;
    super.run_phase(.phase(phase));

    // Wait reset done
    wait (this.cfg.vif.aresetn == 1'b1);
    @(posedge this.cfg.vif.aclk);

    fork
      begin : p_aw
        forever begin
          if (this.cfg.vif.awvalid && this.cfg.vif.awready) begin
            waddr.push_back(this.cfg.vif.awaddr);
          end
          @(posedge this.cfg.vif.aclk);
        end
      end

      begin : p_w
        forever begin
          if (this.cfg.vif.wvalid && this.cfg.vif.wready) begin
            wdata.push_back(this.cfg.vif.wdata);
          end
          @(posedge this.cfg.vif.aclk);
        end
      end

      begin : p_b
        forever begin
          if (this.cfg.vif.bvalid && this.cfg.vif.bready) begin
            wresp.push_back(this.cfg.vif.bresp);
          end
          @(posedge this.cfg.vif.aclk);
        end
      end

      begin : p_ar
        forever begin
          if (this.cfg.vif.arvalid && this.cfg.vif.arready) begin
            raddr.push_back(this.cfg.vif.araddr);
          end
          @(posedge this.cfg.vif.aclk);
        end
      end

      begin : p_r
        forever begin
          if (this.cfg.vif.rvalid && this.cfg.vif.rready) begin
            rdata.push_back(this.cfg.vif.rdata);
            rresp.push_back(this.cfg.vif.rresp);
          end
          @(posedge this.cfg.vif.aclk);
        end
      end

      // Write transaction to analysis port

      begin : w_write
        forever begin
          if (waddr.size() >= 1  && wdata.size() >= 1 && wresp.size() >=1) begin
            witem = axi4l_transaction::type_id::create("witem");
            witem.wrn = 1'b0;
            witem.addr = waddr.pop_front();
            witem.data = wdata.pop_front();
            witem.resp = wresp.pop_front();
            analysis_port.write(witem);
          end
          @(posedge this.cfg.vif.aclk);
        end
      end

      begin : r_write
        forever begin
          if (raddr.size() >= 1  && rdata.size() >= 1 && rresp.size() >=1) begin
            ritem = axi4l_transaction::type_id::create("ritem");
            ritem.wrn = 1'b1;
            ritem.addr = raddr.pop_front();
            ritem.data = rdata.pop_front();
            ritem.resp = rresp.pop_front();
            analysis_port.write(witem);
          end
          @(posedge this.cfg.vif.aclk);
        end
      end
    join
  endtask : run_phase

endclass : axi4l_monitor

`default_nettype none

`endif
