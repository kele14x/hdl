class axi4l_ipif_driver extends uvm_driver #(axi4l_ipif_transaction);
  `uvm_component_utils(axi4l_ipif_driver)

  virtual axi4l_ipif_if vif;

  function new (string name = "axi4l_ipif_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(axi4l_ipif_if).get(this, "axi4l_ipif_driver", "vif", vif)) begin
      `uvm_fatal(get_full_name(), $sformatf("vif not found"));
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    reset();
    forever begin
      seq_item_port.get_next_item(seq);
      drive();
      @(vif.dr_cb);
      $cast(rsp ,req.clone());
      rsp.set_id_info(req);
      seq_item_port.item_done(seq);
      seq_item_port.put(rsp);
    end
  endtask

  task drive();
    wait(vif.aresetn);
    @(vif.dr_cb);
    if (req.wrn) begin
      vif.dr_cb.s_axi_awaddr <= req.addr;
      vif.dr_cb.s_axi_awvalid <= 1'b1;
      //
      vif.dr_cb.s_axi_wdata <= req.data;
      vif.dr_cb.s_axi_wvalid <= 1'b1;
      //
      vif.dr_cb.s_axi_bready <= 1'b1;
    end else begin
      vif.dr_cb.s_axi_araddr <= req.addr;
      vif.dr_cb.s_axi_arvalid <= 1'b1;
      //
      vif.dr_cb.s_axi_rready <= 1'b1;
    end
  endtask

  task reset();
    vif.dr_cb.s_axi_awaddr <= 0;
    vif.dr_cb.s_axi_awprot <= 0;
    vif.dr_cb.s_axi_awvalid <= 0;
    //
    vif.dr_cb.s_axi_wdata <= 0;
    vif.dr_cb.s_axi_wstrb <= 0;
    vif.dr_cb.s_axi_wvalid <= 0;
    //
    vif.dr_cb.s_axi_bready <= 0;
    //
    vif.dr_cb.s_axi_araddr <= 0;
    vif.dr_cb.s_axi_arprot <= 0;
    vif.dr_cb.s_axi_arvalid <= 0;
    //
    vif.dr_cb.s_axi_rready <= 0;
    // IP i/f
    //=======
    vif.dr_cb.ipif_wr_ack <= 0;
    vif.dr_cb.ipif_wr_err <= 0;
    //
    vif.dr_cb.ipif_rd_data <= 0;
    vif.dr_cb.ipif_rd_ack <= 0;
    vif.dr_cb.ipif_rd_err <= 0;
  endtask

endclass
