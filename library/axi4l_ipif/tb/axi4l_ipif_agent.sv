class axi4l_ipif_agent extends axi4l_ipif_agent;
  `uvm_component_utils(axi4l_ipif_agent)

  // Analysis ports to connect to the monitors to the scoreboard
  uvm_analysis_port #(axi4l_ipif_transaction) agent_ap_before;
  uvm_analysis_port #(axi4l_ipif_transaction) agent_ap_after;

  // Components
  axi4l_ipif_sequencer sequencer;
  axi4l_ipif_driver driver;
  axi4l_ipif_monitor_before monitor_before;
  axi4l_ipif_monitor_after monitor_after;

  function new(string name = "axi4l_ipif_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent_ap_before = new("agent_ap_before", this);
    agent_ap_after = new("agent_ap_after", this);
    sequencer = axi4l_ipif_sequencer::type_id::create("sequencer", this);
    driver = axi4l_ipif_driver::type_id::create("driver", this);
    monitor_before = axi4l_ipif_monitor_before::type_id::create("monitor_before", this);
    monitor_after = axi4l_ipif_monitor_after::type_id::create("monitor_after", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    supper.connect_phase(phase);
    driver.seq_item_port.connect(sequencer.seq_item_export);
    monitor.ap.connect(sequencer.agent_ap_before);
    monitor.ap.connect(sequencer.agent_ap_before);
  endfunction

endclass
