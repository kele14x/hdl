class axi4l_ipif_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(axi4l_ipif_scoreboard)

  uvm_analysis_export #(axi4l_ipif_transaction) mon2sb_axi_w_export;
  uvm_analysis_export #(axi4l_ipif_transaction) mon2sb_axi_r_export;
  uvm_analysis_export #(axi4l_ipif_transaction) mon2sb_ipif_w_export;
  uvm_analysis_export #(axi4l_ipif_transaction) mon2sb_ipif_r_export;

  uvm_tlm_analysis_fifo #(axi4l_ipif_transaction) mon2sb_axi_w_export_fifo;
  uvm_tlm_analysis_fifo #(axi4l_ipif_transaction) mon2sb_axi_r_export_fifo;
  uvm_tlm_analysis_fifo #(axi4l_ipif_transaction) mon2sb_ipif_w_export_fifo;
  uvm_tlm_analysis_fifo #(axi4l_ipif_transaction) mon2sb_ipif_r_export_fifo;

  axi4l_ipif_transaction axi_w_trans;
  axi4l_ipif_transaction axi_r_trans;
  axi4l_ipif_transaction ipif_w_trans;
  axi4l_ipif_transaction ipif_r_trans;

  bit error = 0;


  function new(string name = "axi4l_ipif_scoreboard", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    // Exports
    mon2sb_axi_w_export = new("mon2sb_axi_w_export", this);
    mon2sb_axi_r_export = new("mon2sb_axi_r_export", this);
    mon2sb_ipif_w_export = new("mon2sb_ipif_w_export", this);
    mon2sb_ipif_r_export = new("mon2sb_ipif_r_export", this);
    // Export FIFOs
    mon2sb_axi_w_export_fifo = new("mon2sb_axi_w_export_fifo", this);
    mon2sb_axi_r_export_fifo = new("mon2sb_axi_r_export_fifo", this);
    mon2sb_ipif_w_export_fifo = new("mon2sb_ipif_w_export_fifo", this);
    mon2sb_ipif_r_export_fifo = new("mon2sb_ipif_r_export_fifo", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    mon2sb_axi_w_export.connect(mon2sb_axi_w_export_fifo.analysis_export);
    mon2sb_axi_r_export.connect(mon2sb_axi_r_export_fifo.analysis_export);
    mon2sb_ipif_w_export.connect(mon2sb_ipif_w_export_fifo.analysis_export);
    mon2sb_ipif_r_export.connect(mon2sb_ipif_r_export_fifo.analysis_export);
  endfunction


  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    fork
      forever begin : p_compare_w
        mon2sb_axi_w_export_fifo.get(axi_w_trans);
        mon2sb_ipif_w_export_fifo.get(ipif_w_trans);

        `uvm_info(get_full_name(), $sformatf("AXI write trans, ADDR = %d, DATA= %d, RESP=%d",
                                             axi_w_trans.addr, axi_w_trans.data, axi_w_trans.resp),
                  UVM_LOW);
        `uvm_info(get_full_name(), $sformatf("IPIF write trans, ADDR = %d, DATA= %d, RESP=%d",
                                             ipif_w_trans.addr, ipif_w_trans.data,
                                             ipif_w_trans.resp), UVM_LOW);

        if (axi_w_trans.addr == ipif_w_trans.addr && axi_w_trans.data == ipif_w_trans.data &&
            axi_w_trans.resp == ipif_w_trans.resp) begin
          `uvm_info(get_full_name(), $sformatf("Transaction match"), UVM_LOW);
        end else begin
          error = 1;
          `uvm_info(get_full_name(), $sformatf("Transaction not match"), UVM_LOW);
        end
      end

      forever begin : p_compare_r
        mon2sb_axi_r_export_fifo.get(axi_r_trans);
        mon2sb_ipif_r_export_fifo.get(ipif_r_trans);

        `uvm_info(get_full_name(), $sformatf("AXI write trans, ADDR = %d, DATA= %d, RESP=%d",
                                             axi_r_trans.addr, axi_r_trans.data, axi_r_trans.resp),
                  UVM_LOW);
        `uvm_info(get_full_name(), $sformatf("IPIF write trans, ADDR = %d, DATA= %d, RESP=%d",
                                             ipif_r_trans.addr, ipif_r_trans.data,
                                             ipif_r_trans.resp), UVM_LOW);

        if (axi_r_trans.addr == ipif_r_trans.addr && axi_r_trans.data == ipif_r_trans.data &&
            axi_r_trans.resp == ipif_r_trans.resp) begin
          `uvm_info(get_full_name(), $sformatf("Transaction match"), UVM_LOW);
        end else begin
          error = 1;
          `uvm_info(get_full_name(), $sformatf("Transaction not match"), UVM_LOW);
        end
      end
    join
  endtask

endclass
