`ifndef AXIS_REG_TEST_LIST 
`define AXIS_REG_TEST_LIST

package axis_reg_test_list;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // Transaction
  
  `include "axis_ready_trans.sv"

  // Agent
  `include "axis_transaction.sv"
  `include "axis_mst_sequencer.sv"
  `include "axis_mst_driver.sv"
  `include "axis_monitor.sv"
  `include "axis_mst_agent.sv"

  `include "axis_slv_driver.sv"
  `include "axis_ready_sequencer.sv"
  `include "axis_slv_agent.sv"

  // Env
  `include "axis_reg_env.sv"
  `include "axis_reg_scoreboard.sv"

  // Test
  `include "axis_reg_test.sv"
  `include "axis_reg_sequence.sv"
  `include "axis_reg_ready_sequence.sv"
  
endpackage 

`endif

