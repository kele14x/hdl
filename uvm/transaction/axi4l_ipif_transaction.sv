// File: axi4l_ipif_transaction.sv
// Brief: AXI4L IPIF transaction
class axi4l_ipif_transaction #(
    parameter int ADDR_WIDTH = 12,
    parameter int DATA_WIDTH = 32
) extends uvm_sequence_item;

  rand bit [ADDR_WIDTH-1:0] addr;
  rand bit [DATA_WIDTH-1:0] data;
  rand bit                  wrn;
  rand bit [           1:0] resp;

  `uvm_object_utils_begin(axi4l_ipif_transaction)
    `uvm_field_int(addr, UVM_DEFAULT)
    `uvm_field_int(data, UVM_DEFAULT)
    `uvm_field_int(resp, UVM_DEFAULT)
  `uvm_object_utils_end

  function new(string name = "axi4l_ipif_transaction");
    super.new(name);
  endfunction

endclass
