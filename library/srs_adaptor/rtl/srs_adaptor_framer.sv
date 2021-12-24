// file: srs_adaptor_framer.sv
// brief: At SRS framer request, this module read out one symbol data from BRAM
//        buffer, and format it into AXIS packet.
`timescale 1 ns / 1 ps `default_nettype none

module srs_adaptor_framer (
    input var         clk,
    input var         rst,
    // Frame Request
    //==============
    input var  [15:0] fram_req_rtc_pc_id,
    //
    input var  [ 7:0] fram_req_frameid,
    input var  [ 3:0] fram_req_subframeid,
    input var  [ 5:0] fram_req_slotid,
    input var  [ 5:0] fram_req_symbolid,
    //
    input var  [ 3:0] fram_req_numsymbol,
    input var  [ 7:0] fram_req_numprbc,
    input var  [ 9:0] fram_req_startprbc,
    input var  [11:0] fram_req_sectionid,
    //
    input var  [ 2:0] fram_req_ethport,
    //
    input var         fram_req_valid,
    output var        fram_req_ready,
    // BRAM
    //=====
    // Latency = 3
    output var [ 9:0] bram_addr,            // 0 ~ 1024
    output var        bram_rden,            // !connect to all registers in output pipe
    input var  [95:0] bram_data,            // 4 RE
    // UNSOL port
    //===========
    output var [63:0] m_fram_unsol_tdata,
    output var [ 7:0] m_fram_unsol_tkeep,
    output var        m_fram_unsol_tvalid,
    output var        m_fram_unsol_tlast,
    input var         m_fram_unsol_tready,
    output var [31:0] m_fram_unsol_tuser
);


  // ORAN Header
  //============

  // Application Header (8-byte)
  localparam logic [0:0] OranDataDirection = 1'b0;  // 0: UL; 1: DL;
  localparam logic [2:0] OranPayloadVersion = 3'd1;
  localparam logic [3:0] OranFilterIndex = 4'd0;

  logic [31:0] oran_application_header;

  // Section Header (8-byte)
  localparam logic [0:0] OranRb = 1'b0;
  localparam logic [0:0] OranSymbolInc = 1'b0;

  logic [31:0] oran_section_header;

  logic [63:0] fram_req_header;

  assign oran_application_header = {
    OranDataDirection,
    OranPayloadVersion,
    OranFilterIndex,
    fram_req_frameid,
    fram_req_subframeid,
    fram_req_slotid,
    fram_req_symbolid
  };

  assign oran_section_header = {
    fram_req_sectionid, OranRb, OranSymbolInc, fram_req_startprbc, fram_req_numprbc
  };

  assign fram_req_header = {oran_application_header, oran_section_header};


  // FSM
  //====

  // Sending one packet require we send header (64-bit) then IQ data
  typedef enum int {
    S_RST,
    S_IDLE,
    S_PRE1,
    S_PRE2,
    S_PRE3,
    S_PRE4,
    S_OUT,
    S_POST1,
    S_POST2,
    S_POST3,
    S_POST4,
    S_LAST
  } state_t;

  // S_RST  : under reset
  // S_IDLE : wait for fram request
  // S_PRE1 : request accepted, set BRAM read address and enable
  // S_PRE2 : address + 1, BRAM latency 1
  // S_PRE3 : address + 2, BRAM latency 2
  // S_PRE4 : address + 3, BRAM latency 3, read data appear on port
  // S_OUT  : Set AXIS data
  // S_POST1: Set AXIS data, read address not valid, BRAM latency 1
  // S_POST2: Set AXIS data, BRAM latency 2
  // S_POST3: Set AXIS data, BRAM latency 3, last read data appear on port
  // S_POST4: Set AXIS data, #3/#6 word
  // S_LAST : Set AXIS data, last word (#3.5, #7)

  state_t state, state_next;

  logic iq_done;


  always_ff @(posedge clk) begin
    if (rst) begin
      state <= S_RST;
    end else begin
      state <= state_next;
    end
  end

  always_comb begin
    case (state)
      S_RST:   state_next = S_IDLE;
      S_IDLE:  state_next = fram_req_valid ? S_PRE1 : S_IDLE;
      S_PRE1:  state_next = S_PRE2;
      S_PRE2:  state_next = S_PRE3;
      S_PRE3:  state_next = S_PRE4;
      S_PRE4:  state_next = ~m_fram_unsol_tready ? S_PRE4 : S_OUT;
      S_OUT:   state_next = ~m_fram_unsol_tready ? S_OUT : iq_done ? S_POST1 : S_OUT;
      S_POST1: state_next = ~m_fram_unsol_tready ? S_POST1 : S_POST2;
      S_POST2: state_next = ~m_fram_unsol_tready ? S_POST2 : S_POST3;
      S_POST3: state_next = ~m_fram_unsol_tready ? S_POST3 : S_POST4;
      S_POST4: state_next = ~m_fram_unsol_tready ? S_POST4 : S_LAST;
      S_LAST:  state_next = ~m_fram_unsol_tready ? S_LAST : S_IDLE;
      default: state_next = S_RST;
    endcase
  end


  // FRAM Request Accept Interface
  //==============================

  // Will only accept next frame request when `S_IDLE` again.
  assign fram_req_ready = (state == S_IDLE);


  // AXIS Interface
  //===============

  // Besides the BIG state machine, we also need to keep track of the RE reading
  // state. During 7 state, we need to read 24 REs and write 7 AXIS words. Since
  // for BFP9, 7 AXIS words (7 * 64 = 448-bit) holds 2 RB (2 * 12 = 24 REs).
  // The BRAM has capacity of read out 4 REs at a time。 For first 6 state, we
  // set BRAM read address from K+0 to K+6. For last state, we set BRAM read
  // address no change (K+6). So every 6th BRAM data will be readout twice.
  logic [ 2:0] bram_re_state;

  // We need previous read out data to construct the next AXIS data.
  logic [95:0] bram_data_d;

  logic [63:0] fram_req_header_reg;

  logic [63:0] tdata;

  logic [12:0] packet_length;

  function automatic [63:0] data_gb(input logic [2:0] state, input logic [95:0] data,
                                    input logic [95:0] data_d);
    case (state)
      3'd3:
      return {
        4'b0,  // PAD
        data[21:18],  // E
        data[8:0],  // I0
        data[17:9],  // Q0
        data[32:24],  // I1
        data[41:33],  // Q1
        data[56:48],  // I2
        data[65:57],  // Q2
        data[80:79]  // I3 MSB2
      };
      3'd4:
      return {
        data_d[78:72],  // I3 LSB7
        data_d[89:81],  // Q3
        data[8:0],  // I4
        data[17:9],  // Q4
        data[32:24],  // I5
        data[41:33],  // Q5
        data[56:48],  // I6
        data[65:63]  // Q6 MSB3
      };
      3'd5:
      return {
        data_d[62:57],  // Q6 LSB6
        data_d[80:72],  // I7
        data_d[89:81],  // Q7
        data[8:0],  // I8
        data[17:9],  // Q8
        data[32:24],  // I9
        data[41:33],  // Q9
        data[56:53]  // I10 MSB4
      };
      3'd6:
      return {
        data_d[52:48],  // I10 LSB5
        data_d[65:57],  // Q10
        data_d[80:72],  // I11
        data_d[89:81],  // Q11
        4'b0,  // PAD
        data[21:18],  // E
        data[8:0],  // I0
        data[17:9],  // Q0
        data[32:27]  // I1 MSB6
      };
      3'd0:
      return {
        data_d[26:24],  // I1 LSB3
        data_d[41:33],  // Q1
        data_d[56:48],  // I2
        data_d[65:57],  // Q2
        data_d[80:72],  // I3
        data_d[89:81],  // Q3
        data[8:0],  // I4
        data[17:11]  // Q4 MSB7
      };
      3'd1:
      return {
        data_d[10:9],  // Q4 LSB2
        data_d[32:24],  // I5
        data_d[41:33],  // Q5
        data_d[56:48],  // I6
        data_d[65:57],  // Q6
        data_d[80:72],  // I7
        data_d[89:81],  // Q7
        data[8:1]  // I8 MSB8
      };
      default:  // 3'd2
      return {
        data[0:0],  // I8 LSB1
        data[17:9],  // Q8
        data[32:24],  // I9
        data[41:33],  // Q9
        data[56:48],  // I10
        data[65:57],  // Q10
        data[80:72],  // I11
        data[89:81]  // Q11
      };
    endcase
  endfunction

  function automatic [63:0] byte_reverse(input logic [63:0] data);
    return {
      data[7:0],
      data[15:8],
      data[23:16],
      data[31:24],
      data[39:32],
      data[47:40],
      data[55:48],
      data[63:56]
    };
  endfunction


  always_ff @(posedge clk) begin
    if (fram_req_valid && (state == S_IDLE)) begin
      fram_req_header_reg <= fram_req_header;
    end
  end

  assign tdata = data_gb(bram_re_state, bram_data, bram_data_d);

  always_ff @(posedge clk) begin
    if (state == S_PRE3) begin  // state_next == S_PRE4
      m_fram_unsol_tdata <= byte_reverse(fram_req_header_reg);
    end else if (state == S_PRE4 && m_fram_unsol_tready) begin  // state_next == S_OUT
      m_fram_unsol_tdata <= byte_reverse(tdata);
    end else if (state == S_OUT && m_fram_unsol_tready) begin  // state_next == S_OUT | S_POST1
      m_fram_unsol_tdata <= byte_reverse(tdata);
    end else if (state == S_POST1 && m_fram_unsol_tready) begin  // state_next == POST1 | S_POST2
      m_fram_unsol_tdata <= byte_reverse(tdata);
    end else if (state == S_POST2 && m_fram_unsol_tready) begin  // state_next == POST2 | S_POST3
      m_fram_unsol_tdata <= byte_reverse(tdata);
    end else if (state == S_POST3 && m_fram_unsol_tready) begin  // state_next == POST3 | S_POST4
      m_fram_unsol_tdata <= byte_reverse(tdata);
    end else if (state == S_POST4 && m_fram_unsol_tready) begin  // state_next == S_POST 4 | S_LAST
      m_fram_unsol_tdata <= byte_reverse(tdata);
    end else begin
      m_fram_unsol_tdata <= m_fram_unsol_tdata;
    end
  end

  // Generate TKEEP of AXIS data.
  always_ff @(posedge clk) begin
    if (state_next == S_LAST) begin  // state == S_POST4
      // For last word, maybe not all words should be keep. It depends one the
      // number of RBs. If controller request even number of RBs, there will be
      // integer words in AXIS packet. So, all bytes of last word should be
      // keep. If controller request odd number of RBs, there will be one half
      // word in AXIS packet, so only half of last word should be keep.
      m_fram_unsol_tkeep <= (bram_re_state == 6) ? 4'b0011 : 4'b1111;
    end else begin
      m_fram_unsol_tkeep <= '1;
    end
  end

  // `m_fram_unsol_tvalid` should be set when state is `S_PRE4` (Header)
  // and when state is `S_OUT` and `S_POSTx` (BRAM data).
  always_ff @(posedge clk) begin
    m_fram_unsol_tvalid <= (state_next == S_PRE4 ||
        state_next == S_OUT || state_next == S_POST1 ||
        state_next == S_POST2 || state_next == S_POST3 ||
        state_next == S_POST4 || state_next == S_LAST);
  end

  assign m_fram_unsol_tlast = (state == S_LAST);

  // TUSER information. It will be set few ticks before tdata, but it's OK
  // [31:16] eAxC ID
  // [15:13] Ethernet Port
  // [12: 0] Incoming packet length in Bytes
  always_ff @(posedge clk) begin
    if ((state == S_IDLE) && fram_req_valid) begin
      m_fram_unsol_tuser <= {fram_req_rtc_pc_id, fram_req_ethport, packet_length};
    end
  end

  // 1 RB requires 3.5 words, which is 28 byte, plus 8-byte header
  assign packet_length = (fram_req_numprbc == 0 ? 273 : fram_req_numprbc) * 28 + 8;


  // BRAM Reader
  //============

  // logic [95:0] bram_data_d;
  // logic [ 2:0] bram_re_state;
  logic [11:0] bram_re_cnt;  // 0 ~ 4095, suit for 3276 REs
  logic [11:0] bram_re_end;


  always_ff @(posedge clk) begin
    if (state == S_IDLE && fram_req_valid) begin
      bram_re_cnt <= fram_req_startprbc * 12;
    end else if (state == S_PRE1) begin
      bram_re_cnt <= bram_re_cnt + 4;
    end else if (state == S_PRE2) begin
      bram_re_cnt <= bram_re_cnt + 4;
    end else if (state == S_PRE3) begin
      bram_re_cnt <= bram_re_cnt + 4;
    end else if (state == S_PRE4) begin
      bram_re_cnt <= ~m_fram_unsol_tready ? bram_re_cnt : bram_re_cnt + 4;
    end else if (state == S_OUT) begin
      bram_re_cnt <= ~m_fram_unsol_tready ? bram_re_cnt :
          (bram_re_state == 5) ? bram_re_cnt : bram_re_cnt + 4;
    end else begin
      bram_re_cnt <= '0;
    end
  end

  always_ff @(posedge clk) begin
    if (state == S_IDLE && fram_req_valid) begin
      bram_re_end <= (fram_req_startprbc +
          (fram_req_numprbc == 0 ? 273 : fram_req_numprbc)) * 12 - 4;
    end
  end

  always_ff @(posedge clk) begin
    if (state == S_IDLE && fram_req_valid) begin  // state_next == S_PRE1
      bram_re_state <= 0;
    end else if (state == S_PRE1) begin  // state_next == S_PRE2
      bram_re_state <= bram_re_state + 1;
    end else if (state == S_PRE2) begin  // state_next == S_PRE3
      bram_re_state <= bram_re_state + 1;
    end else if (state == S_PRE3) begin  // state_next == S_PRE4
      bram_re_state <= bram_re_state + 1;
    end else if (state == S_PRE4) begin  // state_next == S_OUT
      // From this tick, we need to check whether AXIS sink is ready
      bram_re_state <= ~m_fram_unsol_tready ? bram_re_state :
                (bram_re_state == 6) ? 0 : bram_re_state + 1;
    end else if (state == S_OUT) begin  // state_next == S_OUT | S_POST1
      bram_re_state <= ~m_fram_unsol_tready ? bram_re_state :
                (bram_re_state == 6) ? 0 : bram_re_state + 1;
    end else if (state == S_POST1) begin  // state_next == S_POST1 | S_POST2
      bram_re_state <= ~m_fram_unsol_tready ? bram_re_state :
                (bram_re_state == 6) ? 0 : bram_re_state + 1;
    end else if (state == S_POST2) begin  // state_next == S_POST2 | S_POST3
      bram_re_state <= ~m_fram_unsol_tready ? bram_re_state :
                (bram_re_state == 6) ? 0 : bram_re_state + 1;
    end else if (state == S_POST3) begin  // state_next == S_POST3 | S_POST4
      bram_re_state <= ~m_fram_unsol_tready ? bram_re_state :
                (bram_re_state == 6) ? 0 : bram_re_state + 1;
    end else if (state == S_POST4) begin  // state_next == S_POST4 | S_LAST
      bram_re_state <= ~m_fram_unsol_tready ? bram_re_state :
                (bram_re_state == 6) ? 0 : bram_re_state + 1;
    end else if (state == S_LAST) begin  // state_next = S_IDLE
      bram_re_state <= ~m_fram_unsol_tready ? bram_re_state : 0;
    end else begin
      bram_re_state <= '0;
    end
  end

  assign bram_addr = bram_re_cnt[11:2];

  assign bram_rden = (state == S_PRE1) || (state == S_PRE2) || (state == S_PRE3) ||
        ((state == S_PRE4) && m_fram_unsol_tready) ||
        ((state == S_OUT) && m_fram_unsol_tready) ||
        ((state == S_POST1) && m_fram_unsol_tready) ||
        ((state == S_POST2) && m_fram_unsol_tready) ||
        ((state == S_POST3) && m_fram_unsol_tready) ||
        ((state == S_POST4) && m_fram_unsol_tready);

  assign iq_done = (bram_re_cnt == bram_re_end);

  always_ff @(posedge clk) begin
    if (bram_rden) begin
      bram_data_d <= bram_data;
    end
  end

endmodule

`default_nettype wire
