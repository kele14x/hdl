// File: axis_slv_driver.sv
// Brief: AXI4-Stream Slave UVM Driver

class axis_slv_driver extends uvm_driver #(axis_transaction);
  `uvm_component_utils(axis_slv_driver)

  virtual axis_if vif;

  function new(string name = "axis_slv_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction

  virtual task run_phase(uvm_phase phase);
    reset();
    forever begin
      seq_item_port.get_next_item(req);
      drive();
      seq_item_port.item_done(seq);
    end
  endtask

  function void set_vif(axis_if vif);
    this.vif = vif;
  endfunction

  task drive();
    wait (vif.aresetn);
    @(posedge vif.aclk);
    vif.tready <= 1'b1;
    forever begin
      @(posedge vif.aclk);
      if (vif_in.tvalid) begin
        vif.tready <= 1'b0;
        break;
      end
    end
  endtask

  task reset();
    vif_in.tready <= 1'b0;
  endtask

endclass
