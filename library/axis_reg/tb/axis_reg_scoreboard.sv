// File: axis_reg_scoreboard.sv
// Brief: UVM Scoreboard for test axis_reg module.

class axis_reg_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(axis_reg_scoreboard)

  uvm_analysis_export #(axis_reg_transaction) mon2sb_mst_export;
  uvm_analysis_export #(axis_reg_transaction) mon2sb_slv_export;

  uvm_tlm_analysis_fifo #(axis_reg_transaction) mon2sb_mst_export_fifo;
  uvm_tlm_analysis_fifo #(axis_reg_transaction) mon2sb_slv_export_fifo;

  axis_transaction mst_trans;
  axis_transaction slv_trans;

  bit error = 0;


  function new(string name = "axis_reg_scoreboard", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    // Exports
    mon2sb_mst_export = new("mon2sb_mst_export", this);
    mon2sb_slv_export = new("mon2sb_slv_export", this);
    // Export FIFOs
    mon2sb_mst_export_fifo = new("mon2sb_mst_export", this);
    mon2sb_slv_export_fifo = new("mon2sb_slv_export", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    mon2sb_mst_export.connect(mon2sb_mst_export_fifo.analysis_export);
    mon2sb_slv_export.connect(mon2sb_slv_export_fifo.analysis_export);
  endfunction


  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      mon2sb_mst_export_fifo.get(mst_trans);
      mon2sb_slv_export_fifo.get(slv_trans);

      `uvm_info(get_full_name(), $sformatf("mst_trans, DATA= %d", mst_trans.data), UVM_LOW);
      `uvm_info(get_full_name(), $sformatf("slv_trans, DATA= %d", slv_trans.data), UVM_LOW);

      if (mst_trans.data == slv_trans.data) begin
        `uvm_info(get_full_name(), $sformatf("Transaction match"), UVM_LOW);
      end else begin
        error = 1;
        `uvm_info(get_full_name(), $sformatf("Transaction not match"), UVM_LOW);
      end
    end
  endtask

endclass
