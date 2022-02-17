//-----------------------------------------------------------------------------
// File: tb_eth_pkt_fifo.sv
// Brief: Testbench for module eth_pkt_fifo
//-----------------------------------------------------------------------------
`timescale 1 ns / 1 ps `default_nettype none

module tb_eth_pkt_fifo;

  parameter int ADDR_WIDTH = 12;

  logic        aclk;
  logic        aresetn;
  //
  logic [63:0] m_axis_tdata;
  logic [ 7:0] m_axis_tkeep;
  logic        m_axis_tvalid;
  logic        m_axis_tlast;
  logic        m_axis_tready;
  logic        m_axis_tuser;
  //
  logic [63:0] s_axis_tdata;
  logic [ 7:0] s_axis_tkeep;
  logic        s_axis_tvalid;
  logic        s_axis_tlast;
  logic        s_axis_tready;

  initial begin
    forever begin
      #1 aclk = 0;
      #1 aclk = 1;
    end
  end

  initial begin
    aresetn = 0;
    repeat (16) @(posedge aclk);
    @(posedge aclk);
    aresetn <= 1;
  end


  initial begin
    $display("*** Simulation starts ***");

    m_axis_tdata  <= 0;
    m_axis_tkeep  <= 0;
    m_axis_tvalid <= 0;
    m_axis_tlast  <= 0;
    m_axis_tuser  <= 0;
    //
    s_axis_tready <= 0;

    forever @(posedge aclk) if (aresetn) break;

    //*************************************************************************
    fork
      begin
        @(posedge aclk);
        m_axis_tdata  <= 1;
        m_axis_tvalid <= 1;
        m_axis_tlast  <= 1;
        forever @(posedge aclk) if (m_axis_tready) break;
        m_axis_tdata  <= 0;
        m_axis_tvalid <= 0;
        m_axis_tlast  <= 0;
      end

      begin
        repeat(7) @(posedge aclk);
        s_axis_tready <= 1;
        @(posedge aclk);
        s_axis_tready <= 0;
        end
    join


    #1000;
    $display("*** Simulation ends ***");
    $finish();
  end

  eth_pkt_fifo #(
      .ADDR_WIDTH(ADDR_WIDTH)
  ) UUT (
      .aclk               (aclk),
      .aresetn            (aresetn),
      //
      .s_axis_tdata       (m_axis_tdata),
      .s_axis_tkeep       (m_axis_tkeep),
      .s_axis_tlast       (m_axis_tlast),
      .s_axis_tready      (m_axis_tready),
      .s_axis_tvalid      (m_axis_tvalid),
      .s_axis_tuser       (m_axis_tuser),
      //
      .s_axis_tstamp_out  (80'b0),
      .s_axis_tstamp_valid(1'b0),
      // Output
      .m_axis_tdata       (s_axis_tdata),
      .m_axis_tkeep       (s_axis_tkeep),
      .m_axis_tlast       (s_axis_tlast),
      .m_axis_tready      (s_axis_tready),
      .m_axis_tvalid      (s_axis_tvalid),
      //
      .m_axis_tstamp_out  (  /* open */),
      .m_axis_tstamp_valid(  /* open */)
  );

endmodule

`default_nettype none
