class axi4l_ipif_env extends uvm_env;
  `uvm_component_utils(axi4l_ipif_env)

  axi4l_ipif_agent agent0;
  axi4l_ipif_scoreboard sb0;

  function new(string name = "axi4l_ipif_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  // Create the agent and scoreboard
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent0 = axi4l_ipif_agent::type_id::create("agent0", this);
    sb0 = axi4l_ipif_scoreboard::type_id::create("sb0", this);
  endfunction

  // Connect the agent and scoreboard
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agent0.agent_ap_before.connect(sb0.sb_export_before);
    agent0.agent_ap_after.connect(sb0.sb_export_after);
  endfunction

endclass
