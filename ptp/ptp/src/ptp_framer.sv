// File: ptp_master.sv
// Brief: PTP Master implemented by FPGA.
`timescale 1 ns / 1 ps
//
`default_nettype none

module ptp_framer (
    input var         clk,
    input var         rst,
    //
    output var [63:0] m_axis_tdata,
    output var        m_axis_tvalid,
    output var        m_axis_tlast,
    input var         m_axis_tready,
    output var [55:0] m_axis_tuser,      // TX Ctrl
    //
    input var         s_send_sync,
    input var         s_send_announce,
    input var         s_send_delay_req,
    input var         s_send_delay_resp
);

  ptp_framer_eth i_eth (
      // Tx Ethernet ports
      //------------------
      .eth_tx_clk       (eth_tx_clk),
      .eth_tx_rst       (eth_tx_rst),
      // Tx data
      .m_eth_fram_tdata (m_eth_fram_tdata),
      .m_eth_fram_tkeep (m_eth_fram_tkeep),
      .m_eth_fram_tvalid(m_eth_fram_tvalid),
      .m_eth_fram_tlast (m_eth_fram_tlast),
      .m_eth_fram_tready(m_eth_fram_tready),
      // Internal clock domain
      //----------------------
      .clk              (clk),
      .rst              (rst),
      //
      .s_axis_tdata     (s_axis_tdata),
      .s_axis_tkeep     (s_axis_tkeep),
      .s_axis_tvalid    (s_axis_tvalid),
      .s_axis_tlast     (s_axis_tlast),
      .s_axis_tready    (s_axis_tready)
  );

endmodule

`default_nettype wire
