`timescale 1 ns / 1 ps
//
`default_nettype none

// PUXCH BFP9 buffer.
//
// The FFT output is bit-reversed.  The write side reverses the sample count,
// removes the unused part of the FFT, and stores one provisional BFP value per
// RE.  The read side gathers one RB, takes the maximum of its twelve local
// exponents, and applies the additional right shift before the BFP gearbox.
//
// The IQ memory is split into even and odd natural-index lanes.  Consequently
// each write is a complete 18-bit word and does not need a byte-enable RAM.
// The two lanes together are the logical ping-pong 3584 x 36-bit memory in a
// full-block build.
module puxch_bfp_buffer #(
    parameter int ID              = 0,
    parameter int NUM_CC          = 3,
    parameter int HALF_BLOCK      = 0,
    parameter int HALF_FFT        = 0,
    parameter int FFT_ADDR_WIDTH  = (HALF_FFT != 0) ? 11 : 12,
    parameter int ACTIVE_RE_COUNT = (HALF_BLOCK != 0) ? 1920 : 3276
) (
    input var         clk,
    input var         rst,
    //
    input var  [15:0] din_dr         [NUM_CC],
    input var  [15:0] din_di         [NUM_CC],
    input var         din_sf         [NUM_CC],
    input var         din_sl         [NUM_CC],
    input var         din_sy         [NUM_CC],
    input var  [ 3:0] din_chn        [NUM_CC],
    input var         din_dv         [NUM_CC],
    //
    input var         clk_eth_xran,
    input var         rst_eth_xran,
    //
    input var  [11:0] s_ul_sym_num   [NUM_CC],
    //
    output var [63:0] m_axis_tdata,
    output var [ 7:0] m_axis_tkeep,
    output var        m_axis_tlast,
    output var        m_axis_tvalid,
    input var         m_axis_tready,
    //
    input var  [32:0] m_fram_data_req,
    //
    input var  [ 1:0] ctrl_rat       [NUM_CC],
    input var  [ 3:0] ctrl_bw        [NUM_CC],
    input var  [ 3:0] ctrl_fs_offset,
    // Kept in the interface for symmetry with the generic BFP path.  This
    // implementation is intentionally fixed to 9-bit IQ BFP.
    input var  [ 3:0] ctrl_ud_iq_width
);

  localparam int CcIndexWidth = (NUM_CC <= 1) ? 1 : $clog2(NUM_CC);
  localparam int IqBankDepth  = (HALF_BLOCK != 0) ? 1024 : 1792;
  localparam int MemDepth     = 2 * IqBankDepth;
  localparam int MemAddrWidth = $clog2(MemDepth);

  initial begin : drc_check
    assert (ID >= 0 && ID < 16)
    else $error("[%m]: ID (%0d) must fit in the four-bit channel field.", ID);

    assert (NUM_CC >= 1 && NUM_CC <= 16)
    else $error("[%m]: NUM_CC (%0d) must be within the range 1 to 16.", NUM_CC);

    assert (FFT_ADDR_WIDTH >= 1 && FFT_ADDR_WIDTH <= 12)
    else $error("[%m]: FFT_ADDR_WIDTH (%0d) must be within the range 1 to 12.",
                FFT_ADDR_WIDTH);

    assert (ACTIVE_RE_COUNT > 0 && ACTIVE_RE_COUNT <= (1 << FFT_ADDR_WIDTH))
    else $error("[%m]: ACTIVE_RE_COUNT (%0d) is invalid for FFT_ADDR_WIDTH (%0d).",
                ACTIVE_RE_COUNT, FFT_ADDR_WIDTH);

  end

  // -------------------------------------------------------------------------
  // First pass: bit-reversed FFT output to provisional per-RE BFP storage.
  // -------------------------------------------------------------------------

  logic [1:0] ctrl_rat_s[NUM_CC];
  logic [3:0] ctrl_bw_s [NUM_CC];
  logic [3:0] fft_size  [NUM_CC];

  logic                         wr_bank [NUM_CC];
  logic [FFT_ADDR_WIDTH-1:0]    wr_cnt  [NUM_CC];
  logic [FFT_ADDR_WIDTH-1:0]    wr_nat  [NUM_CC];
  logic [MemAddrWidth-1:0]      wr_addr [NUM_CC];
  logic                         wr_lane [NUM_CC];
  logic                         wr_we   [NUM_CC];
  logic [17:0]                  wr_iq   [NUM_CC];
  logic [ 5:0]                  wr_meta [NUM_CC];
  logic                         wr_we_d [NUM_CC];
  logic [17:0]                  wr_iq_d [NUM_CC];
  logic [ 5:0]                  wr_meta_d[NUM_CC];

  function automatic logic [3:0] msb_position(input logic [15:0] din);
    for (int i = 15; i > 0; i--) begin
      if (din[i] ^ din[i-1]) begin
        return i[3:0];
      end
    end
    return 4'd0;
  endfunction

  function automatic logic [3:0] get_shift(input logic [3:0] msb);
    logic [3:0] shift;
    shift = 4'd15 - msb;
    return (shift >= 4'd7) ? 4'd7 : shift;
  endfunction

  generate
    for (genvar cc = 0; cc < NUM_CC; cc++) begin : g_wr

      cdc_array_single #(
          .DEST_SYNC_FF (2),
          .INIT_SYNC_FF (0),
          .SRC_INPUT_REG(0),
          .WIDTH        (2 + 4)
      ) u_ctrl_cdc (
          .src_clk (1'b1),
          .src_in  ({ctrl_bw[cc], ctrl_rat[cc]}),
          //
          .dest_clk(clk),
          .dest_out({ctrl_bw_s[cc], ctrl_rat_s[cc]})
      );

      always_comb begin
        if (ctrl_rat_s[cc] == 2'd0) begin
          fft_size[cc] = 4'd2;
        end else if (ctrl_rat_s[cc] == 2'd1) begin
          case (ctrl_bw_s[cc])
            4'b0000, 4'b0001, 4'b0010: fft_size[cc] = 4'd2;
            default:                    fft_size[cc] = 4'd1;
          endcase
        end else begin
          case (ctrl_bw_s[cc])
            4'b0000, 4'b0001, 4'b0010: fft_size[cc] = 4'd4;
            4'b0011:                    fft_size[cc] = 4'd2;
            default:                    fft_size[cc] = 4'd1;
          endcase
        end
      end

      always_ff @(posedge clk) begin
        if (rst) begin
          wr_bank[cc] <= 1'b0;
        end else if (din_sf[cc]) begin
          wr_bank[cc] <= 1'b0;
        end else if (din_sy[cc] && (din_chn[cc] == 4'd0)) begin
          wr_bank[cc] <= ~wr_bank[cc];
        end
      end

      always_ff @(posedge clk) begin
        if (rst || din_sy[cc]) begin
          wr_cnt[cc] <= '0;
        end else if (din_dv[cc] && (din_chn[cc] == 4'(ID))) begin
          wr_cnt[cc] <= wr_cnt[cc] + fft_size[cc];
        end
      end

      // Natural RE address corresponding to the current bit-reversed FFT
      // output count.  The counter stride is retained from puxch_buffer so
      // 1k/2k/4k FFT configurations use the same physical mapping.
      always_comb begin
        wr_nat[cc] = '0;
        for (int i = 0; i < FFT_ADDR_WIDTH; i++) begin
          wr_nat[cc][i] = wr_cnt[cc][FFT_ADDR_WIDTH-1-i];
        end
      end

      always_comb begin
        wr_addr[cc] = MemAddrWidth'(wr_nat[cc] >> 1);
        if (wr_bank[cc]) begin
          wr_addr[cc] = MemAddrWidth'(IqBankDepth) + MemAddrWidth'(wr_nat[cc] >> 1);
        end
        wr_lane[cc] = wr_nat[cc][0];
        wr_we[cc] = din_dv[cc] && (din_chn[cc] == 4'(ID));
      end

      logic [3:0] local_msb;
      logic [3:0] local_shift;
      logic signed [15:0] scaled_i;
      logic signed [15:0] scaled_q;

      always_comb begin
        local_msb   = msb_position(din_dr[cc]) >= msb_position(din_di[cc]) ?
          msb_position(din_dr[cc]) : msb_position(din_di[cc]);
        local_shift = get_shift(local_msb);
        scaled_i    = $signed(din_dr[cc]) <<< local_shift;
        scaled_q    = $signed(din_di[cc]) <<< local_shift;

        // The four low bits are the local (unbiased) exponent.  The guard
        // bits are retained so the second pass can round after its extra
        // right shift without restoring the original 16-bit sample.
        wr_iq[cc]   = {scaled_i[15:7], scaled_q[15:7]};
        wr_meta[cc] = {scaled_q[6], scaled_i[6], 4'd15 - local_shift};
      end

      // Match the one-cycle write staging used by the original raw buffer.
      // This allows din_sy to reset/toggle the address state on the same
      // cycle as the first FFT sample without writing that sample to the
      // previous bank/address.
      always_ff @(posedge clk) begin
        if (rst) begin
          wr_we_d[cc]   <= 1'b0;
          wr_iq_d[cc]   <= '0;
          wr_meta_d[cc] <= '0;
        end else begin
          wr_we_d[cc]   <= wr_we[cc];
          wr_iq_d[cc]   <= wr_iq[cc];
          wr_meta_d[cc] <= wr_meta[cc];
        end
      end

    end
  endgenerate

  // Four independent memory lanes per carrier: even/odd IQ and the matching
  // six-bit exponent/guard metadata.  Both IQ and metadata go to block RAM:
  // a 3584-deep distributed RAM would cost ~450 LUTs per instance, which is
  // a poor trade on a LUT-starved part.
  logic [17:0] iq_dout   [NUM_CC][2];
  logic [ 5:0] meta_dout [NUM_CC][2];

  logic rd_en [NUM_CC];
  logic rd_en_d[NUM_CC];

  logic [MemAddrWidth-1:0] rd_addr;

  generate
    for (genvar cc = 0; cc < NUM_CC; cc++) begin : g_ram_cc
      for (genvar lane = 0; lane < 2; lane++) begin : g_ram_lane

        ram_sdp #(
            .ADDR_WIDTH  (MemAddrWidth),
            .DATA_WIDTH  (18),
            .READ_LATENCY(2),
            .DEPTH       (MemDepth),
            .INIT_FILE   ("NONE"),
            .RAM_STYLE   ("BLOCK")
        ) u_iq_ram (
            .clka (clk),
            .wea  (wr_we_d[cc] && (wr_nat[cc] < ACTIVE_RE_COUNT) &&
              (wr_lane[cc] == lane)),
            .addra(wr_addr[cc]),
            .dina (wr_iq_d[cc]),
            //
            .clkb (clk_eth_xran),
            .rstb (rst_eth_xran),
            .enb  ({rd_en_d[cc], rd_en[cc]}),
            .addrb(rd_addr),
            .doutb(iq_dout[cc][lane])
        );

        ram_sdp #(
            .ADDR_WIDTH  (MemAddrWidth),
            .DATA_WIDTH  (6),
            .READ_LATENCY(2),
            .DEPTH       (MemDepth),
            .INIT_FILE   ("NONE"),
            .RAM_STYLE   ("BLOCK")
        ) u_meta_ram (
            .clka (clk),
            .wea  (wr_we_d[cc] && (wr_nat[cc] < ACTIVE_RE_COUNT) &&
              (wr_lane[cc] == lane)),
            .addra(wr_addr[cc]),
            .dina (wr_meta_d[cc]),
            //
            .clkb (clk_eth_xran),
            .rstb (rst_eth_xran),
            .enb  ({rd_en_d[cc], rd_en[cc]}),
            .addrb(rd_addr),
            .doutb(meta_dout[cc][lane])
        );

      end

      always_ff @(posedge clk_eth_xran) begin
        if (rst_eth_xran) begin
          rd_en_d[cc] <= 1'b0;
        end else begin
          rd_en_d[cc] <= rd_en[cc];
        end
      end

    end
  endgenerate

  // -------------------------------------------------------------------------
  // Request queue and second pass.
  // -------------------------------------------------------------------------

  logic       req_valid;
  logic [ 8:0] req_startprb;
  logic [ 7:0] req_numprb;
  logic [ 3:0] req_cc;
  logic [20:0] req_data;

  logic       fifo_rden;
  logic [20:0] fifo_dout;
  logic       fifo_empty;
  logic       fifo_full;

  logic       fifo_req_valid;
  logic [ 8:0] fifo_req_startprb;
  logic [ 7:0] fifo_req_numprb;
  logic [ 3:0] fifo_req_cc;
  logic       fifo_req_ready;
  logic       rd_busy;
  logic       pack_done;

  assign req_valid    = m_fram_data_req[24];
  assign req_startprb = m_fram_data_req[23:15];
  assign req_numprb   = m_fram_data_req[14:7];
  assign req_cc       = m_fram_data_req[3:0];
  assign req_data     = {req_startprb, req_numprb, req_cc};

  fifo_srl #(
      .FIFO_DEPTH(16),
      .DATA_WIDTH(21)
  ) u_req_fifo (
      .clk  (clk_eth_xran),
      .rst  (rst_eth_xran),
      //
      .wren (req_valid),
      .din  (req_data),
      .full (fifo_full),
      //
      .rden (fifo_rden),
      .dout (fifo_dout),
      .empty(fifo_empty)
  );

  assign {fifo_req_startprb, fifo_req_numprb, fifo_req_cc} = fifo_dout;
  assign fifo_req_valid = ~fifo_empty;
  assign fifo_req_ready = ~rd_busy;
  assign fifo_rden      = fifo_req_ready;

  logic [ 3:0]                rd_cc;
  logic                       rd_bank;
  logic [11:0]                rd_word_addr;
  logic [11:0]                rd_words_left;
  logic [ 2:0]                rd_group_idx;
  logic                       rd_issue_fire;
  logic [ 2:0]                rd_issue_idx;
  logic                       rd_issue_last;

  assign rd_issue_fire = rd_busy && (rd_words_left != 0) &&
    (rd_cc < 4'(NUM_CC));
  assign rd_issue_idx   = rd_group_idx;
  assign rd_issue_last  = rd_issue_fire && (rd_words_left == 12'd1);

  always_comb begin
    rd_addr = MemAddrWidth'(rd_word_addr);
    if (rd_bank) begin
      rd_addr = MemAddrWidth'(IqBankDepth) + MemAddrWidth'(rd_word_addr);
    end
    for (int i = 0; i < NUM_CC; i++) begin
      rd_en[i] = rd_issue_fire && (rd_cc == i);
    end
  end

  always_ff @(posedge clk_eth_xran) begin
    if (rst_eth_xran) begin
      rd_busy      <= 1'b0;
      rd_cc        <= '0;
      rd_bank      <= 1'b0;
      rd_word_addr <= '0;
      rd_words_left<= '0;
      rd_group_idx <= '0;
    end else begin
      if (fifo_req_valid && fifo_req_ready) begin
        rd_cc         <= fifo_req_cc;
        rd_bank       <= (fifo_req_cc < 4'(NUM_CC)) ?
          s_ul_sym_num[fifo_req_cc[CcIndexWidth-1:0]][0] : 1'b0;
        rd_word_addr  <= 12'(fifo_req_startprb) * 12'd6;
        rd_words_left <= 12'(fifo_req_numprb) * 12'd6;
        rd_group_idx  <= '0;
        rd_busy       <= (fifo_req_cc < 4'(NUM_CC)) && (fifo_req_numprb != 0);
      end else if (rd_issue_fire) begin
        rd_word_addr  <= rd_word_addr + 1'b1;
        rd_words_left <= rd_words_left - 1'b1;
        rd_group_idx  <= (rd_group_idx == 3'd5) ? 3'd0 : rd_group_idx + 1'b1;
      end

      if (pack_done) begin
        rd_busy <= 1'b0;
      end
    end
  end

  // RAM output pipeline.  The RAM's second read-enable stage makes the data
  // visible after the following edge; the capture below therefore uses the
  // two-stage issue pipeline.
  logic       rd_pipe_valid0;
  logic       rd_pipe_valid1;
  logic [ 2:0] rd_pipe_idx0;
  logic [ 2:0] rd_pipe_idx1;
  logic       rd_pipe_last0;
  logic       rd_pipe_last1;

  logic [35:0] rd_iq_c;
  logic [11:0] rd_meta_c;

  always_comb begin
    rd_iq_c   = '0;
    rd_meta_c = '0;
    for (int i = 0; i < NUM_CC; i++) begin
      if (rd_cc == i) begin
        rd_iq_c   = {iq_dout[i][1], iq_dout[i][0]};
        rd_meta_c = {meta_dout[i][1], meta_dout[i][0]};
      end
    end
  end

  logic [35:0] rb_iq   [6];
  logic [11:0] rb_meta [6];
  logic        rb_group_ready;
  logic        rb_group_last;

  always_ff @(posedge clk_eth_xran) begin
    if (rst_eth_xran) begin
      rd_pipe_valid0 <= 1'b0;
      rd_pipe_valid1 <= 1'b0;
      rd_pipe_idx0   <= '0;
      rd_pipe_idx1   <= '0;
      rd_pipe_last0  <= 1'b0;
      rd_pipe_last1  <= 1'b0;
      rb_group_ready <= 1'b0;
      rb_group_last  <= 1'b0;
      for (int i = 0; i < 6; i++) begin
        rb_iq[i]   <= '0;
        rb_meta[i] <= '0;
      end
    end else begin
      rd_pipe_valid0 <= rd_issue_fire;
      rd_pipe_valid1 <= rd_pipe_valid0;
      rd_pipe_idx0   <= rd_issue_idx;
      rd_pipe_idx1   <= rd_pipe_idx0;
      rd_pipe_last0  <= rd_issue_last;
      rd_pipe_last1  <= rd_pipe_last0;

      rb_group_ready <= 1'b0;
      if (rd_pipe_valid1) begin
        rb_iq[rd_pipe_idx1]   <= rd_iq_c;
        rb_meta[rd_pipe_idx1] <= rd_meta_c;
        if (rd_pipe_idx1 == 3'd5) begin
          rb_group_ready <= 1'b1;
          rb_group_last  <= rd_pipe_last1;
        end
      end
    end
  end

  // Sync the frame-scale offset into the read clock domain.  The local
  // exponent stored in metadata is deliberately before this offset, so the
  // second-pass shift uses the full exponent range.
  logic [3:0] ctrl_fs_offset_s;

  cdc_array_single #(
      .DEST_SYNC_FF (2),
      .INIT_SYNC_FF (0),
      .SRC_INPUT_REG(0),
      .WIDTH        (4)
  ) u_ctrl_fs_offset_cdc (
      .src_clk (1'b1),
      .src_in  (ctrl_fs_offset),
      //
      .dest_clk(clk_eth_xran),
      .dest_out(ctrl_fs_offset_s)
  );

  function automatic logic signed [8:0] round_mantissa(
      input logic signed [8:0] din,
      input logic [3:0]       delta,
      input logic             guard
  );
    logic signed [9:0] quotient;
    logic signed [9:0] rounded;
    logic              round_up;

    if (delta == 0) begin
      quotient = {din[8], din};
      round_up = guard;
    end else if (delta >= 9) begin
      quotient = '0;
      round_up = 1'b0;
    end else begin
      quotient = $signed(din) >>> delta;
      round_up = din[delta-1];
    end

    rounded = quotient + (round_up ? 10'sd1 : 10'sd0);
    if (rounded > 10'sd255) begin
      return 9'sd255;
    end else if (rounded < -10'sd256) begin
      return -9'sd256;
    end else begin
      return rounded[8:0];
    end
  endfunction

  logic [3:0]             rb_exp_wire;
  logic signed [8:0]      rb_mant [24];
  logic [223:0]           rb_group_bits;

  always_comb begin
    rb_exp_wire = 4'd0;
    for (int i = 0; i < 6; i++) begin
      if (rb_meta[i][3:0] > rb_exp_wire) begin
        rb_exp_wire = rb_meta[i][3:0];
      end
      if (rb_meta[i][9:6] > rb_exp_wire) begin
        rb_exp_wire = rb_meta[i][9:6];
      end
    end

    for (int re = 0; re < 12; re++) begin
      int word;
      logic signed [8:0] provisional_i;
      logic signed [8:0] provisional_q;
      logic [3:0] local_exp_i;
      logic [3:0] local_exp_q;
      logic [3:0] delta_i;
      logic [3:0] delta_q;
      logic       guard_i;
      logic       guard_q;

      word = re / 2;
      if ((re & 1) == 0) begin
        provisional_i = $signed(rb_iq[word][17:9]);
        provisional_q = $signed(rb_iq[word][8:0]);
        local_exp_i   = rb_meta[word][3:0];
        local_exp_q   = rb_meta[word][3:0];
      end else begin
        provisional_i = $signed(rb_iq[word][35:27]);
        provisional_q = $signed(rb_iq[word][26:18]);
        local_exp_i   = rb_meta[word][9:6];
        local_exp_q   = rb_meta[word][9:6];
      end

      // The word stores two REs.  The exponent and guard fields are selected
      // by the even/odd natural-index lane.
      if ((re & 1) == 0) begin
        local_exp_i = rb_meta[word][3:0];
        local_exp_q = rb_meta[word][3:0];
        guard_i     = rb_meta[word][4];
        guard_q     = rb_meta[word][5];
      end else begin
        local_exp_i = rb_meta[word][9:6];
        local_exp_q = rb_meta[word][9:6];
        guard_i     = rb_meta[word][10];
        guard_q     = rb_meta[word][11];
      end

      delta_i = rb_exp_wire - local_exp_i;
      delta_q = rb_exp_wire - local_exp_q;
      rb_mant[2*re] = round_mantissa(provisional_i, delta_i, guard_i);
      rb_mant[2*re+1] = round_mantissa(provisional_q, delta_q, guard_q);
    end

    rb_group_bits = '0;
    rb_group_bits[7:0] = {4'd0, rb_exp_wire -
      ((rb_exp_wire >= ctrl_fs_offset_s) ? ctrl_fs_offset_s : rb_exp_wire)};
    for (int scalar = 0; scalar < 24; scalar++) begin
      for (int bit_index = 0; bit_index < 9; bit_index++) begin
        // The BFP payload is an MSB-first bitstream after the exponent byte,
        // while the AXI data word below is represented in little-endian byte
        // order.  This maps the first payload bit to byte 1 bit 7.
        rb_group_bits[8 + ((scalar*9 + bit_index) / 8) * 8 +
          7 - ((scalar*9 + bit_index) % 8)] = rb_mant[scalar][8-bit_index];
      end
    end
  end

  // -------------------------------------------------------------------------
  // Byte gearbox and AXI output FIFO.
  // -------------------------------------------------------------------------

  logic [287:0] pack_buffer;
  logic [287:0] pack_buffer_next;
  logic [  8:0] pack_bits;
  logic [  8:0] pack_bits_next;
  logic         pack_final;
  logic         pack_final_next;
  logic [63:0]  pack_tdata;
  logic [ 7:0]  pack_tkeep;
  logic         pack_tvalid;
  logic         pack_tlast;

  assign pack_tdata = pack_buffer[63:0];
  assign pack_tvalid = (pack_bits >= 9'd64) ||
    (pack_final && (pack_bits != 0));
  assign pack_tlast = pack_final && (pack_bits <= 9'd64);
  assign pack_tkeep = (pack_bits >= 9'd64) ? 8'hFF :
    ((pack_bits == 9'd32) ? 8'h0F : 8'h00);
  assign pack_done = pack_tvalid && pack_tlast;

  always_comb begin
    pack_buffer_next = pack_buffer;
    pack_bits_next   = pack_bits;
    pack_final_next  = pack_final;

    if (pack_tvalid) begin
      if (pack_tlast) begin
        // The final beat may contain only 32 valid bits.  Do not subtract
        // 64 from that count: the unsigned counter would underflow and
        // contaminate the next packet.  Clear the unused buffer contents as
        // well, since the next packet is packed from bit zero.
        pack_buffer_next = '0;
        pack_bits_next   = '0;
        pack_final_next = 1'b0;
      end else begin
        pack_buffer_next = pack_buffer >> 64;
        pack_bits_next   = pack_bits - 9'd64;
      end
    end

    if (rb_group_ready) begin
      pack_buffer_next = pack_buffer_next |
        (288'(rb_group_bits) << pack_bits_next);
      pack_bits_next  = pack_bits_next + 9'd224;
      if (rb_group_last) begin
        pack_final_next = 1'b1;
      end
    end
  end

  always_ff @(posedge clk_eth_xran) begin
    if (rst_eth_xran) begin
      pack_buffer <= '0;
      pack_bits   <= '0;
      pack_final  <= 1'b0;
    end else begin
      pack_buffer <= pack_buffer_next;
      pack_bits   <= pack_bits_next;
      pack_final  <= pack_final_next;
    end
  end

  logic [63:0] fifo_axis_tdata;
  logic [ 7:0] fifo_axis_tkeep;
  logic        fifo_axis_tlast;
  logic        fifo_axis_tvalid;
  logic        reg_axis_tready;
  logic        fifo_axis_tuser;
  logic        reg_axis_tuser;
  logic        fifo_err_discard;

  axis_fifo_alt #(
      .ASYNC_MODE  (0),
      .FIFO_DEPTH  (2048),
      .FIFO_LATENCY(2),
      .DATA_WIDTH  (64),
      .USER_WIDTH  (1)
  ) u_fifo (
      .s_axis_aclk   (clk_eth_xran),
      .s_axis_aresetn(~rst_eth_xran),
      //
      .s_axis_tdata  (pack_tdata),
      .s_axis_tkeep  (pack_tkeep),
      .s_axis_tlast  (pack_tlast),
      .s_axis_tuser  ('0),
      .s_axis_tvalid (pack_tvalid),
      //
      .m_axis_aclk   (clk_eth_xran),
      //
      .m_axis_tdata  (fifo_axis_tdata),
      .m_axis_tkeep  (fifo_axis_tkeep),
      .m_axis_tlast  (fifo_axis_tlast),
      .m_axis_tuser  (fifo_axis_tuser),
      .m_axis_tvalid (fifo_axis_tvalid),
      .m_axis_tready (reg_axis_tready),
      .err_discard   (fifo_err_discard)
  );

  axis_reg #(
      .DATA_WIDTH(64),
      .USER_WIDTH(1)
  ) u_axis_reg (
      .aclk         (clk_eth_xran),
      .aresetn      (~rst_eth_xran),
      //
      .s_axis_tdata (fifo_axis_tdata),
      .s_axis_tkeep (fifo_axis_tkeep),
      .s_axis_tlast (fifo_axis_tlast),
      .s_axis_tuser (1'b0),
      .s_axis_tvalid(fifo_axis_tvalid),
      .s_axis_tready(reg_axis_tready),
      //
      .m_axis_tdata (m_axis_tdata),
      .m_axis_tkeep (m_axis_tkeep),
      .m_axis_tlast (m_axis_tlast),
      .m_axis_tuser (reg_axis_tuser),
      .m_axis_tvalid(m_axis_tvalid),
      .m_axis_tready(m_axis_tready)
  );

  wire unused_din_sl = &{1'b0, din_sl[0], 1'b0};
  wire unused_ctrl_ud_iq_width = &{1'b0, ctrl_ud_iq_width, 1'b0};
  wire unused_fifo_full = fifo_full;
  wire unused_fifo_err_discard = fifo_err_discard;
  wire unused_fifo_axis_tuser = fifo_axis_tuser;
  wire unused_reg_axis_tuser = reg_axis_tuser;

endmodule

`default_nettype wire
