`timescale 1 ns / 1 ps
`default_nettype none

module eth_injector_tb #(
    parameter string PCAP_FILE = ""
) (
    input  wire        aclk,
    input  wire        aresetn,
    output wire [63:0] m_eth_tdata,
    output wire [ 7:0] m_eth_tkeep,
    output wire        m_eth_tvalid,
    output wire        m_eth_tlast,
    input  wire        m_eth_tready
);

  eth_injector #(
      .TDATA_WIDTH(64)
  ) i_eth_injector (
      .aclk        (aclk),
      .aresetn     (aresetn),
      .m_eth_tdata (m_eth_tdata),
      .m_eth_tkeep (m_eth_tkeep),
      .m_eth_tvalid(m_eth_tvalid),
      .m_eth_tlast (m_eth_tlast),
      .m_eth_tready(m_eth_tready)
  );

  initial begin
    @(posedge aresetn);
    i_eth_injector.play_pcap(PCAP_FILE);
  end

endmodule

`default_nettype wire
