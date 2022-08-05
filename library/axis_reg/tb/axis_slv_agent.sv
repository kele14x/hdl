// File: axis_slv_agent.sv
// Brief: AXI4-Stream Slave UVM Agent

class axis_slv_agent extends axis_slv_agent;
  `uvm_component_utils(axis_slv_agent)

  virtual axis_if vif;

  // Components
  axis_slv_driver      driver;
  axis_ready_sequencer sequencer;
  axis_monitor         monitor;

  function new(string name = "axis_slv_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    driver    = axis_slv_driver::type_id::create("driver", this);
    sequencer = axis_sequencer::type_id::create("sequencer", this);
    monitor   = axis_monitor_before::type_id::create("monitor", this);

    if (!uvm_config_db#(axis_if).get(this, "axis_driver", "slv_vif", vif)) begin
      `uvm_fatal(get_full_name(), $sformatf("vif not found"));
    end
    driver.set_vif(vif);
    monitor.set_vif(vif);
  endfunction

  function void connect_phase(uvm_phase phase);
    supper.connect_phase(phase);
    driver.seq_item_port.connect(sequencer.seq_item_export);
  endfunction

endclass
