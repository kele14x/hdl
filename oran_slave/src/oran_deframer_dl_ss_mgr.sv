// File: oran_deframer_dl_ss_mgr.sv
// Brief: This module unpack the DL IQ packets (assume MAC & eCPRI header is
//        removed). Application header is parsed to parse ports, section data
//        is sent to next module.
`timescale 1 ns / 1 ps
//
`default_nettype none

module oran_deframer_dl_ss_mgr #(
    parameter int BUFFER_SYMBOL = 10
) (
    input var                              clk,
    input var                              rst,
    //
    input var                              timer_sof,
    input var                              timer_sos,
    //
    input var  [                     63:0] s_axis_tdata,
    input var  [                      7:0] s_axis_tkeep,
    input var                              s_axis_tvalid,
    input var                              s_axis_tlast,
    input var  [                      8:0] s_axis_tuser,
    // Section data
    output var [                     63:0] m_axis_data_tdata,
    output var                             m_axis_data_tvalid,
    output var                             m_axis_data_tlast,
    output var [$clog2(BUFFER_SYMBOL)-1:0] m_axis_data_tuser,
    // Section header
    output var [                     39:0] m_axis_header_tdata,
    output var                             m_axis_header_tvalid,
    output var [$clog2(BUFFER_SYMBOL)-1:0] m_axis_header_tuser,
    //
    output var [$clog2(BUFFER_SYMBOL)-1:0] buffer_rd_bank,
    // Control & Status
    //-----------------
    input var                              ctrl_has_udcomphdr,
    input var  [                      3:0] ctrl_ud_comp_meth,
    input var  [                      3:0] ctrl_ud_iq_width,
    // O-RAN Parse ports
    //------------------
    output var                             m_app_header_valid,
    output var                             m_app_datadirection,
    output var [                      3:0] m_app_filterindex,
    output var [                      7:0] m_app_frameid,
    output var [                      3:0] m_app_subframeid,
    output var [                      5:0] m_app_slotid,
    output var [                      5:0] m_app_symbolid,
    //
    output var                             m_app_packet_in_window,
    output var [                      8:0] m_app_offset_in_symbol,
    // TODO: reversed for C-Plane parser
    output var [                      7:0] m_app_numsections,
    output var [                      2:0] m_app_sectiontype,
    output var [                      7:0] m_app_udcomphdr,
    output var [                     15:0] m_app_timeoffset,
    output var [                      7:0] m_app_framestructure,
    output var [                     15:0] m_app_cplength,
    //
    output var                             m_section_header_valid,
    output var [                     11:0] m_section_sectionid,
    output var                             m_section_rb,
    output var                             m_section_syminc,
    output var [                      9:0] m_section_startprb,
    output var [                      7:0] m_section_numprb,
    output var [                      7:0] m_section_udcomphdr,
    // TODO: reversed for C-Plane parser
    output var [                     11:0] m_section_remask,
    output var [                      3:0] m_section_numsymbol,
    output var                             m_section_ef,
    output var [                     14:0] m_section_beamid,
    output var [                     23:0] m_section_freqoffset
);

  // Each symbol is stored in dedicate bank
  localparam int BankWidth = $clog2(BUFFER_SYMBOL);
  // Each symbol hs 2k x 64-bit buffer (cost ~=4 BRAM per symbol)
  // TODO: the buffer size could be optimized by sharing between CC & Symbol
  localparam int AddrWidth = BankWidth + 11;

  // Symbol counter

  logic [8:0] current_symbol;  // 0 ~ 279

  // Misc

  logic [63:0] s_axis_tdata_reversed;
  logic [63:0] s_axis_tdata_d1;  // also byte reversed
  logic [63:0] s_axis_tdata_d2;  // also byte reversed

  logic        s_axis_tvalid_d;

  logic [127:0] s_axis_tdata_h;
  logic [127:0] s_axis_tdata_c;

  logic [$clog2(BUFFER_SYMBOL)-1:0] buffer_rd_bank_d;

  // FSM

  // Incoming O-RAN packet, assume MAC, and transport header removed
  typedef enum int {
    S_RST,     // Under reset
    S_APP,     // Wait for application common & section header
    S_PAYLOAD, // IQ payload, not last word
    S_DISCARD  // Discard packet, mostly because packet not in window
  } state_t;

  state_t state, state_next;

  // Application common header (32-bit)

  logic        app_datadirection;
  logic [ 2:0] app_payloadversion;
  logic [ 3:0] app_filterindex;
  logic [ 7:0] app_frameid;
  logic [ 3:0] app_subframeid;
  logic [ 5:0] app_slotid;
  logic [ 5:0] app_symbolid;

  logic [ 8:0] app_symbol_num;
  logic        app_packet_in_window;
  logic        app_packet_in_window_d;
  logic [ 8:0] app_offset_in_symbol;
  logic [ 8:0] app_offset_in_symbol_d;

  logic [31:0] app_header;

  // Application section header (32-bit)

  logic [11:0] section_sectionid;
  logic        section_rb;
  logic        section_syminc;
  logic [ 9:0] section_startprb;
  logic [ 7:0] section_numprb;
  logic [ 7:0] section_udcomphdr;
  logic [ 7:0] section_reserved;

  logic [47:0] section_header;

  // Unpacking state

  logic [ 2:0] section_hdr_size;

  logic [ 5:0] iq_bytes; // Bytes per PRB

  logic [15:0] packet_c_size;  // current section size (including header) in bytes
  logic [15:0] packet_cnt;  // already received number of data in bytes
  logic [15:0] packet_h_size;  // in bytes

  logic [ 2:0] section_header_shift;
  logic        section_header_valid;

  logic [ 2:0] section_data_shift;
  logic        section_data_valid;
  logic        section_data_last;

  logic [63:0] section_extra_data;
  logic        section_extra_last_c;
  logic        section_extra_last;
  logic        section_extra_last_d;


  //
  // This function reverse byte order of 64-bit data
  //
  function automatic logic [63:0] byte_reverse(input logic [63:0] data);
    for (int i = 0; i < 8; i++) begin
      byte_reverse[64-1-i*8-:8] = data[i*8+8-1-:8];
    end
  endfunction

  //
  // This function calculates the offset in symbol between current symbol and
  // received symbol number. The returned value is how many symbol is advanced
  // from current symbol to received symbol number, and it is always a
  // positive number. The return value is between 1 and 280.
  //
  function automatic logic [8:0] offset_in_symbol(input logic [8:0] current_symbol,
                                                  input logic [8:0] symbol_number);
    if (symbol_number > current_symbol) begin
      offset_in_symbol = symbol_number - current_symbol;
    end else begin
      offset_in_symbol = 280 - current_symbol + symbol_number;
    end
  endfunction


  // Main
  //-----

  // Symbol counter

  always_ff @(posedge clk) begin
    if (rst | timer_sof) begin
      current_symbol <= '0;
    end else if (timer_sos) begin
      current_symbol <= current_symbol + 1;
    end
  end

  // Combine two word of TDATA, in case some field may span over two words

  assign s_axis_tdata_reversed = byte_reverse(s_axis_tdata);

  always_ff @(posedge clk) begin
    if (s_axis_tvalid) begin
      s_axis_tdata_d1 <= s_axis_tdata_reversed;
      s_axis_tdata_d2 <= s_axis_tdata_d1;
    end
  end

  always_ff @(posedge clk) begin
    s_axis_tvalid_d <= s_axis_tvalid;
  end

  assign s_axis_tdata_h = {s_axis_tdata_d1, s_axis_tdata_reversed};

  assign s_axis_tdata_c = {s_axis_tdata_d2, s_axis_tdata_d1};


  // FSM

  always_ff @(posedge clk) begin
    if (rst) begin
      state <= S_RST;
    end else begin
      state <= state_next;
    end
  end

  always_comb begin
    // By default, stay at current state
    state_next = state;

    case (state)
      S_RST: begin
        state_next = S_APP;
      end

      S_APP: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_APP;
        end else if (s_axis_tvalid) begin
          // Check if packet in received in window
          if (app_packet_in_window) begin
            state_next = S_PAYLOAD;
          end else begin
            state_next = S_DISCARD;
          end
        end
      end

      S_PAYLOAD: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_APP;
        end
      end

      S_DISCARD: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_APP;
        end
      end

      default: begin
        state_next = S_RST;
      end
    endcase
  end


  // O-RAN application header parser

  // Application common header
  // It's presents at MSB 32-bit of first word in packet

  assign {
    app_datadirection,
    app_payloadversion,
    app_filterindex,
    app_frameid,
    app_subframeid,
    app_slotid,
    app_symbolid
  } = app_header;

  assign app_symbol_num = s_axis_tuser;

  assign app_offset_in_symbol = offset_in_symbol(current_symbol, app_symbol_num);

  // The packet is considered "in window" if it arrives at least 1 symbol early
  // and not too early so it could fit into buffer.
  assign app_packet_in_window = (1 <= app_offset_in_symbol) && (app_offset_in_symbol < BUFFER_SYMBOL);

  assign app_header = s_axis_tdata_reversed[63:32];

  always_ff @(posedge clk) begin
    m_app_header_valid <= (state == S_APP) && s_axis_tvalid;
  end

  always_ff @(posedge clk) begin
    if ((state == S_APP) && s_axis_tvalid) begin
      m_app_datadirection    <= app_datadirection;
      m_app_filterindex      <= app_filterindex;
      m_app_frameid          <= app_frameid;
      m_app_subframeid       <= app_subframeid;
      m_app_slotid           <= app_slotid;
      m_app_symbolid         <= app_symbolid;
      //
      m_app_offset_in_symbol <= app_offset_in_symbol;
      m_app_packet_in_window <= app_packet_in_window;
    end
  end


  // Application section header

  // First application section header present at LSB 32-bit of first word in packet
  // But left sections may appear at any byte position, based on the number of
  // bytes for IQ data. The position could be calculated from section size and
  // number of bytes we received.
  assign section_header_shift = 0 - packet_c_size - section_hdr_size;

  always_ff @(posedge clk) begin
    section_hdr_size <= ctrl_has_udcomphdr ? 6 : 4;
  end

  // If we received 4 or more bytes than current section, it means we received
  // another section header
  // section_header_valid = packet_cnt + 8 >= packet_c_size + section_hdr_size;
  assign section_header_valid = (packet_cnt + 8 >= packet_c_size + section_hdr_size) && ~s_axis_tlast;

  assign {
    section_sectionid,
    section_rb,
    section_syminc,
    section_startprb,
    section_numprb,
    section_udcomphdr,
    section_reserved
  } = section_header;

  always_comb begin
    section_header = s_axis_tdata_h[section_header_shift*8+47-:48];
  end

  always_ff @(posedge clk) begin
    m_section_header_valid <= section_header_valid && s_axis_tvalid;
  end

  always_ff @(posedge clk) begin
    if (section_header_valid && s_axis_tvalid) begin
      m_section_sectionid <= section_sectionid;
      m_section_rb        <= section_rb;
      m_section_syminc    <= section_syminc;
      m_section_startprb  <= section_startprb;
      m_section_numprb    <= section_numprb;
      m_section_udcomphdr <= section_udcomphdr;
    end
  end


  // Section data

  function static [5:0] iq_bytes_lut(input logic [3:0] iq_width);
    logic [5:0] the_lut [16];
    the_lut[0] = 48;
    for (int i = 1; i < 15; i++) begin
      the_lut[i] = (3 * i + 1);
    end
    iq_bytes_lut = the_lut[iq_width];
  endfunction

  always_ff @(posedge clk) begin
    if (ctrl_ud_comp_meth == 4'd1) begin
      iq_bytes <= iq_bytes_lut(ctrl_ud_iq_width);
    end else begin
      iq_bytes <= iq_bytes_lut(0);
    end
  end

  // `packet_cnt` counts how many bytes received on AXIS i/f. TKEEP size is not
  // needed as we can know the ending of the packet.
  always_ff @(posedge clk) begin
    if (rst) begin
      packet_cnt <= '0;
    end else if (s_axis_tvalid && s_axis_tlast) begin
      packet_cnt <= '0;
    end else if (s_axis_tvalid) begin
      packet_cnt <= packet_cnt + 8;
    end
  end

  // Count the accumulative section size, including application common & section header
  // TODO: For other compression method, the section size is different
  always_ff @(posedge clk) begin
    if (rst) begin
      packet_c_size <= 'd4;
    end else if (s_axis_tlast && s_axis_tvalid) begin
      // At first section, we count the application common header as 4
      packet_c_size <= 'd4;
    end else if (section_header_valid && s_axis_tvalid) begin
      // From second section, the section size is (section_numprb * iq_bytes + 4)
      packet_c_size <= packet_c_size + section_hdr_size + section_numprb * iq_bytes;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      packet_h_size <= 'd4;
    end else if (s_axis_tlast && s_axis_tvalid) begin
      packet_h_size <= 'd4;
    end else if (section_header_valid && s_axis_tvalid) begin
      packet_h_size <= packet_c_size + section_hdr_size;
    end
  end

  always_ff @(posedge clk) begin
    section_data_shift <= 0 - packet_h_size;
  end

  always_ff @(posedge clk) begin
    section_data_valid <= (packet_cnt + 8 >= packet_h_size + 8) &&
                          (packet_cnt + 8 <= packet_c_size + 7);
  end

  // last tick of data

  always_ff @(posedge clk) begin
    if ((state == S_PAYLOAD) && (packet_cnt + 8 >= packet_c_size) && s_axis_tvalid && section_data_valid && ~section_extra_last_c) begin
      section_data_last <= 1'b1;
    end else begin
      section_data_last <= 1'b0;
    end
  end

  always_comb begin
    if (packet_c_size[2:0] == packet_h_size[2:0]) begin
      section_extra_last_c = 1'b0;
    end else if (packet_c_size[2:0] == 3'b000) begin
      section_extra_last_c = 1'b1;
    end else if (packet_h_size[2:0] == 3'b000) begin
      section_extra_last_c = 1'b0;
    end else if (packet_c_size[2:0] <= packet_h_size[2:0]) begin
      section_extra_last_c = 1'b0;
    end else begin
      section_extra_last_c = 1'b1;
    end
  end

  always_ff @(posedge clk) begin
    if ((state == S_PAYLOAD) && (packet_cnt + 8 >= packet_c_size) && s_axis_tvalid && section_data_valid && section_extra_last_c) begin
      section_extra_last <= 1'b1;
    end else begin
      section_extra_last <= 1'b0;
    end
  end

  always_ff @(posedge clk) begin
    section_extra_last_d <= section_extra_last;
  end

  always_ff @(posedge clk) begin
    if (section_extra_last) begin
      section_extra_data <= s_axis_tdata_h[section_data_shift*8+63-:64];
    end
  end


  // Output
  //-------

  // At each symbol, move to next bank for reading
  always_ff @(posedge clk) begin
    if (rst) begin
      buffer_rd_bank <= '0;
    end else if (timer_sos) begin
      if (buffer_rd_bank == BUFFER_SYMBOL - 1) begin
        buffer_rd_bank <= 0;
      end else begin
        buffer_rd_bank <= buffer_rd_bank + 1;
      end
    end
  end


  // Section data AXIS

  always_ff @(posedge clk) begin
    if (section_extra_last_d) begin
      m_axis_data_tdata <= byte_reverse(section_extra_data);
    end else if ((section_data_valid && s_axis_tvalid_d) || section_data_last) begin
      m_axis_data_tdata <= byte_reverse(s_axis_tdata_c[section_data_shift*8+63-:64]);
    end
  end

  always_ff @(posedge clk) begin
    m_axis_data_tvalid <= ((section_data_valid && s_axis_tvalid_d) || section_data_last || section_extra_last_d) && app_packet_in_window_d;
  end

  always_ff @(posedge clk) begin
    m_axis_data_tlast <= section_data_last || section_extra_last_d;
  end

  // TUSER marks the write bank to buffer
  always_ff @(posedge clk) begin
    if ((state == S_APP) && s_axis_tvalid) begin
      buffer_rd_bank_d       <= buffer_rd_bank;
      app_packet_in_window_d <= app_packet_in_window;
      app_offset_in_symbol_d <= app_offset_in_symbol;
    end
    m_axis_data_tuser <= (buffer_rd_bank_d + app_offset_in_symbol_d) % BUFFER_SYMBOL;
  end


  // Section header AXIS

  always_ff @(posedge clk) begin
    m_axis_header_tdata <= {
      m_section_udcomphdr, m_section_sectionid, m_section_rb, m_section_syminc, m_section_startprb, m_section_numprb
    };
  end

  always_ff @(posedge clk) begin
    m_axis_header_tvalid <= m_section_header_valid && app_packet_in_window_d;
  end

  assign m_axis_header_tuser = m_axis_data_tuser;

endmodule

`default_nettype wire
