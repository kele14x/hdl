`ifndef __AXI4S_SCOREBOARD__
`define __AXI4S_SCOREBOARD__

`timescale 1 ns / 1 ps
//
`default_nettype none

import uvm_pkg::*;
`include "uvm_macros.svh"

`include "axi4s_transaction.sv"


//
// AXI4-Stream Scoreboard
//
class axi4s_scoreboard extends uvm_scoreboard;

  // Fields

  uvm_tlm_analysis_fifo #(axi4s_transaction) analysis_expect_fifo;
  uvm_tlm_analysis_fifo #(axi4s_transaction) analysis_actual_fifo;

  int collected_item = 0;
  int mismatched_item = 0;

  // Macro

  `uvm_component_utils(axi4s_scoreboard)

  // Constructor

  function new(input string name = "unnamed_axi4s_scoreboard", input uvm_component parent = null);
    super.new(.name(name), .parent(parent));
  endfunction

  // UVM

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(.phase(phase));
    analysis_expect_fifo = new("analysis_expect_fifo", this);
    analysis_actual_fifo = new("analysis_actual_fifo", this);
  endfunction : build_phase

  virtual task run_phase(uvm_phase phase);
    axi4s_transaction expected;
    axi4s_transaction actual;
    super.run_phase(.phase(phase));

    forever begin
      this.analysis_expect_fifo.get(expected);
      this.analysis_actual_fifo.get(actual);
      this.collected_item++;
      if (!expected.compare(actual)) begin
        this.mismatched_item++;
        `uvm_error("", "Expected result and actual result mismatch!")
        `uvm_info("", $sformatf("Expected: %s", expected.sprint()), UVM_LOW);
        `uvm_info("", $sformatf("Actual: %s", actual.sprint()), UVM_LOW);
      end
    end
  endtask : run_phase

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(.phase(phase));
    `uvm_info("", $sformatf("Collected item: %d", this.collected_item), UVM_LOW)
    `uvm_info("", $sformatf("Mismatched item: %d", this.mismatched_item), UVM_LOW)
  endfunction : report_phase

endclass : axi4s_scoreboard

`default_nettype wire

`endif
