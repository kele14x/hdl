// file: srs_adaptor_filter.sv
// brief: This block will looking at the ORAN parse port from XORIF IP core. All
//        needed information should appear on this port (not on message body).
`timescale 1 ns / 1 ps `default_nettype none

module srs_adaptor_filter #(
    parameter int NUM_CC = 2
) (
    // Interface with XORIF
    //=====================
    input var         clk,
    input var         rst,
    // ORAN Parse Port
    input var         s_t_header_offset_valid,
    input var         s_runt_packet_len,
    input var  [15:0] s_rtc_pc_id,
    input var         s_concat,
    input var  [ 2:0] s_messagetype,
    input var  [ 7:0] s_seqid,
    input var  [ 6:0] s_subseqid,
    input var         s_ebit,
    input var  [15:0] s_payloadsize,
    input var         s_packet_in_window,
    input var  [11:0] s_offset_in_symbol,
    //
    input var         s_radio_app_head_valid,
    input var         s_datadirection,
    input var  [ 7:0] s_numsections,
    input var  [ 2:0] s_sectiontype,
    input var  [ 3:0] s_filterindex,
    input var  [ 7:0] s_frameid,
    input var  [ 3:0] s_subframeid,
    input var  [ 5:0] s_slotid,
    input var  [ 5:0] s_symbolid,
    input var  [ 7:0] s_udcomphdr,
    input var  [15:0] s_timeoffset,
    input var  [ 7:0] s_framestructure,
    input var  [15:0] s_cplength,
    //
    input var         s_section_header_valid,
    input var  [ 3:0] s_numsymbol,
    input var  [ 7:0] s_numprbc,
    input var  [ 9:0] s_startprbc,
    input var  [11:0] s_sectionid,
    input var         s_rb,
    input var  [11:0] s_remask,
    input var  [14:0] s_beamid15,
    input var  [23:0] s_freqoffset,
    // SRS Information
    //================
    output var [15:0] srs_rtc_pc_id,
    //
    output var [ 7:0] srs_frameid,
    output var [ 3:0] srs_subframeid,
    output var [ 5:0] srs_slotid,
    output var [ 5:0] srs_symbolid,
    //
    output var [ 3:0] srs_numsymbol,
    output var [ 7:0] srs_numprbc,
    output var [ 9:0] srs_startprbc,
    output var [11:0] srs_sectionid,
    //
    output var        srs_valid,
    // Ctrl Interface
    //===============
    input var  [ 1:0] ctrl_numerology        [NUM_CC]
);


  // The necessary information of SRS message are:
  //  rtcID[7:6] = 1 (RU Port ID for SRS)
  //  messageType = 2 (C-Plane message)
  //  Packet in window
  //  Packet with good length
  //  dataDirction = 0 (UL)
  //  sectionType = 1 (Generic for DL/UL, but we use it for SRS)

  logic        runt_packet_len_r;
  logic [15:0] rtc_pc_id_r;
  logic [ 2:0] messagetype_r;
  //
  logic        datadirection_r;
  logic [ 2:0] sectiontype_r;
  logic [ 7:0] frameid_r;
  logic [ 3:0] subframeid_r;
  logic [ 5:0] slotid_r;
  logic [ 5:0] symbolid_r;
  //
  logic [ 3:0] numsymbol_r;
  logic [ 7:0] numprbc_r;
  logic [ 9:0] startprbc_r;
  logic [11:0] sectionid_r;
  //
  logic        section_header_valid_r;

  logic t_header_is_ok, radio_app_head_is_ok, section_header_is_ok;

  logic [ 2:0] cc;
  logic [ 1:0] mu;
  logic [11:0] symbol;


  always_ff @(posedge clk) begin
    if (s_t_header_offset_valid) begin
      runt_packet_len_r <= s_runt_packet_len;
      rtc_pc_id_r       <= s_rtc_pc_id;
      messagetype_r     <= s_messagetype;
    end
  end

  always_ff @(posedge clk) begin
    if (s_radio_app_head_valid) begin
      datadirection_r <= s_datadirection;
      sectiontype_r   <= s_sectiontype;
      frameid_r       <= s_frameid;
      subframeid_r    <= s_subframeid;
      slotid_r        <= s_slotid;
      symbolid_r      <= s_symbolid;
    end
  end

  always_ff @(posedge clk) begin
    if (s_section_header_valid) begin
      numsymbol_r <= s_numsymbol;
      numprbc_r   <= s_numprbc;
      startprbc_r <= s_startprbc;
      sectionid_r <= s_sectionid;
    end
    section_header_valid_r <= s_section_header_valid;
  end


  // NR Symbol number calculation
  assign cc = rtc_pc_id_r[10:8];
  // 0 : 30 kHz SCS, 1: 15 khz SCS, others: 60 kHz SCS
  assign mu = ctrl_numerology[cc] == 0 ? 1 : ctrl_numerology[cc] == 1 ? 0 : 2;
  assign symbol = ((s_subframeid * (2 ** mu) + s_slotid) * 14 + s_symbolid);

  // SRS Message Filter Condition

  // {2-bit DU_Port_ID, 3-bit RandSector_ID, 3-bit CC_ID, 8-bit RU_Port_ID}
  // SRS: RU_Port_ID from 0x40 to 0x7F
  assign t_header_is_ok = messagetype_r == 2 && ~runt_packet_len_r && rtc_pc_id_r[7:6] == 2'b01;

  assign radio_app_head_is_ok = datadirection_r == 0 && sectiontype_r == 1;

  assign section_header_is_ok = 1;


  // Output
  //=======

  always_ff @(posedge clk) begin
    if (section_header_valid_r) begin
      srs_rtc_pc_id  <= rtc_pc_id_r;
      //
      srs_frameid    <= frameid_r;
      srs_subframeid <= subframeid_r;
      srs_slotid     <= slotid_r;
      srs_symbolid   <= symbolid_r;
      //
      srs_numsymbol  <= numsymbol_r;
      srs_numprbc    <= numprbc_r;
      srs_startprbc  <= startprbc_r;
      srs_sectionid  <= sectionid_r;
    end
  end

  always_ff @(posedge clk) begin
    srs_valid <= section_header_valid_r && t_header_is_ok && radio_app_head_is_ok && section_header_is_ok;
  end

endmodule

`default_nettype wire
