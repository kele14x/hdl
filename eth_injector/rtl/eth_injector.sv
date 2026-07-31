// File: eth_injector
// Brief: Inject Ethernet packet to target DUT
`timescale 1 ns / 1 ps
`default_nettype none

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

  // synthesis translate_off

  pcap_handler_t                     pcap;
  pkt_buffer_t                       pkt;

  logic          [  TDATA_WIDTH-1:0] buf_tdata [2000];
  logic          [TDATA_WIDTH/8-1:0] buf_tkeep [2000];
  int                                buf_bytes;
  int                                buf_len;
  longint                            wait_time;
  longint                            ts_shift;

  // Open and play a .pcap file.
  task automatic play_pcap(string fn);
    pcap = pcap_open(fn);

    // Read first packet from pcap file, cacluate the time differrence between 
    // packet's time stamp (usually unix epoch) and current simulation time.
    // To reflect the real time sended on net, we will use the time stamp to 
    // determine the wait time between sending each packet.
    pkt = pcap_read_packet(pcap);
    ts_shift = pkt.ts - $time();
`ifdef DEBUG
    $display("Cacluated time shift is %d ns.", ts_shift);
`endif

    // Loop send each packet, assume packet is placed in order with timestamp.
    while (pkt.len != 0) begin
      wait_time = pkt.ts - $time() - ts_shift;
      wait_time = (wait_time > 0) ? wait_time : 0;
`ifdef DEBUG
      $display("Packet TS: %d ns, sim time: %d (%d) ns, wait: %d ns.", pkt.ts, $time(),
               $signed(ts_shift + $time()), wait_time);
`endif
      #(wait_time);

      copy_pkg();
      send_buffer();

      pkt = pcap_read_packet(pcap);
    end

  endtask

  task automatic send_buffer();
    for (int i = 0; i < buf_len; i++) begin
      @(posedge aclk);
      m_eth_tdata  <= buf_tdata[i];
      m_eth_tkeep  <= buf_tkeep[i];
      m_eth_tvalid <= 1'b1;
      m_eth_tlast  <= (i == buf_len - 1);
      while (!m_eth_tready) begin
        @(posedge aclk);
      end
    end
    @(posedge aclk);
    m_eth_tdata  <= '0;
    m_eth_tkeep  <= '0;
    m_eth_tvalid <= 1'b0;
    m_eth_tlast  <= 1'b0;
  endtask

  function automatic void copy_pkg();
    buf_bytes = pkt.len == 64 ? 60 : pkt.len; // !! Bug workaround for packet less than 64-byte (C-Plane message)
    buf_len = buf_bytes % 8 == 0 ? buf_bytes / 8 : buf_bytes / 8 + 1;
    for (int i = 0; i < buf_len; i++) begin
      for (int j = 0; j < 8; j++) begin
        if (i * 8 + j < buf_bytes) begin
          buf_tdata[i][j*8+7-:8] = pkt.buffer[i*8+j];
          buf_tkeep[i][j] = 1'b1;
        end else begin
          buf_tdata[i][j*8+7-:8] = '0;
          buf_tkeep[i][j] = 1'b0;
        end
      end
    end
  endfunction

  always @(negedge aresetn) begin
    m_eth_tdata  <= '0;
    m_eth_tkeep  <= '0;
    m_eth_tvalid <= 1'b0;
    m_eth_tlast  <= 1'b0;
  end

  initial begin
    m_eth_tdata  = '0;
    m_eth_tkeep  = '0;
    m_eth_tvalid = 1'b0;
    m_eth_tlast  = 1'b0;
  end

  // synthesis translate_on

endmodule

`default_nettype wire
