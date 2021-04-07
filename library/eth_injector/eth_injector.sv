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
  logic [TDATA_WIDTH/8-1:0] buf_tkeep [1000];
  int buf_len;
  longint wait_time;
  longint ts_shift;

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
    while(pkt.len != 0) begin
      wait_time = pkt.ts - $time() - ts_shift;
      wait_time = (wait_time > 0) ? wait_time : 0;
`ifdef DEBUG
      $display("Packet TS: %d ns, sim time: %d (%d) ns, wait: %d ns.", pkt.ts, $time(), $signed(ts_shift + $time()), wait_time);
`endif
      #(wait_time);
  
      copy_pkg();
      i_vip.IF.master_send(buf_len, buf_tdata, buf_tkeep);

      pkt = pcap_read_packet(pcap);
    end

  endtask

  function automatic void copy_pkg();
    buf_len = pkt.len % 8 == 0 ? pkt.len / 8 : pkt.len / 8 + 1;
    for (int i = 0; i < buf_len; i++) begin
        for (int j = 0; j < 8; j++) begin
            if (i*8+j < pkt.len) begin
                buf_tdata[i][j*8+7-:8] = pkt.buffer[i*8+j];
                buf_tkeep[i][j] = 1'b1;
            end else begin
                buf_tdata[i][j*8+7-:8] = '0;
                buf_tkeep[i][j] = 1'b0;
            end
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
