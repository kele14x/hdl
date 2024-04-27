// File: axp4l_ipif_monitor.sv
// Brief: IPIF monitor for AXP4L

class axi4l_ipif_monitor #(
    parameter int ADDR_WIDTH = 12,
    parameter int DATA_WIDTH = 32
) extends uvm_monitor;
  `uvm_component_utils(axi4l_ipif_monitor)

  uvm_analysis_port #(axi4l_ipif_transaction) mon_ap_before;

  axi4l_ipif_transaction tx_trans;
  axi4l_ipif_transaction rx_trans;

  // AXI4-Lite data queue

  logic [ADDR_WIDTH-1:0] AW_queue[$];
  logic [DATA_WIDTH-1:0] W_queue[$];
  logic [           1:0] B_queue[$];
  logic [ADDR_WIDTH-1:0] AR_queue[$];
  logic [DATA_WIDTH-1:0] R_queue[$];


  virtual axi4l_ipif_if vif;

  // Constructor
  function new(string name = "axi4l_ipif_monitor", uvm_component parent = null);
    super.new(name, parent);
    mon_ap_before = new("mon_ap_before", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(axi4l_ipif_if)::get(this, "axi4l_ipif_monitor", "vif", vif)) begin
      `uvm_fatal(get_full_name(), $sformatf("vif not found"));
    end
  endfunction

  task run_phase(uvm_phase phase);
    fork

      forever begin : p_aw
        @(rc_cb iff (vif.rc_cb.s_axi_awvalid && vif.rc_cb.s_axi_awready)) begin
          AW_queue.push_back(vif.rc_cb.s_axi_awaddr);
        end
      end

      forever begin: p_w
        @(rc_cb iff (vif.rc_cb.s_axi_wvalid && vif.rc_cb.s_axi_wready)) begin
          W_queue.push_back(vif.rc_cb.s_axi_wdata);
        end
      end

      forever begin : p_b
        @(rc_cb iff (vif.rc_cb.s_axi_bvalid && vif.rc_cb.s_axi_bready)) begin
          B_queue.push_back(vif.rc_cb.s_axi_bresp);
        end
      end

      forever begin : p_ar
        @(rc_cb iff (vif.rc_cb.s_axi_arvalid && vif.rc_cb.s_axi_arready)) begin
          AR_queue.push_back(vif.rc_cb.s_axi_araddr);
        end
      end

      forever begin : p_r
        @(rc_cb iff (vif.rc_cb.s_axi_rvalid && vif.rc_cb.s_axi_rready)) begin
          R_queue.push_back(vif.rc_cb.s_axi_rdata);
        end
      end

      forever begin : p_tx_trans
        @(rc_cb) begin
          if (AW_queue.size() > 0 && W_queue.size() > 0 && B_queue.size() > 0) begin
            mon2sb_port.write(w_trans);
          end
        end
      end

      forever begin : p_tx_trans
        @(rc_cb) begin
          if (AR_queue.size() > 0 && R_queue.size() > 0) begin
            mon2sb_port.write(w_trans);
          end
        end
      end

    join
  endtask

endclass
