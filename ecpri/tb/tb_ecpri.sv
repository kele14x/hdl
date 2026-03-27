`timescale 1 ns / 1 ps
//
`default_nettype none

module tb_ecpri;

  // AXI-Lite I/F
  //-------------
  logic        s_axi_aclk;
  logic        s_axi_aresetn;
  //
  logic [31:0] s_axi_awaddr;
  logic [ 2:0] s_axi_awprot;
  logic        s_axi_awvalid;
  logic        s_axi_awready;
  //
  logic [31:0] s_axi_wdata;
  logic [ 3:0] s_axi_wstrb;
  logic        s_axi_wvalid;
  logic        s_axi_wready;
  //
  logic [ 1:0] s_axi_bresp;
  logic        s_axi_bvalid;
  logic        s_axi_bready;
  //
  logic [31:0] s_axi_araddr;
  logic [ 2:0] s_axi_arprot;
  logic        s_axi_arvalid;
  logic        s_axi_arready;
  //
  logic [31:0] s_axi_rdata;
  logic [ 1:0] s_axi_rresp;
  logic        s_axi_rvalid;
  logic        s_axi_rready;
  // Ethernet I/F
  //-------------
  // Rx Ethernet ports
  logic        rx_eth_clk;
  logic        rx_eth_rst;
  //
  logic [31:0] s_eth_defm_tdata;
  logic [ 3:0] s_eth_defm_tkeep;
  logic        s_eth_defm_tlast;
  logic        s_eth_defm_tuser;
  logic        s_eth_defm_tvalid;
  // Tx Ethernet ports
  logic        tx_eth_clk;
  logic        tx_eth_rst;
  //
  logic [31:0] m_eth_fram_tdata;
  logic [ 3:0] m_eth_fram_tkeep;
  logic        m_eth_fram_tlast;
  logic        m_eth_fram_tuser;
  logic        m_eth_fram_tvalid;
  logic        m_eth_fram_tready;
  // PTP ports
  logic [79:0] rx_ptp_timestamp;
  logic        rx_ptp_timestamp_valid;
  //
  logic [ 1:0] tx_ptp_1588op;
  logic [15:0] tx_ptp_tag_field;
  logic [79:0] tx_ptp_timestamp;
  logic [15:0] tx_ptp_timestamp_tag;
  logic        tx_ptp_timestamp_valid;
  // PTP Control Interface
  logic [79:0] ctl_rx_systemtimer;
  logic [79:0] ctl_tx_systemtimer;
  // Internal interface
  //-------------------
  logic        clk;
  logic        rst;
  //
  logic        pps_in;
  //
  logic [47:0] tod_sec;
  logic [31:0] tod_ns;
  // Deframer ports
  logic [31:0] m_axis_tdata;
  logic [ 3:0] m_axis_tkeep;
  logic        m_axis_tlast;
  logic        m_axis_tvalid;
  //
  logic        m_mac_header_valid;
  logic [47:0] m_mac_dest_mac;
  logic [47:0] m_mac_source_mac;
  logic        m_mac_with_vlan;
  logic [15:0] m_mac_vlan_tag;
  logic [15:0] m_mac_ethertype;
  //
  logic        m_ecpri_header_valid;
  logic        m_ecpri_concat;
  logic [ 7:0] m_ecpri_messagetype;
  logic [15:0] m_ecpri_payloadsize;
  //
  logic        m_trans_header_valid;
  logic [15:0] m_trans_rtc_pc_id;
  logic [ 7:0] m_trans_seqid;
  logic        m_trans_ebit;
  logic [ 6:0] m_trans_subseqid;
  //
  logic [31:0] m_ptp_tdata;
  logic [ 3:0] m_ptp_tkeep;
  logic        m_ptp_tlast;
  logic [79:0] m_ptp_tuser;
  logic        m_ptp_tvalid;
  logic        m_ptp_tready;
  //
  logic [31:0] m_message_tdata;
  logic [ 3:0] m_message_tkeep;
  logic        m_message_tlast;
  logic        m_message_tvalid;
  logic        m_message_tready;
  // Framer ports
  logic [31:0] s_axis_tdata;
  logic [ 3:0] s_axis_tkeep;
  logic        s_axis_tlast;
  logic        s_axis_tvalid;
  logic        s_axis_tready;
  //
  logic [ 7:0] s_trans_messagetype;
  logic [15:0] s_trans_payloadsize;
  logic [15:0] s_trans_rtc_pc_id;
  //
  logic [31:0] s_ptp_tdata;
  logic [ 3:0] s_ptp_tkeep;
  logic        s_ptp_tlast;
  logic [17:0] s_ptp_tuser;
  logic        s_ptp_tvalid;
  logic        s_ptp_tready;
  //
  logic [31:0] s_message_tdata;
  logic [ 3:0] s_message_tkeep;
  logic        s_message_tlast;
  logic        s_message_tvalid;
  logic        s_message_tready;

  `include "tb_axi4l.svh"

  // Clock and reset

  initial begin
    s_axi_aclk = 0;
    forever #5 s_axi_aclk = ~s_axi_aclk;
  end

  initial begin
    s_axi_aresetn = 0;
    repeat (10) @(posedge s_axi_aclk);
    s_axi_aresetn <= 1;
  end

  initial begin
    rx_eth_clk = 0;
    forever #(1.6) rx_eth_clk = ~rx_eth_clk;
  end

  initial begin
    rx_eth_rst = 1;
    repeat (10) @(posedge rx_eth_clk);
    rx_eth_rst <= 0;
  end

  initial begin
    tx_eth_clk = 0;
    forever #(1.6) tx_eth_clk = ~tx_eth_clk;
  end

  initial begin
    tx_eth_rst = 1;
    repeat (10) @(posedge tx_eth_clk);
    tx_eth_rst <= 0;
  end

  initial begin
    clk = 0;
    forever #1 clk = ~clk;
  end

  initial begin
    rst = 1;
    repeat (10) @(posedge clk);
    rst <= 0;
  end

  // Stimulus

  initial begin
    logic [31:0] data;
    $display("*** Simulation started ***");

    axi_reset();
    wait (s_axi_aresetn);

    // Register read/write test

    axi_read('h0, data);
    assert (data == 32'h20230411);

    axi_write('h4, 32'h12345678);
    axi_read('h4, data);
    assert (data == 32'h12345678);

    axi_write('h8, 32'h5A5AA5A5);
    axi_read('h8, data);
    assert (data == 32'h5A5AA5A5);

    $info("AXI register test pass");

    // defm_ctrl
    axi_write('h100, 32'h1);
    // fram_ctrl
    axi_write('h200, 32'h1);
    // ODM
    axi_write('h300, 32'h1);
    axi_write('h308, 32'd10000);

    #1000000;
    $finish();
  end

  final begin
    $display("*** Simulation finished ***");
  end

  // Ethernet ports

  // Loopback connection
  assign s_eth_defm_tdata  = m_eth_fram_tdata;
  assign s_eth_defm_tkeep  = m_eth_fram_tkeep;
  assign s_eth_defm_tlast  = m_eth_fram_tlast;
  assign s_eth_defm_tuser  = m_eth_fram_tuser;
  assign s_eth_defm_tvalid = m_eth_fram_tvalid;

  assign m_eth_fram_tready = 1;


  // Framer ports

  initial begin
    int packet_nbyte;
    int packet_nword;
    int ipg;

    s_axis_tdata = 0;
    s_axis_tkeep = 0;
    s_axis_tlast = 0;
    s_axis_tvalid = 0;
    //
    s_trans_messagetype = 0;
    s_trans_payloadsize = 0;
    s_trans_rtc_pc_id = 0;
    wait (!rst);
    @(posedge clk);

    forever begin
      // Send packet
      packet_nbyte = $urandom_range(20, 4000);
      packet_nword = (packet_nbyte + 3) / 4;
      ipg = $urandom_range(1000, 2000);

      s_trans_messagetype <= $urandom_range(0, 256);
      s_trans_payloadsize <= packet_nbyte;
      s_trans_rtc_pc_id <=  $urandom_range(0, 32768);

      for (int w = 0; w < packet_nword; w++) begin
        s_axis_tdata <= '0;
        s_axis_tkeep <= '0;
        for (int b = 0; b < 4; b++) begin
          if (w * 4 + b < packet_nbyte) begin
            s_axis_tdata[b*8+7-:8] <= $urandom_range(255);
            s_axis_tkeep[b] <= 1'b1;
          end
        end
        s_axis_tvalid <= 1;
        s_axis_tlast  <= (w == packet_nword - 1);
        // Check if the word is accepted
        forever begin
          @(posedge clk);
          if (s_axis_tready) break;
        end
      end
      s_axis_tvalid <= 0;

      // Wait for inter-packet gap
      repeat (ipg) @(posedge clk);
    end
  end

  // Message ports

  initial begin
    int packet_nbyte;
    int packet_nword;
    int ipg;

    s_message_tdata  = 0;
    s_message_tkeep  = 0;
    s_message_tlast  = 0;
    s_message_tvalid = 0;
    wait (!rst);
    @(posedge clk);

//    forever begin
//      // Send packet
//      packet_nbyte = $urandom_range(20, 1500);
//      packet_nword = (packet_nbyte + 3) / 4;
//      ipg = $urandom_range(1000, 2000);

//      for (int w = 0; w < packet_nword; w++) begin
//        s_message_tdata <= '0;
//        s_message_tkeep <= '0;
//        for (int b = 0; b < 4; b++) begin
//          if (w * 4 + b < packet_nbyte) begin
//            s_message_tdata[b*8+7-:8] <= $urandom_range(255);
//            s_message_tkeep[b] <= 1'b1;
//          end
//        end
//        s_message_tvalid <= 1;
//        s_message_tlast  <= (w == packet_nword - 1);
//        // Check if the word is accepted
//        forever begin
//          @(posedge clk);
//          if (s_message_tready) break;
//        end
//      end
//      s_message_tvalid <= 0;

//      // Wait for inter-packet gap
//      repeat (ipg) @(posedge clk);
//    end
  end

  // DUT

  ecpri DUT (.*);

endmodule

`default_nettype wire
