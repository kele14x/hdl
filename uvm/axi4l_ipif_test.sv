// File: axi4l_ipif_test.sv
// Brief: Basic test of the axi4l_ipif module.

import uvm_pkg::*;
`include "uvm_macros.svh"

class axi4l_ipif_test extends uvm_test;
  `uvm_component_utils(axi4l_ipif_test)

  bit test_pass = 1;

  axi4l_ipif_env      env0;
  axi4l_ipif_sequence seq0;

  function new(string name = "axi4l_ipif_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void end_of_elaboration_phase(uvm_phase phase);
    uvm_top.print_topology();
  endfunction

  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    phase.raise_objection(this);
    #1000;
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
