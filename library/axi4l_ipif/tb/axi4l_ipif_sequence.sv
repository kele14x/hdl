class axi4l_ipif_sequence extends uvm_sequence #(axi4l_ipif_transaction);
  `uvm_object_utils(axi4l_ipif_sequence)

  function new(string name = "axi4l_ipif_sequence");
    super.new(name);
  endfunction

  virtual task body();
    for (int i = 0; i < 100; i++) begin
      // T req is a transaction object
      req = axi4l_ipif_transaction::type_id::create("req");
      start_item(req);
      assert (req.randomize());
      `uvm_info(get_full_name(), $sformatf("Randomized transaction from sequence"), UVM_LOW);
      req.print();
      finish_item(req);
    end
  endtask

endclass
