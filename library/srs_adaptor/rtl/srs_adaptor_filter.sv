// file: srs_adaptor_filter.sv
// brief: This block will looking at the ORAN parse port from XORIF IP core. All
//        needed information should appear on this port (not on message body).
`timescale 1 ns / 1 ps `default_nettype none

module srs_adaptor_filter (
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
    output var [ 3:0] srs_cc,
    output var [11:0] srs_symbol,
    output var [ 3:0] srs_numsymbol,
    output var [ 7:0] srs_numprbc,
    output var [ 9:0] srs_startprbc,
    output var [11:0] srs_sectionid,
    output var        srs_valid,
    // Control
    //========
    input var  [ 1:0] ctrl_numerology
);


  // FSM
  //====
  // This FSM is used to extract SRS configuration C-Plane message from XORIF.
  // The necessary information of SRS message are:
  //  messageType = 2 (C-Plane message)
  //  Packet in window
  //  Packet with good length
  //  dataDirction = 0 (UL)
  //  sectionType = 1 (Generic for DL/UL, but we use it for SRS)
  //  sectionID = 0

  typedef enum int {
    S_TRANS,
    S_APP,
    S_SEC,
    S_VALID
  } state_t;

  state_t state, state_next;

  logic t_header_is_ok, radio_app_head_is_ok, section_header_is_ok;

  logic [3:0] s_subframeid_r;
  logic [5:0] s_slotid_r;
  logic [5:0] s_symbolid_r;

  // SRS Message Filter Condition

  // TODO: SRS message is filtered by s_rtc_pc_id, need to check
  assign t_header_is_ok = s_messagetype == 2 && s_packet_in_window && ~s_runt_packet_len && s_rtc_pc_id == 64;

  assign radio_app_head_is_ok = s_datadirection == 0 && s_sectiontype == 1;

  assign section_header_is_ok = 1;


  // FSM

  always_ff @(posedge clk) begin
    if (rst) begin
      state <= S_TRANS;
    end else begin
      state <= state_next;
    end
  end

  always_comb begin : p_state_next
    case (state)
      S_TRANS: state_next = ~s_t_header_offset_valid ? S_TRANS : ~t_header_is_ok ? S_TRANS : S_APP;
      S_APP: state_next = ~s_radio_app_head_valid ? S_APP : ~radio_app_head_is_ok ? S_TRANS : S_SEC;
      S_SEC:
      state_next = ~s_section_header_valid ? S_SEC : ~section_header_is_ok ? S_TRANS : S_VALID;
      S_VALID: state_next = S_TRANS;
      default: state_next = S_TRANS;
    endcase
  end


  // Output

  always_ff @(posedge clk) begin
    if (s_radio_app_head_valid) begin
      s_subframeid_r <= s_subframeid;
      s_slotid_r     <= s_slotid;
      s_symbolid_r   <= s_symbolid;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      srs_valid <= 1'b0;
    end else begin
      srs_valid <= (state_next == S_VALID);
    end
  end

  always_ff @(posedge clk) begin
    if (state_next == S_VALID) begin
      srs_rtc_pc_id <= s_rtc_pc_id;
      srs_cc        <= s_rtc_pc_id[11:8];
      srs_symbol    <= (s_subframeid_r * 2 + s_slotid_r) * 7 * (2 ** ctrl_numerology) + s_symbolid_r;
      srs_numsymbol <= s_numsymbol;
      srs_numprbc   <= s_numprbc;
      srs_startprbc <= s_startprbc;
      srs_sectionid <= s_sectionid;
    end
  end

endmodule

`default_nettype wire
