`timescale 1 ns / 1 ps `default_nettype none

module srs_adaptor_sim #(
  parameter int NUM_ETH_PORT = 2,
  parameter int NUM_SRS_LAYER = 64,
  parameter int NUM_CC = 2
) (
  // Interface with DFE
  //===================
  input var          clk_491m52,
  input var          rst_491m52,
  // SRS Section Header
  output var [ 3:0]  srs_buf_numsymbol,
  output var [11:0]  srs_buf_symbol,
  output var         srs_buf_valid,
  // SRS data request
  output var [ 5:0]  srs_req_layer,
  output var [11:0]  srs_req_symbol,
  output var         srs_req_cc,
  output var         srs_req_valid,
  // SRS data
  input var  [21:0]  srs_data, // {4'b exponent, 9'b mantissa Q, 9'b mantissa I}
  input var          srs_sop,
  input var          srs_eop,
  // Interface with XORIF
  //=====================
  input var          clk_400m,
  input var          rst_400m,
  // ORAN Parse Port
  input var          m_t_header_offset_valid    [NUM_ETH_PORT],
  input var          m_runt_packet_len          [NUM_ETH_PORT],
  input var  [ 15:0] m_rtc_pc_id                [NUM_ETH_PORT],
  input var          m_concat                   [NUM_ETH_PORT],
  input var  [  2:0] m_messagetype              [NUM_ETH_PORT],
  input var  [  7:0] m_seqid                    [NUM_ETH_PORT],
  input var  [  6:0] m_subseqid                 [NUM_ETH_PORT],
  input var          m_ebit                     [NUM_ETH_PORT],
  input var  [ 15:0] m_payloadsize              [NUM_ETH_PORT],
  input var          m_packet_in_window         [NUM_ETH_PORT],
  input var  [ 11:0] m_offset_in_symbol         [NUM_ETH_PORT],
  //
  input var          m_radio_app_head_valid     [NUM_ETH_PORT],
  input var          m_datadirection            [NUM_ETH_PORT],
  input var  [  7:0] m_numsections              [NUM_ETH_PORT],
  input var  [  2:0] m_sectiontype              [NUM_ETH_PORT],
  input var  [  3:0] m_filterindex              [NUM_ETH_PORT],
  input var  [  7:0] m_frameid                  [NUM_ETH_PORT],
  input var  [  3:0] m_subframeid               [NUM_ETH_PORT],
  input var  [  5:0] m_slotid                   [NUM_ETH_PORT],
  input var  [  5:0] m_symbolid                 [NUM_ETH_PORT],
  input var  [  7:0] m_udcomphdr                [NUM_ETH_PORT],
  input var  [ 15:0] m_timeoffset               [NUM_ETH_PORT],
  input var  [  7:0] m_framestructure           [NUM_ETH_PORT],
  input var  [ 15:0] m_cplength                 [NUM_ETH_PORT],
  //
  input var          m_section_header_valid     [NUM_ETH_PORT],
  input var  [  3:0] m_numsymbol                [NUM_ETH_PORT],
  input var  [  7:0] m_numprbc                  [NUM_ETH_PORT],
  input var  [  9:0] m_startprbc                [NUM_ETH_PORT],
  input var  [ 11:0] m_sectionid                [NUM_ETH_PORT],
  input var          m_rb                       [NUM_ETH_PORT],
  input var  [ 11:0] m_remask                   [NUM_ETH_PORT],
  input var  [ 14:0] m_beamid15                 [NUM_ETH_PORT],
  input var  [ 23:0] m_freqoffset               [NUM_ETH_PORT],
  // UNSOL port
  output var [ 63:0] s00_fram_unsol_tdata,
  output var [  7:0] s00_fram_unsol_tkeep,
  output var         s00_fram_unsol_tvalid,
  output var         s00_fram_unsol_tlast,
  input var          s00_fram_unsol_tready,
  output var [ 31:0] s00_fram_unsol_tuser
);

  logic [63:0] buf_tdata[1000];
  logic [ 7:0] buf_tkeep[1000];
  logic [31:0] buf_tuser[1000];

  axi4s_vip #(
      .INIT_MODE  (1),
      .HAS_TKEEP  (1),
      .HAS_TLAST  (1),
      .TDATA_WIDTH(64),
      .TUSER_WIDTH(32)
  ) i_vip (
      .aclk        (clk_400m),
      .aresetn     (~rst_400m),
      //
      .m_axis_tdata (s00_fram_unsol_tdata),
      .m_axis_tkeep (s00_fram_unsol_tkeep),
      .m_axis_tvalid(s00_fram_unsol_tvalid),
      .m_axis_tlast (s00_fram_unsol_tlast),
      .m_axis_tready(s00_fram_unsol_tready),
      .m_axis_tuser (s00_fram_unsol_tuser)
  );

  initial begin
    for (int i = 0; i < 1000; i++) begin
      buf_tdata[i] = i;
      buf_tkeep[i] = '1;
      buf_tuser[i][31:16] = '0; // ExID
      buf_tuser[i][15:13] = '0; // Ethernet Port
      buf_tuser[i][12: 0] = 13'd100; // Incoming packet length
    end
  end

  initial begin
    wait(rst_400m == 0);
    #1000;

    i_vip.IF.master_send(100, buf_tdata, buf_tkeep, buf_tuser);

    #1000;
  end

endmodule

`default_nettype wire
