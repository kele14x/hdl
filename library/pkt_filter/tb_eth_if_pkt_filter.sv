//-----------------------------------------------------------------------------
// File: tb_eth_if_pkt_filter.sv
// Brief: Testbench for module eth_if_pkt_filter
//-----------------------------------------------------------------------------
`timescale 1 ns / 1 ps `default_nettype none

module tb_eth_if_pkt_filter;

  parameter int ADDR_WIDTH = 12;

  logic        aclk;
  logic        aresetn;
  // Input
  logic [63:0] s_axis_tdata;
  logic [ 7:0] s_axis_tkeep;
  logic        s_axis_tvalid;
  logic        s_axis_tlast;
  logic        s_axis_tready;
  // Sideband signal
  logic        s_mac_tuser;
  logic        s_mac_bad_fcs;
  logic [79:0] s_mac_tstamp_out;
  logic        s_mac_tstamp_valid;
  // Output
  logic [63:0] m_axis_tdata;
  logic [ 7:0] m_axis_tkeep;
  logic        m_axis_tvalid;
  logic        m_axis_tlast;
  logic        m_axis_tready;
  //
  logic [79:0] m_mac_tstamp_out;
  logic        m_mac_tstamp_valid;

  initial begin
    forever begin
      #1 aclk = 0;
      #1 aclk = 1;
    end
  end

  initial begin
    aresetn = 0;
    repeat (10) @(posedge aclk);
    aresetn <= 1;
  end


  initial begin
    $display("*** Simulation start ***");

    s_axis_tdata = '0;
    s_axis_tkeep = '0;
    s_axis_tvalid = '0;
    s_axis_tlast = '0;
    s_mac_tuser = '0;
    s_mac_bad_fcs = '0;
    s_mac_tstamp_out = '0;
    s_mac_tstamp_valid = '0;
    //
    m_axis_tready = '0;

    // wait reset done
    forever begin
      @(posedge aclk);
      if (aresetn) break;
    end

    fork
      begin : p_feed_packet
        @(posedge aclk);
        for (int i = 0; i < 16; i++) begin
          s_axis_tdata  <= 100 + i;
          s_axis_tvalid <= 1;
          s_axis_tlast  <= (i == 15);
          forever begin
            @(posedge aclk);
            if (s_axis_tready) break;
          end
        end
        s_axis_tvalid <= 0;
      end

      begin : p_check_packet
        @(posedge aclk);
        m_axis_tready <= 1;
      end
    join

  end

  eth_if_pkt_filter #(.ADDR_WIDTH(ADDR_WIDTH)) UUT (.*);

endmodule

`default_nettype none
