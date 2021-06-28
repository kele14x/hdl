`timescale 1 ns / 1 ps `default_nettype none

module srs_adaptor_framer (
    input var         clk,
    input var         rst,
    // Frame Request
    //==============
    input var  [ 2:0] fram_req_eth_port,
    input var  [63:0] fram_req_header,
    input var  [ 8:0] fram_req_start_rb,
    input var  [ 7:0] fram_req_num_rb,
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


  // FSM
  //====

  // Sending one packet require we send header (64-bit) then IQ data
  typedef enum int {
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
      state <= S_IDLE;
    end else begin
      state <= state_next;
    end
  end

  always_comb begin
    case (state)
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
      default: state_next = S_IDLE;
    endcase
  end


  // FRAM Request Accept Interface
  //==============================

  // Will only accept next frame request when `S_IDLE` again.
  always_ff @(posedge clk) begin
    if (rst) begin
      fram_req_ready <= 1'b0;
    end else begin
      fram_req_ready <= (state_next == S_IDLE);
    end
  end


  // AXIS Interface
  //===============

  logic [95:0] bram_data_d;
  logic [ 2:0] bram_re_state;

  logic [63:0] tdata;

  logic [15:0] ecpri_axc_id;
  logic [12:0] packet_length;

  function [63:0] data_gb(input logic [2:0] state, input logic [95:0] data,
                          input logic [95:0] data_d);
    case (state)
      3'd3:
      return {
        4'b0,
        data[21:18],
        data[8:0],
        data[17:9],
        data[32:24],
        data[41:33],
        data[56:48],
        data[65:57],
        data[80:79]
      };
      3'd4:
      return {
        data_d[78:72],
        data_d[89:81],
        data[8:0],
        data[17:9],
        data[32:24],
        data[41:33],
        data[56:48],
        data[65:63]
      };
      3'd5:
      return {
        data_d[62:57],
        data_d[80:72],
        data_d[89:81],
        data[8:0],
        data[17:9],
        data[32:24],
        data[41:33],
        data[56:53]
      };
      3'd6:
      return {
        data_d[52:48],
        data_d[65:57],
        data_d[80:72],
        data_d[89:81],
        4'b0,
        data[21:18],
        data[8:0],
        data[17:9],
        data[32:27]
      };
      3'd0:
      return {
        data_d[26:24],
        data_d[41:33],
        data_d[56:48],
        data_d[65:57],
        data_d[80:72],
        data_d[89:81],
        data[8:0],
        data[17:11]
      };
      3'd1:
      return {
        data_d[10:9],
        data_d[32:24],
        data_d[41:33],
        data_d[56:48],
        data_d[65:57],
        data_d[80:72],
        data_d[89:81],
        data[7:0]
      };
      default:
      return {
        data_d[8:8],
        data_d[17:9],
        data_d[32:24],
        data_d[41:33],
        data_d[56:48],
        data_d[65:57],
        data_d[80:72],
        data_d[89:81]
      };  // 2
    endcase
  endfunction

  function [63:0] byte_reverse(input logic [63:0] data);
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


  assign tdata = data_gb(bram_re_state, bram_data, bram_data_d);

  always_ff @(posedge clk) begin
    if (state == S_PRE3) begin  // state_next == S_PRE4
      m_fram_unsol_tdata <= fram_req_header;
    end else if (state == S_PRE4 && m_fram_unsol_tready) begin  // state_next == S_OUT
      m_fram_unsol_tdata <= byte_reverse(tdata);
    end else if (state == S_OUT && m_fram_unsol_tready) begin
      m_fram_unsol_tdata <= byte_reverse(tdata);
    end else if (state == S_POST1 && m_fram_unsol_tready) begin
      m_fram_unsol_tdata <= byte_reverse(tdata);
    end else if (state == S_POST2 && m_fram_unsol_tready) begin
      m_fram_unsol_tdata <= byte_reverse(tdata);
    end else if (state == S_POST3 && m_fram_unsol_tready) begin
      m_fram_unsol_tdata <= byte_reverse(tdata);
    end else if (state == S_POST4 && m_fram_unsol_tready) begin  // state_next == S_LAST
      m_fram_unsol_tdata <= byte_reverse(tdata);
    end else begin
      m_fram_unsol_tdata <= m_fram_unsol_tdata;
    end
  end

  // If controller request odd number of RBs, last word only have 32-bit valid
  // data, so tkeep should be set to 8'h0F.
  always_ff @(posedge clk) begin
    if (state_next == S_PRE4) begin
      m_fram_unsol_tkeep <= '1;
    end else if (state_next == S_OUT) begin
      m_fram_unsol_tkeep <= '1;
    end else if (state_next == S_POST1) begin
      m_fram_unsol_tkeep <= '1;
    end else if (state_next == S_POST2) begin
      m_fram_unsol_tkeep <= '1;
    end else if (state_next == S_POST3) begin
      m_fram_unsol_tkeep <= '1;
    end else if (state_next == S_POST4) begin
      m_fram_unsol_tkeep <= '1;
    end else if (state_next == S_LAST) begin
      // TODO: last word may not all should be keep
      m_fram_unsol_tkeep <= '1;
    end else begin
      m_fram_unsol_tkeep <= m_fram_unsol_tkeep;
    end
  end

  // `m_fram_unsol_tvalid` should be set when state is `S_PRE4` (Header)
  // and when state is `S_OUT` and `S_POSTx` (BRAM data).
  always_ff @(posedge clk) begin
    if (rst) begin
      m_fram_unsol_tvalid <= 1'b0;
    end else begin
      m_fram_unsol_tvalid <= (state_next == S_PRE4 ||
                state_next == S_OUT || state_next == S_POST1 ||
                state_next == S_POST2 || state_next == S_POST3 ||
                state_next == S_POST4 || state_next == S_LAST);
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      m_fram_unsol_tlast <= 1'b0;
    end else begin
      m_fram_unsol_tlast <= (state_next == S_LAST);
    end
  end

  // TUSER information. It will be set few ticks before tdata, but it's OK
  // [31:16] eAxC ID
  // [15:13] Ethernet Port
  // [12: 0] Incoming packet length in Bytes
  always_ff @(posedge clk) begin
    if (rst) begin
      m_fram_unsol_tuser <= 1'b0;
    end else if (state == S_IDLE && fram_req_valid) begin
      m_fram_unsol_tuser <= {ecpri_axc_id, fram_req_eth_port, packet_length};
    end
  end

  // RTC/PC ID
  assign ecpri_axc_id  = fram_req_header[63:48];

  // 1 RB requires 3.5 words, which is 28 byte, plus 8-byte header
  assign packet_length = fram_req_num_rb * 28 + 8;


  // BRAM Reader
  //============

  // logic [95:0] bram_data_d;
  // logic [ 2:0] bram_re_state;
  logic [11:0] bram_re_cnt;  // 0 ~ 4095, suit for 3276 REs
  logic [11:0] bram_re_end;


  always_ff @(posedge clk) begin
    if (state == S_IDLE && fram_req_valid) begin
      bram_re_cnt <= fram_req_start_rb * 12;
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
      bram_re_end <= (fram_req_start_rb + fram_req_num_rb) * 12 - 4;
    end
  end

  always_ff @(posedge clk) begin
    if (state == S_IDLE && fram_req_valid) begin
      bram_re_state <= 0;
    end else if (state == S_PRE1) begin
      bram_re_state <= bram_re_state + 1;
    end else if (state == S_PRE2) begin
      bram_re_state <= bram_re_state + 1;
    end else if (state == S_PRE3) begin
      bram_re_state <= bram_re_state + 1;
    end else if (state == S_PRE4) begin
      bram_re_state <= ~m_fram_unsol_tready ? bram_re_state : bram_re_state + 1;
    end else if (state == S_OUT) begin
      bram_re_state <= ~m_fram_unsol_tready ? bram_re_state :
                (bram_re_state == 6) ? 0 : bram_re_state + 1;
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
