`ifndef AXIS_REG_TEST_LIST 
`define AXIS_REG_TEST_LIST

package axis_reg_test_list;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  `include "axis_reg_test.sv"
  `include "axis_reg_env.sv"
  `include "axis_reg_sequence.sv"
  `include "axis_reg_ready_sequence.sv"
  `include "axis_transaction.sv"
  `include "axis_ready_trans.sv"

endpackage 

`endif

