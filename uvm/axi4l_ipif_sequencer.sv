class axi4l_ipif_sequencer extends uvm_sequencer #(axi4l_ipif_transaction);
  `uvm_component_utils(axi4l_ipif_sequencer)

  function new(string name = "axi4l_ipif_sequencer", uvm_component parent = null);
    super.new(name, parent);
  endfunction

endclass
