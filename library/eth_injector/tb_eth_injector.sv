`timescale 1 ns / 1 ps `default_nettype none

module tb_eth_injector;

  parameter TDATA_WIDTH = 64;

  logic                     aclk;
  logic                     aresetn;
  logic [  TDATA_WIDTH-1:0] m_eth_tdata;
  logic [TDATA_WIDTH/8-1:0] m_eth_tkeep;
  logic                     m_eth_tvalid;
  logic                     m_eth_tlast;
  logic                     m_eth_tready;

  eth_injector #(
      .PCAP_FILENAME("ethdata_port_0.pcap"),
      .TDATA_WIDTH  (TDATA_WIDTH)
  ) DUT (
      .aclk        (aclk),
      .aresetn     (aresetn),
      // Data interface
      .m_eth_tdata (m_eth_tdata),
      .m_eth_tkeep (m_eth_tkeep),
      .m_eth_tvalid(m_eth_tvalid),
      .m_eth_tlast (m_eth_tlast),
      .m_eth_tready(m_eth_tready)
  );

  initial begin
    aclk = 0;
    forever begin
      #(1.28) aclk = ~aclk;
    end
  end

  initial begin
    aresetn = 0;
    repeat (16) @(posedge aclk);
    aresetn <= 1;
    tb_eth_injector.DUT.play_pcap("ethdata_port_0.pcap");
    #1000;
    $display("Simulation ends with no error.");
    $finish();
  end

  assign m_eth_tready = 1;

endmodule

`default_nettype wire
