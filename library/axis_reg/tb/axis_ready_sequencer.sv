// File axis_ready_sequencer.sv
// Brief: AXI4-Stream Ready UVM Sequencer

class axis_sequencer extends uvm_sequencer #(axis_ready_trans);
  `uvm_component_utils(axis_sequencer)

  function new(string name = "axis_sequencer", uvm_component parent = null);
    super.new(name, parent);
  endfunction

endclass
