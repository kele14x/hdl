`timescale 1 ns / 1 ps `default_nettype none
module tb_eth_if_sim;

  // The number of ethernet ports for ORAN_IF
  parameter int NUM_ETH_PORT = 1;
  // The number of CCs for ORAN_IF
  parameter int NUM_CC = 1;
  // The number of DL layers
  parameter int NUM_DL_LAYER = 4;
  // The number of Ul layers
  parameter int NUM_UL_LAYER = 4;

  // Ethernet Port Clock Interval in PS
  parameter real ETH_CLK_INTERVAL_PS = 6400;
  // Core Clock Interval in PS
  parameter real CORE_CLK_INTERVAL_PS = 4069;


  // Ethernet Interface
  //===================

  bit        eth_port_clk            [NUM_ETH_PORT];
  bit        eth_port_rst            [NUM_ETH_PORT];

  bit [63:0] m_eth_fram_tdata        [NUM_ETH_PORT];
  bit [ 7:0] m_eth_fram_tkeep        [NUM_ETH_PORT];
  bit        m_eth_fram_tvalid       [NUM_ETH_PORT];
  bit        m_eth_fram_tlast        [NUM_ETH_PORT];
  bit        m_eth_fram_tready       [NUM_ETH_PORT] = '{NUM_ETH_PORT{1'b1}};

  bit        s_eth_mac_tuser         [NUM_ETH_PORT];
  bit        s_eth_mac_bad_fcs       [NUM_ETH_PORT];

  bit [79:0] s_eth_mac_tstamp_out    [NUM_ETH_PORT];

  bit        s_eth_mac_tstamp_valid  [NUM_ETH_PORT];

  //
  bit [63:0] s_eth_defm_tdata        [NUM_ETH_PORT];
  bit [ 7:0] s_eth_defm_tkeep        [NUM_ETH_PORT];
  bit        s_eth_defm_tvalid       [NUM_ETH_PORT];
  bit        s_eth_defm_tlast        [NUM_ETH_PORT];

  bit [63:0] m_message_tdata         [NUM_ETH_PORT];
  bit [ 7:0] m_message_tkeep         [NUM_ETH_PORT];
  bit        m_message_tvalid        [NUM_ETH_PORT];
  bit        m_message_tlast         [NUM_ETH_PORT];
  bit        m_message_tready        [NUM_ETH_PORT] = '{NUM_ETH_PORT{1'b1}};

  bit [79:0] m_message_ts_tdata      [NUM_ETH_PORT];
  bit        m_message_ts_tvalid     [NUM_ETH_PORT];

  // Internal Bus Interface
  //=======================

  bit        clk_400m;
  bit        rst_400m;

  // Radio Bus Interface
  //====================

  bit        clk_491m52;
  bit        rst_491m52;

  bit        dl_radio_start_10ms = 0;
  bit        ul_radio_start_10ms = 0;

  // DL data
  bit        dl_sof                  [      NUM_CC];
  bit        dl_sop                  [      NUM_CC];
  bit [15:0] dl_data_i               [      NUM_CC][NUM_DL_LAYER];
  bit [15:0] dl_data_q               [      NUM_CC][NUM_DL_LAYER];
  bit        dl_valid                [      NUM_CC];

  // UL data
  bit        ul_sof_ahead_3_s;
  bit        ul_sop_ahead_3_s;
  bit [15:0] ul_data_i_s;
  bit [15:0] ul_data_q_s;

  bit        ul_sof_ahead_3        [      NUM_CC];
  bit        ul_sop_ahead_3        [      NUM_CC];
  bit [15:0] ul_data_i             [      NUM_CC][NUM_UL_LAYER];
  bit [15:0] ul_data_q             [      NUM_CC][NUM_UL_LAYER];

  bit [  3:0] ctrl_bandwidth             [         NUM_CC] = '{NUM_CC{0}};
  bit [  1:0] ctrl_numerology            [         NUM_CC] = '{NUM_CC{0}};
  bit [  1:0] ctrl_compression_mode      [         NUM_CC] = '{NUM_CC{1}};

  // AXI-Lite Control/Status
  //========================

  bit        aclk;
  bit        aresetn;

  bit [15:0] s00_axi_awaddr;
  bit [ 2:0] s00_axi_awprot;
  bit        s00_axi_awvalid;
  bit        s00_axi_awready;
  //
  bit [31:0] s00_axi_wdata;
  bit [ 3:0] s00_axi_wstrb;
  bit        s00_axi_wvalid;
  bit        s00_axi_wready;
  //
  bit [ 1:0] s00_axi_bresp;
  bit        s00_axi_bvalid;
  bit        s00_axi_bready;
  //
  bit [15:0] s00_axi_araddr;
  bit [ 2:0] s00_axi_arprot;
  bit        s00_axi_arvalid;
  bit        s00_axi_arready;
  //
  bit [31:0] s00_axi_rdata;
  bit [ 1:0] s00_axi_rresp;
  bit        s00_axi_rvalid;
  bit        s00_axi_rready;
  // interrupt pin
  bit        s00_interrupt;

  bit [15:0] s01_axi_awaddr;
  bit [ 2:0] s01_axi_awprot;
  bit        s01_axi_awvalid;
  bit        s01_axi_awready;
  //
  bit [31:0] s01_axi_wdata;
  bit [ 3:0] s01_axi_wstrb;
  bit        s01_axi_wvalid;
  bit        s01_axi_wready;
  //
  bit [ 1:0] s01_axi_bresp;
  bit        s01_axi_bvalid;
  bit        s01_axi_bready;
  //
  bit [15:0] s01_axi_araddr;
  bit [ 2:0] s01_axi_arprot;
  bit        s01_axi_arvalid;
  bit        s01_axi_arready;
  //
  bit [31:0] s01_axi_rdata;
  bit [ 1:0] s01_axi_rresp;
  bit        s01_axi_rvalid;
  bit        s01_axi_rready;
  // interrupt pin
  bit        s01_interrupt;

  // Simulation Signals
  //===================

  bit        axi_done = 0;


  // Registers Configuration Tasks
  //------------------------------

  //
  // AXI Write a register
  //
  task axi_write(input logic [31:0] addr, input logic [31:0] data);
    logic [31:0] rdata;
    axi4l_vip_i.IF.master_write(addr, data);
    axi4l_vip_i.IF.master_read(addr, rdata);
    if (data != rdata) begin
      $warning("Write address with checking fail, addr = 0x%0x, write = 0x%0x, checked = 0x%0x",
               addr, data, rdata);
    end
  endtask

  //
  // AXI Read a register
  //
  task axi_read(input logic [31:0] addr, output logic [31:0] data);
    axi4l_vip_i.IF.master_read(addr, data);
  endtask

  //
  // Configure Ethernet port registers (0x61??, 0xA0??)
  //
  task eth_config();
    for (int i = 0; i < NUM_ETH_PORT; i++) begin
      $display("Start configure user_data_filter_* registers for Ethernet port %0d", i);
      // ETH_PORTS(X), 0x6100 + 0x100 * (X)
      // user_data_filter_w0
      axi_write(32'h6100 + 32'h100 * i, 32'h81EFA01C);
      axi_write(32'h6104 + 32'h100 * i, 32'hFFFF2187);
      axi_write(32'h6108 + 32'h100 * i, 32'hFFFFFFFF);
      axi_write(32'h610C + 32'h100 * i, 32'hFFFF0081);
      // user_data_filter_w0_mask
      axi_write(32'h6110 + 32'h100 * i, 32'hCFC0);
      // user_data_filter_w1
      axi_write(32'h6120 + 32'h100 * i, 32'hFFFFFFFF);
      axi_write(32'h6124 + 32'h100 * i, 32'hFFFFFFFF);
      axi_write(32'h6128 + 32'h100 * i, 32'hFFFFFFFF);
      axi_write(32'h612C + 32'h100 * i, 32'hFFFFFFFF);
      // user_data_filter_w1_mask
      axi_write(32'h6130 + 32'h100 * i, 32'hFFFF);
      // user_data_filter_w2
      axi_write(32'h6140 + 32'h100 * i, 32'hFFFFFFFF);
      axi_write(32'h6144 + 32'h100 * i, 32'hFFFFFFFF);
      axi_write(32'h6148 + 32'h100 * i, 32'hFFFFFFFF);
      axi_write(32'h614C + 32'h100 * i, 32'hFFFFFFFF);
      // user_data_filter_w2_mask
      axi_write(32'h6150 + 32'h100 * i, 32'hFFFF);
      // user_data_filter_w3
      axi_write(32'h6160 + 32'h100 * i, 32'hFFFFFFFF);
      axi_write(32'h6164 + 32'h100 * i, 32'hFFFFFFFF);
      axi_write(32'h6168 + 32'h100 * i, 32'hFFFFFFFF);
      axi_write(32'h616C + 32'h100 * i, 32'hFFFFFFFF);
      // user_data_filter_w3_mask
      axi_write(32'h6170 + 32'h100 * i, 32'hFFFF);

      $display("Start configure eth_* register for Ethernet port %0d", i);
      // ETH_PORTS(X), 0xA000 + 0x100 * (X)
      // eth_dest_addr (DU Address)
      axi_write(32'hA000 + 32'h100 * i, 32'h22334466);
      axi_write(32'hA004 + 32'h100 * i, 32'h0011);
      // eth_src_addr (RU Address)
      axi_write(32'hA008 + 32'h100 * i, 32'h22334455);
      axi_write(32'hA00C + 32'h100 * i, 32'h0011);
      // eth_vlan
      axi_write(32'hA010 + 32'h100 * i, 32'hE005);
      // eth_ipv4_0
      axi_write(32'hA030 + 32'h100 * i, 32'h54);
      // eth_ipv4_1
      axi_write(32'hA034 + 32'h100 * i, 32'h2E);
      // eth_ipv4_id
      axi_write(32'hA038 + 32'h100 * i, 32'h0);
      // eth_ipv4_2
      axi_write(32'hA03C + 32'h100 * i, 32'h2);
      // eth_ipv4_time_to_live
      axi_write(32'hA040 + 32'h100 * i, 32'h40);
      // eth_ipv4_protocol
      axi_write(32'hA040 + 32'h100 * i, 32'h11);
      // eth_ipv4_source_add
      axi_write(32'hA048 + 32'h100 * i, 32'h0);
      // eth_ipv4_destination_add
      axi_write(32'hA04C + 32'h100 * i, 32'h0);
      // eth_udp_config
      axi_write(32'hA050 + 32'h100 * i, 32'hC0008000);
      // eth_ipv6_v
      axi_write(32'hA080 + 32'h100 * i, 32'h6);
      // eth_ipv6_traffic_class
      axi_write(32'hA084 + 32'h100 * i, 32'h0);
      // eth_ipv6_flow_label
      axi_write(32'hA088 + 32'h100 * i, 32'h0);
      // eth_ipv6_next_header
      axi_write(32'hA08C + 32'h100 * i, 32'h11);
      // eth_ipv6_hop_limit
      axi_write(32'hA090 + 32'h100 * i, 32'h40);
      // eth_ipv6_source_add
      axi_write(32'hA094 + 32'h100 * i, 32'h0);
      axi_write(32'hA098 + 32'h100 * i, 32'h0);
      axi_write(32'hA09C + 32'h100 * i, 32'h0);
      axi_write(32'hA0A0 + 32'h100 * i, 32'h0);
      // eth_ipv6_destination_add
      axi_write(32'hA0A4 + 32'h100 * i, 32'h0);
      axi_write(32'hA0A8 + 32'h100 * i, 32'h0);
      axi_write(32'hA0AC + 32'h100 * i, 32'h0);
      axi_write(32'hA0B0 + 32'h100 * i, 32'h0);
    end
  endtask

  //
  // Configure common and misc registers
  //
  task common_config();
    $display("Start configure common registers");
    // timeout_value
    axi_write(32'h8, 32'h80);

    // master_int_enable
    axi_write(32'h10, 32'h1);
    // cfg_roe_interrupt_en
    axi_write(32'h14, 32'h8000FF00);

    // fram_reset
    axi_write(32'h2000, 32'h1);
    axi_write(32'h2000, 32'h0);

    // Framer, 0x2000 and 0x2200
    // fram_protocol
    axi_write(32'h2200, 32'h10);  // with VLAN
    //axi_write(32'h2200, 32'h0); // w/o VLAN

    // De-Framer, 0x6000 ~ 0x6058
    // defm_err_packet_filter
    axi_write(32'h6004, 32'h0);
    // defm_user_one_symbol_strobe
    axi_write(32'h6008, 32'h0);
    // defm_reset
    axi_write(32'h6000, 32'h1);
    axi_write(32'h6000, 32'h0);

    // [15:12] DU Port ID
    // [   11] Band Sector
    // [10: 8] CC ID
    // [ 7: 0] RU Port ID

    // defm_cid_cc_shift
    axi_write(32'h6020, 32'h8);
    // defm_cid_cc_mask
    axi_write(32'h6024, 32'h3);

    // defm_cid_bs_shift
    axi_write(32'h6028, 32'hA);
    // defm_cid_bs_mask
    axi_write(32'h602C, 32'h3);

    // defm_cid_du_shift
    axi_write(32'h6030, 32'hC);
    // defm_cid_du_mask
    axi_write(32'h6034, 32'hF);


    // 0x00 ~ 0x0F UL/DL SS (Layer)
    // 0x20 ~ 0x23 PRACH
    // 0x40 ~ 0x7F SRS (no support)

    // defm_cid_ss_mask
    axi_write(32'h6038, 32'h3);

    // defm_cid_u_mask
    axi_write(32'h603C, 32'hFC);
    // defm_cid_u_value
    axi_write(32'h6040, 32'h00);

    // defm_cid_prach_mask
    axi_write(32'h6044, 32'hFC);
    // defm_cid_prach_value
    axi_write(32'h6048, 32'h8);

    // defm_cid_ssb_mask
    axi_write(32'h604C, 32'h0);
    // defm_cid_ssb_value
    axi_write(32'h6050, 32'hFF);

    // defm_cid_lte_mask
    axi_write(32'h6054, 32'h0);
    // defm_cid_lte_value
    axi_write(32'h6058, 32'hFF);
  endtask

  //
  // Simulation only registers, used to speed up simulation
  //
  task simulation_config();
    logic [31:0] data;
    automatic int start_symbol = 177;

    start_symbol = start_symbol % 280;
    $display("Start configure simulation only registers");
    // setup_cnt
    axi_write(32'hE600, 32'd7200);
    // setup_sf
    axi_write(32'hE608, start_symbol / 28);
    // setup_sl
    axi_write(32'hE60C, (start_symbol % 28) / 14);
    // setup_sy
    axi_write(32'hE610, start_symbol % 14);
    // oran_timer_sim_cfg
    axi_write(32'hE604, 32'h0);
  endtask

  //
  // CC registers
  //
  task cc_config();
    logic [31:0] data;
    for (int i = 0; i < NUM_CC; i++) begin
      $display("Start configure CC registers for CC %0d", i);
      // CC(X), 0xE100 + 0x70 * (X)
      // oran_cc_config
      axi_write(32'hE100 + 32'h70 * i, 32'h10111);
      // cc_dl_ctrl_offsets
      axi_write(32'hE104 + 32'h70 * i, 32'h300 * i);
      // cc_dl_ctrl_unrolled_offsets
      axi_write(32'hE108 + 32'h70 * i, 32'h20 * i);
      // cc_ul_ctrl_offsets
      axi_write(32'hE10C + 32'h70 * i, 32'h300 * i);
      // cc_ul_ctrl_unrolled_offsets
      axi_write(32'hE110 + 32'h70 * i, 32'h20 * i);
      // oran_cc_num_sym_config
      axi_write(32'hE114 + 32'h70 * i, 32'h15120A00 + 32'hA * i);
      // pran_cc_ul_compression
      //axi_write(32'hE118 + 32'h70 * i, 32'h100); // raw
      axi_write(32'hE118 + 32'h70 * i, 32'h119); // bfp9
      // oran_cc_dl_compression
      //axi_write(32'hE11C + 32'h70 * i, 32'h100); // raw
      axi_write(32'hE11C + 32'h70 * i, 32'h119); // bfp9
      // cc_ul_setup_c_abs_symbol
      axi_write(32'hE120 + 32'h70 * i, 32'h4);
      // cc_ul_setup_c_cycles
      axi_write(32'hE124 + 32'h70 * i, 32'h1D35);
      // cc_ul_setup_d_cycles
      axi_write(32'hE128 + 32'h70 * i, 32'h2249);
      // cc_dl_setup_c_abs_symbol
      axi_write(32'hE130 + 32'h70 * i, 32'h4);
      // cc_dl_setup_c_cycles
      axi_write(32'hE134 + 32'h70 * i, 32'hC58);
      // cc_dl_setup_d_cycles
      axi_write(32'hE138 + 32'h70 * i, 32'h1D7D);
      // cc_ul_base_offset
      axi_write(32'hE140 + 32'h70 * i, 32'h20 * i);
      // cc_ul_bidf_c_abs_symbol
      axi_write(32'hE144 + 32'h70 * i, 32'h4);
      // cc_ul_bidf_c_cycles
      axi_write(32'hE148 + 32'h70 * i, 32'h1075);
      // cc_max_symbols
      axi_write(32'hE158 + 32'h70 * i, 32'h118);
      // cc_num_ctrl_per_symbol_dl
      axi_write(32'hE160 + 32'h70 * i, 32'h20);
      // cc_num_ctrl_per_symbol_ul
      axi_write(32'hE164 + 32'h70 * i, 32'h20);
      // cc_modvals_dl
      axi_write(32'hE168 + 32'h70 * i, 32'h240);
      // cc_modvals_ul
      axi_write(32'hE16C + 32'h70 * i, 32'h2A0);
    end

    // cc_dl_data_unroll_offset
    axi_write(32'hE500, 32'h0);
    axi_write(32'hE504, 32'h3F8);
    axi_write(32'hE508, 32'h7F0);
    axi_write(32'hE50C, 32'hBE8);
    axi_write(32'hE510, 32'hFE0);
    axi_write(32'hE514, 32'h13D8);
    axi_write(32'hE518, 32'h17D0);
    axi_write(32'hE51C, 32'h1BC8);
    axi_write(32'hE520, 32'h1FC0);
    axi_write(32'hE524, 32'h23B8);

    // TODO: SSB related register

  endtask

  //
  // CC registers
  //
  task enable_cc();
    logic [31:0] data = '0;
    for (int i = 0; i < NUM_CC; i++) begin
      data[i] = 1'b1;
    end

    $display("Enable and reload CC");
    // cc_reload
    axi_write(32'hE000, data);
    // cc_enable
    axi_write(32'hE004, data);
  endtask

  // Registers Checking Tasks
  //-------------------------

  //
  // Check all hdl configuration related registers (0x0 ~ 0x110)
  //
  task check_cfg_regs();
    logic [31:0] data;

    // cfg_version
    axi_read(32'h0, data);
    $display("oran_radio_if version: %0d.%0d.%0d", data[31:24], data[23:16], data[15:8]);
    // internal_revision
    axi_read(32'h4, data);
    $display("oran_radio_if reversion: 0x%x", data);
    // cfg_antenna_counts
    axi_read(32'h20, data);
    $display("oran_radio_if max number of antennas supported by Deframer/Framer: %0d/%0d",
             data[31:16], data[15:0]);

    $display("HDL configuration registers:");
    for (int addr = 16'h24; addr <= 16'h110; addr = addr + 4) begin
      axi_read(addr, data);
      $display("0x%0x: %0d:", addr, data);
    end
    $display("");

  endtask

  //
  // Check all Ethernet statistics registers (0xC000 ~ 0xC084)
  //
  task check_eth_stat_regs();
    logic [31:0] data;

    // defm_stats_ctrl
    axi_write(16'h6010, 32'hFFFFFFFF);
    #(100 * 1000);
    axi_write(16'h6010, 32'hFFFFFFFF);

    for (int i = 0; i < NUM_ETH_PORT; i++) begin
      $display("Statistics registers for Ethernet port %0d:", i);
      for (int addr = 16'hC000; addr <= 16'hC084; addr = addr + 4) begin
        axi_read(addr, data);
        $display("0x%0x: %0d:", addr, data);
      end
    end
    $display("");

  endtask


  // Clock Generation
  //-----------------

  // AXI clock runs at 100 MHz
  initial begin
    aclk = 0;
    forever begin
      #5 aclk = ~aclk;
    end
  end

  // Internal bus clock runs at 400 MHz
  initial begin
    #2;
    clk_400m = 0;
    forever begin
      #(CORE_CLK_INTERVAL_PS/2000) clk_400m = ~clk_400m;
    end
  end

  // Internal bus clock runs at 400 MHz
  initial begin
    clk_491m52 = 0;
    forever begin
      #(1.017) clk_491m52 = ~clk_491m52;
    end
  end

  // Ethernet clock runs at 390.625 Mhz
  generate
    for (genvar i = 0; i < NUM_ETH_PORT; i++) begin
      initial begin
        eth_port_clk[i] = 0;
        forever begin
          #(ETH_CLK_INTERVAL_PS/2000) eth_port_clk[i] = ~eth_port_clk[i];
        end
      end
    end
  endgenerate


  // Reset Generation
  //-----------------

  // Sync with aclk
  initial begin
    aresetn = 0;
    repeat (100) @(posedge aclk);
    aresetn <= 1;
  end

  // Async reset
  initial begin
    rst_400m = 1;
    repeat (100) @(posedge clk_400m);
    rst_400m <= 0;
  end

  // Async reset
  initial begin
    rst_491m52 = 1;
    repeat (100) @(posedge clk_491m52);
    rst_491m52 <= 0;
  end

  // ETH reset
  initial begin
    eth_port_rst = '{NUM_ETH_PORT{1'b1}};
    repeat (100) @(posedge eth_port_clk[0]);
    eth_port_rst = '{NUM_ETH_PORT{1'b0}};
  end

  // AXI Port Stimulation
  //---------------------

  initial begin
    logic [31:0] data;
    $display("****Simulation starts");
    axi4l_vip_i.set_master_mode();
    axi4l_vip_i.IF.reset();
    wait(aresetn);
    @(posedge aclk);

    simulation_config();

    // Check HDL configurations
    check_cfg_regs();

    // Configure
    common_config();
    eth_config();
    cc_config();

    $display("Done AXI registers configuration");
    axi_done = 1;

    // Wait to enable CC
    #(50 * 1000 - $time());  // wait to 50 us
    enable_cc();

    forever begin
      // Wait interrupt
      @(posedge aclk);
      if (s00_interrupt) begin
        $display("Warning: Interrupt is assert!");
        axi_read(16'h0018, data);
        $display("Interrupt status: 0x%0x", data);
        // Clear master interupt enable
        axi_write(16'h0010, 32'h0);
        axi_write(16'h0010, 32'h1);
      end
    end
  end

  // Ends
  final begin
    $display("****Simulation ends");
  end


  // Ethernet Stimulation
  //---------------------

  initial begin
    #(158 * 1000 + 868);  // wait to 150 us
    g_eth_injector[0].eth_injector_i.play_pcap("prach_jp.pcap");
    #10000;
    $finish();
  end


  // 10ms strob generation
  //----------------------

  initial begin
    wait(~rst_491m52);

    #(10 * 1000 * 1000);  // 10ms us

    forever begin
      @(posedge clk_491m52);
      dl_radio_start_10ms <= 1'b1;
      ul_radio_start_10ms <= 1'b1;
      @(posedge clk_491m52);
      dl_radio_start_10ms <= 1'b0;
      ul_radio_start_10ms <= 1'b0;
      repeat (4915200 - 2) @(posedge clk_491m52);
    end
  end


  // Module Instances
  //=================

  axi4l_vip #(
      .C_ADDR_WIDTH(16),
      .C_DATA_WIDTH(32)
  ) axi4l_vip_i (
      .aclk         (aclk),
      .aresetn      (aresetn),
      //
      .m_axi_awaddr (s00_axi_awaddr),
      .m_axi_awprot (s00_axi_awprot),
      .m_axi_awvalid(s00_axi_awvalid),
      .m_axi_awready(s00_axi_awready),
      //
      .m_axi_wdata  (s00_axi_wdata),
      .m_axi_wstrb  (s00_axi_wstrb),
      .m_axi_wvalid (s00_axi_wvalid),
      .m_axi_wready (s00_axi_wready),
      //
      .m_axi_bresp  (s00_axi_bresp),
      .m_axi_bvalid (s00_axi_bvalid),
      .m_axi_bready (s00_axi_bready),
      //
      .m_axi_araddr (s00_axi_araddr),
      .m_axi_arprot (s00_axi_arprot),
      .m_axi_arvalid(s00_axi_arvalid),
      .m_axi_arready(s00_axi_arready),
      //
      .m_axi_rdata  (s00_axi_rdata),
      .m_axi_rresp  (s00_axi_rresp),
      .m_axi_rvalid (s00_axi_rvalid),
      .m_axi_rready (s00_axi_rready)
  );

  axi4l_vip #(
      .C_ADDR_WIDTH(16),
      .C_DATA_WIDTH(32)
  ) axi4l_vip_i2 (
      .aclk         (aclk),
      .aresetn      (aresetn),
      //
      .m_axi_awaddr (s01_axi_awaddr),
      .m_axi_awprot (s01_axi_awprot),
      .m_axi_awvalid(s01_axi_awvalid),
      .m_axi_awready(s01_axi_awready),
      //
      .m_axi_wdata  (s01_axi_wdata),
      .m_axi_wstrb  (s01_axi_wstrb),
      .m_axi_wvalid (s01_axi_wvalid),
      .m_axi_wready (s01_axi_wready),
      //
      .m_axi_bresp  (s01_axi_bresp),
      .m_axi_bvalid (s01_axi_bvalid),
      .m_axi_bready (s01_axi_bready),
      //
      .m_axi_araddr (s01_axi_araddr),
      .m_axi_arprot (s01_axi_arprot),
      .m_axi_arvalid(s01_axi_arvalid),
      .m_axi_arready(s01_axi_arready),
      //
      .m_axi_rdata  (s01_axi_rdata),
      .m_axi_rresp  (s01_axi_rresp),
      .m_axi_rvalid (s01_axi_rvalid),
      .m_axi_rready (s01_axi_rready)
  );

  generate
    for (genvar i = 0; i < NUM_ETH_PORT; i++) begin : g_eth_injector
      eth_injector eth_injector_i (
          // Clocks
          .aclk        (eth_port_clk[i]),
          .aresetn     (~eth_port_rst[i]),
          // Data interface
          .m_eth_tdata (s_eth_defm_tdata[i]),
          .m_eth_tkeep (s_eth_defm_tkeep[i]),
          .m_eth_tvalid(s_eth_defm_tvalid[i]),
          .m_eth_tlast (s_eth_defm_tlast[i]),
          .m_eth_tready(1'b1)
      );
    end
  endgenerate

  eth_if_sim #(
      .NUM_CC(NUM_CC),
      .NUM_ETH_PORT(NUM_ETH_PORT),
      .NUM_DL_LAYER(NUM_DL_LAYER),
      .NUM_UL_LAYER(NUM_UL_LAYER)
  ) DUT (
      .*
  );

  ul_traffic_gen i_ul_traffic_gen (
    .clk                (clk_491m52),
    .rst                (rst_491m52),
    //
    .ul_radio_start_10ms(ul_radio_start_10ms),
    //
    .ul_sof_ahead_3     (ul_sof_ahead_3_s),
    .ul_sop_ahead_3     (ul_sop_ahead_3_s),
    .ul_data_i          (ul_data_i_s),
    .ul_data_q          (ul_data_q_s),
    // Control
    .ctrl_numerology    ('0)
  );

  generate
    for (genvar cc = 0; cc < NUM_CC; cc++) begin : g_ul_s
      assign ul_sof_ahead_3[cc] = ul_sof_ahead_3_s;
      assign ul_sop_ahead_3[cc] = ul_sop_ahead_3_s;
      for (genvar ss = 0; ss < NUM_UL_LAYER; ss++) begin
        assign ul_data_i[cc][ss] = ul_data_i_s;
        assign ul_data_q[cc][ss] = ul_data_q_s;
      end
    end
  endgenerate

endmodule

`default_nettype wire
