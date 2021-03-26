// File: eth_injector
// Brief: Inject Ethernet packet to target DUT
`timescale 1 ns / 1 ps `default_nettype none

module eth_injector #(
    parameter int TDATA_WIDTH = 64
) (
    // Clocks
    input var                      aclk,
    input var                      aresetn,
    // Data interface
    output var [  TDATA_WIDTH-1:0] m_eth_tdata,
    output var [TDATA_WIDTH/8-1:0] m_eth_tkeep,
    output var                     m_eth_tvalid,
    output var                     m_eth_tlast,
    input var                      m_eth_tready
);

  import pcap_pkg::*;

  axi4s_vip #(
      .INIT_MODE  (1),
      .HAS_TKEEP  (1),
      .HAS_TLAST  (1),
      .TDATA_WIDTH(TDATA_WIDTH)
  ) i_vip (
      .aclk        (aclk),
      .aresetn     (aresetn),
      //
      .m_axis_tdata (m_eth_tdata),
      .m_axis_tkeep (m_eth_tkeep),
      .m_axis_tvalid(m_eth_tvalid),
      .m_axis_tlast (m_eth_tlast),
      .m_axis_tready(m_eth_tready)
  );

  // synthesis translate_off

  pcap_handler_t pcap;
  pkt_buffer_t   pkt;

  logic [TDATA_WIDTH-1:0] buf_tdata [1000];
  int buf_len;

  // Open and play a .pcap file.
  task automatic play_pcap(string fn);
    pcap = pcap_open(fn);

    pkt = pcap_read_packet(pcap);
    while(pkt.len != 0) begin
      copy_pkg();
      i_vip.IF.master_send(buf_len, buf_tdata);
      pkt = pcap_read_packet(pcap);
    end

  endtask

  function automatic void copy_pkg();
    buf_len = pkt.len % 8 == 0 ? pkt.len / 8 : pkt.len / 8 + 1;
    for (int i = 0; i < buf_len; i++) begin
        for (int j = 0; i*8+j < pkt.len; j++) begin
            buf_tdata[i][j*8+7-:8] = pkt.buffer[i*8+j];
        end
    end
  endfunction

  initial begin
    i_vip.set_master_mode();
    i_vip.IF.reset();
  end

  // synthesis translate_on

endmodule

`default_nettype wire
