// File: axis_reg_test.sv
// Brief: Basic test of the axis_reg module.

`ifndef AXIS_REG_TEST
`define AXIS_REG_TEST

import uvm_pkg::*;
`include "uvm_macros.svh"

class axis_reg_test extends uvm_test;
  `uvm_component_utils(axis_reg_test)

  bit test_pass = 1;

  axis_reg_env        env;
  axis_reg_sequence   seq;
  axis_ready_sequence ready_seq;

  function new(string name = "axis_reg_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void end_of_elaboration_phase(uvm_phase phase);
    uvm_top.print_topology();
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = axis_reg_env::type_id::create("env", this);
    seq = axis_reg_sequence::type_id::create("seq");
  endfunction : build_phase

  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    phase.raise_objection(this);
    seq.start(env.mst_agent.sequencer);
    ready_seq.start(env.slv_agent.sequencer);
    phase.drop_objection(this);
  endtask

  // Report the test results
  virtual function void report_phase(uvm_phase phase);
    if (test_pass) begin
      `uvm_info(get_type_name(), "** UVM TEST PASSED **", UVM_NONE);
    end else begin
      `uvm_error(get_type_name(), "** UVM TEST FAIL **");
    end
  endfunction

endclass

`endif