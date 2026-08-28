`timescale 1 ns / 1 ps
//
`default_nettype none

module puxch_buffer #(
    parameter int ID         = 0,
    parameter int NUM_CC     = 3,
    parameter int HALF_BLOCK = 0
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
    input var  [ 3:0] ctrl_bw        [NUM_CC]
);

  // Signals

  logic [       1:0] ctrl_rat_s        [NUM_CC];
  logic [       3:0] ctrl_bw_s         [NUM_CC];

  logic [       3:0] fft_size          [NUM_CC];

  logic              req_valid;
  logic [       8:0] req_startprb;
  logic [       7:0] req_numprb;
  logic [       3:0] req_cc;
  logic [      20:0] req_data;

  logic              fifo_rden;
  logic [      20:0] fifo_dout;
  logic              fifo_empty;
  logic              fifo_full;

  logic              fifo_req_valid;
  logic [       8:0] fifo_req_startprb;
  logic [       7:0] fifo_req_numprb;
  logic [       3:0] fifo_req_cc;
  logic              fifo_req_ready;

  logic [      10:0] fifo_req_endprb;

  logic              wr_bank           [NUM_CC];
  logic [      11:0] wr_cnt            [NUM_CC];
  logic [      11:0] wr_cnt_rev        [NUM_CC];
  logic [      12:0] wr_addr           [NUM_CC];
  logic              wr_we             [NUM_CC];

  logic              rd_busy;
  logic              rd_issue;
  logic              rd_bank;
  logic [      10:0] rd_cnt;
  logic [      11:0] rd_addr;
  logic              rd_en             [NUM_CC];
  logic              rd_en_d           [NUM_CC];
  logic              rd_en_dd          [NUM_CC];
  logic [NUM_CC-1:0] rd_pipe_en;
  logic [      63:0] rd_dout           [NUM_CC];
  logic [      63:0] rd_data_c;
  logic              rd_last;
  logic              last_d1;
  logic              last_d2;

  logic              ram_out_v;
  logic [       4:0] out_cnt;
  logic              out_stall;
  logic              out_wren;
  logic              out_rden;
  logic              out_empty;
  logic              out_full;
  logic [      64:0] out_dout;

  logic [      63:0] s0_axis_tdata;

  logic [      63:0] s1_axis_tdata;
  logic [       7:0] s1_axis_tkeep;
  logic              s1_axis_tlast;
  logic              s1_axis_tvalid;
  logic              s1_axis_tready;
  logic              reg_m_axis_tuser;

  localparam int CcIndexWidth = (NUM_CC <= 1) ? 1 : $clog2(NUM_CC);

  localparam int FullMaxPrb = 275;
  localparam int FullMaxRe = FullMaxPrb * 12;
  localparam int FullIqBankDepth = 1792;
  localparam int FullNarrowBankDepth = FullIqBankDepth * 2;
  localparam int FullNarrowDepth = FullNarrowBankDepth * 2;

  // Small output FIFO replacing the store-and-forward packet FIFO. The read
  // pipeline has 3 cycles of latency from issue to FIFO write, so the stall
  // threshold must keep at least 3 words of headroom.
  localparam int OutFifoDepth = 16;
  localparam int OutFifoAlmostFull = OutFifoDepth - 3;

  initial begin : drc_check
    assert (NUM_CC >= 1 && NUM_CC <= 16)
    else $error("[%m]: NUM_CC (%0d) must be in the range 1 to 16.", NUM_CC);

    assert (ID >= 0 && ID < 16)
    else $error("[%m]: ID (%0d) must fit in din_chn.", ID);
  end

  function automatic logic [3:0] msb_position(input logic [15:0] data);
    for (int i = 15; i > 0; i--) begin
      if (data[i] ^ data[i-1]) return i[3:0];
    end
    return 0;
  endfunction

  function automatic logic [3:0] bfp9_re_exp(input logic [15:0] data_i, input logic [15:0] data_q);
    logic [3:0] msb_i;
    logic [3:0] msb_q;
    logic [3:0] msb;
    logic [3:0] shift;

    msb_i = msb_position(data_i);
    msb_q = msb_position(data_q);
    msb = (msb_i >= msb_q) ? msb_i : msb_q;
    shift = 15 - msb;
    shift = (shift >= 7) ? 7 : shift;
    bfp9_re_exp = 15 - shift;
  endfunction

  function automatic logic [8:0] bfp9_re_compress(input logic [15:0] data, input logic [3:0] exp);
    logic [15:0] rounded;
    logic [ 3:0] shift;

    shift   = 15 - exp;
    rounded = data << shift;
    rounded = rounded | 16'h003F;
    if (rounded != 16'h7FFF) begin
      rounded = rounded + 1'b1;
    end
    bfp9_re_compress = rounded[15:7];
  endfunction

  function automatic logic [15:0] bfp9_re_decompress(input logic [8:0] data, input logic [3:0] exp);
    logic signed [16:0] expanded;

    expanded = $signed(data);
    expanded = expanded <<< (exp - 8);
    bfp9_re_decompress = expanded[15:0];
  endfunction

  // CDC for control signals

  generate
    for (genvar i = 0; i < NUM_CC; i++) begin : g_cdc

      cdc_array_single #(
          .DEST_SYNC_FF (2),
          .INIT_SYNC_FF (0),
          .SRC_INPUT_REG(0),
          .WIDTH        (2 + 4)
      ) u_ctrl_cdc (
          .src_clk (1'b1),
          .src_in  ({ctrl_bw[i], ctrl_rat[i]}),
          //
          .dest_clk(clk),
          .dest_out({ctrl_bw_s[i], ctrl_rat_s[i]})
      );

      // Main

      always_comb begin
        if (ctrl_rat_s[i] == 0) begin  // LTE
          fft_size[i] = 4'd2;  // 2k
        end else if (ctrl_rat_s[i] == 1) begin  // 15 kHz SCS NR
          case (ctrl_bw_s[i])
            4'b0000: fft_size[i] = 4'd2;  // 7.68 (30.72), 2k
            4'b0001: fft_size[i] = 4'd2;  // 15.36 (30.72), 2k
            4'b0010: fft_size[i] = 4'd2;  // 30.72, 2k
            default: fft_size[i] = 4'd1;  // 61.44, 4k
          endcase
        end else begin
          case (ctrl_bw_s[i])
            4'b0000: fft_size[i] = 4'd4;  // 7.68 (30.72), 1k
            4'b0001: fft_size[i] = 4'd4;  // 15.36 (30.72), 1k
            4'b0010: fft_size[i] = 4'd4;  // 30.72, 1k
            4'b0011: fft_size[i] = 4'd2;  // 61.44, 2k
            default: fft_size[i] = 4'd1;  // 122.88, 4k
          endcase
        end
      end

    end
  endgenerate

  // Request buffer

  assign req_valid    = m_fram_data_req[24];
  assign req_startprb = m_fram_data_req[23:15];
  assign req_numprb   = m_fram_data_req[14:7];
  assign req_cc       = m_fram_data_req[3:0];

  assign req_data     = {req_startprb, req_numprb, req_cc};

  fifo_srl #(
      .FIFO_DEPTH(16),
      .DATA_WIDTH(21)
  ) u_req_fifo (
      // Common to write and read
      .clk  (clk_eth_xran),
      .rst  (rst_eth_xran),
      // Write interface
      .wren (req_valid),
      .din  (req_data),
      .full (fifo_full),
      // Read interface
      .rden (fifo_rden),
      .dout (fifo_dout),
      .empty(fifo_empty)
  );

  assign {fifo_req_startprb, fifo_req_numprb, fifo_req_cc} = fifo_dout;
  assign fifo_req_valid = ~fifo_empty;
  assign fifo_rden = fifo_req_ready;

  always_ff @(posedge clk_eth_xran) begin
    if (fifo_req_valid && fifo_req_ready) begin
      fifo_req_endprb <= (11'(fifo_req_numprb) + 11'(fifo_req_startprb)) * 11'd6 - 11'd1;
    end
  end

  // The buffer

  generate
    for (genvar cc = 0; cc < NUM_CC; cc++) begin : g_wr

      // Write

      always_ff @(posedge clk) begin
        if (din_sf[cc]) begin
          wr_bank[cc] <= 1'b0;
        end else if (din_sy[cc] && (din_chn[cc] == 0)) begin
          wr_bank[cc] <= ~wr_bank[cc];
        end
      end

      always_ff @(posedge clk) begin
        if (din_sy[cc]) begin
          wr_cnt[cc] <= 'd0;
        end else if (din_dv[cc] && (din_chn[cc] == 4'(ID))) begin
          wr_cnt[cc] <= wr_cnt[cc] + 12'(fft_size[cc]);
        end
      end

      // The incoming data is at bit-reversed order
      always_comb begin
        for (int i = 0; i < 12; i++) begin
          wr_cnt_rev[cc][i] = wr_cnt[cc][11-i];
        end
      end

      assign wr_addr[cc] = {wr_bank[cc], wr_cnt_rev[cc]};

      always_ff @(posedge clk) begin
        wr_we[cc] <= din_dv[cc] && (din_chn[cc] == 4'(ID));
      end

    end
  endgenerate

  // The buffer

  generate
    for (genvar cc = 0; cc < NUM_CC; cc++) begin : g_ram
      if (HALF_BLOCK != 0) begin : g_half

        logic [11:0] wr_addr_s;
        logic        wr_we_s;
        logic [31:0] wr_din_s;

        logic [10:0] rd_addr_s;
        logic        rd_en_s;
        logic        rd_en_s_d;

        assign wr_addr_s = {wr_addr[cc][12], wr_addr[cc][10:0]};
        assign wr_we_s   = wr_we[cc] && ~wr_addr[cc][11];

        always_ff @(posedge clk) begin
          wr_din_s <= {din_di[cc], din_dr[cc]};
        end

        assign rd_addr_s = {rd_addr[11], rd_addr[9:0]};
        assign rd_en_s   = rd_en[cc] && ~rd_addr[10];

        always_ff @(posedge clk_eth_xran) begin
          if (!out_stall) begin
            rd_en_s_d <= rd_en_s;
          end
        end

        assign rd_pipe_en[cc] = rd_en_s_d;

        // wr_addr: [12]: bank, [11]: null, [10:0]: address
        // rd_addr: [11]: bank, [10]: null, [9:0]: address

        // The ping-pong buffer, write side is 4096 x 32-bit
        // The read side is 2048 x 64-bit
        ram_sdp_asym #(
            .ADDR_WIDTH_A  (12),
            .DATA_WIDTH_A  (32),
            .ADDR_WIDTH_B  (11),
            .DATA_WIDTH_B  (64),
            .READ_LATENCY_B(2),
            .INIT_FILE     ("NONE")
        ) u_ram (
            .clka (clk),
            .wea  (wr_we_s),
            .addra(wr_addr_s),
            .dina (wr_din_s),
            //
            .clkb (clk_eth_xran),
            .rstb (1'b0),
            .enb  ({rd_en_s_d & ~out_stall, rd_en_s & ~out_stall}),
            .addrb(rd_addr_s),
            .doutb(rd_dout[cc])
        );

      end else begin : g_full

        logic [12:0] wr_comp_addr;
        logic        wr_comp_en;
        logic [17:0] wr_iq_din;
        logic [ 3:0] wr_exp_c;
        logic [ 3:0] wr_exp_din;
        logic [11:0] rd_comp_addr;
        logic [35:0] rd_iq_data;
        logic [ 7:0] rd_exp_data;
        logic [15:0] rd_i0;
        logic [15:0] rd_q0;
        logic [15:0] rd_i1;
        logic [15:0] rd_q1;

        assign rd_pipe_en[cc] = rd_en_d[cc];

        // The frequency converter places the occupied REs at the beginning of
        // natural FFT order. Discard the unused tail and place the two banks
        // in padded 3584-RE address ranges. The padding lets the read side use
        // a 1792-word bank stride while retaining the exact 3.5-BRAM layout.
        assign wr_comp_addr = (wr_bank[cc] ? 13'(FullNarrowBankDepth) : 13'd0) +
            13'(wr_cnt_rev[cc]);
        assign wr_comp_en = wr_we[cc] && (wr_cnt_rev[cc] < 12'(FullMaxRe));

        assign rd_comp_addr = (rd_bank ? 12'(FullIqBankDepth) : 12'd0) + 12'(rd_cnt);

        assign wr_exp_c = bfp9_re_exp(din_dr[cc], din_di[cc]);

        always_ff @(posedge clk) begin
          wr_exp_din <= wr_exp_c;
          wr_iq_din <= {
            bfp9_re_compress(din_di[cc], wr_exp_c), bfp9_re_compress(din_dr[cc], wr_exp_c)
          };
        end

        // IQ RAM: 7168 x 18-bit write, 3584 x 36-bit read. The segmented
        // wrapper maps this to three RAMB36 primitives and one RAMB18 tail.
        puxch_iq_ram #(
            .READ_LATENCY(2)
        ) u_iq_ram (
            .clka (clk),
            .wea  (wr_comp_en),
            .addra(wr_comp_addr),
            .dina (wr_iq_din),
            //
            .clkb (clk_eth_xran),
            .rstb (1'b0),
            .enb  ({rd_en_d[cc] & ~out_stall, rd_en[cc] & ~out_stall}),
            .addrb(rd_comp_addr),
            .doutb(rd_iq_data)
        );

        // One exponent belongs to each complex RE. The asymmetric read port
        // returns the two exponents corresponding to the 36-bit IQ word.
        ram_sdp_asym #(
            .ADDR_WIDTH_A  (13),
            .DATA_WIDTH_A  (4),
            .ADDR_WIDTH_B  (12),
            .DATA_WIDTH_B  (8),
            .READ_LATENCY_B(2),
            .DEPTH         (FullNarrowDepth),
            .INIT_FILE     ("NONE"),
            .RAM_STYLE     ("BLOCK")
        ) u_exp_ram (
            .clka (clk),
            .wea  (wr_comp_en),
            .addra(wr_comp_addr),
            .dina (wr_exp_din),
            //
            .clkb (clk_eth_xran),
            .rstb (1'b0),
            .enb  ({rd_en_d[cc] & ~out_stall, rd_en[cc] & ~out_stall}),
            .addrb(rd_comp_addr),
            .doutb(rd_exp_data)
        );

        always_comb begin
          rd_i0 = bfp9_re_decompress(rd_iq_data[8:0], rd_exp_data[3:0]);
          rd_q0 = bfp9_re_decompress(rd_iq_data[17:9], rd_exp_data[3:0]);
          rd_i1 = bfp9_re_decompress(rd_iq_data[26:18], rd_exp_data[7:4]);
          rd_q1 = bfp9_re_decompress(rd_iq_data[35:27], rd_exp_data[7:4]);
          rd_dout[cc] = {rd_q1, rd_i1, rd_q0, rd_i0};
        end

      end
    end
  endgenerate

  // Read

  generate
    for (genvar cc = 0; cc < NUM_CC; cc++) begin : g_rd

      always_ff @(posedge clk_eth_xran) begin
        if (rst_eth_xran) begin
          rd_en[cc] <= 1'b0;
        end else if (fifo_req_valid && fifo_req_ready && (fifo_req_cc == cc)) begin
          rd_en[cc] <= 1'b1;
        end else if (rd_issue && (&rd_cnt || (rd_cnt == fifo_req_endprb))) begin
          rd_en[cc] <= 1'b0;
        end
      end

      always_ff @(posedge clk_eth_xran) begin
        if (!out_stall) begin
          rd_en_d[cc]  <= rd_en[cc];
          rd_en_dd[cc] <= rd_en_d[cc];
        end
      end

    end
  endgenerate

  always_ff @(posedge clk_eth_xran) begin
    if (rst_eth_xran) begin
      rd_busy <= 1'b0;
    end else if (fifo_req_valid && fifo_req_ready && (fifo_req_cc < 4'(NUM_CC))) begin
      rd_busy <= 1'b1;
    end else if (rd_issue && (&rd_cnt || (rd_cnt == fifo_req_endprb))) begin
      rd_busy <= 1'b0;
    end
  end

  assign fifo_req_ready = ~rd_busy;

  generate
    if (HALF_BLOCK == 0) begin : g_full_request_guard
      assert property (@(posedge clk_eth_xran) disable iff (rst_eth_xran)
                       !(fifo_req_valid && fifo_req_ready) ||
                       (fifo_req_cc >= 4'(NUM_CC)) ||
                       ((fifo_req_numprb != 0) &&
                        (11'(fifo_req_startprb) + 11'(fifo_req_numprb) <= 11'(FullMaxPrb))))
      else $error("[%m]: full-block request exceeds the %0d-PRB buffer.", FullMaxPrb);
    end
  endgenerate

  // A read beat enters the RAM pipeline this cycle
  assign rd_issue = rd_busy && ~out_stall;

  // Use ORAN-IP counted symbol number as bank
  always_ff @(posedge clk_eth_xran) begin
    if (fifo_req_valid && fifo_req_ready) begin
      if (fifo_req_cc < 4'(NUM_CC)) begin
        rd_bank <= s_ul_sym_num[fifo_req_cc[CcIndexWidth-1:0]][0];
      end else begin
        rd_bank <= 1'b0;
      end
    end
  end

  always_ff @(posedge clk_eth_xran) begin
    if (fifo_req_valid && fifo_req_ready) begin
      rd_cnt <= fifo_req_startprb * 6;
    end else if (rd_issue) begin
      rd_cnt <= rd_cnt + 1'b1;
    end else if (!rd_busy) begin
      rd_cnt <= '0;
    end
  end

  assign rd_addr = {rd_bank, rd_cnt};

  always_comb begin
    rd_data_c = '0;
    for (int i = 0; i < NUM_CC; i++) begin
      rd_data_c = rd_data_c | (rd_en_dd[i] ? rd_dout[i] : 64'b0);
    end
  end

  assign rd_last = &rd_cnt || (rd_cnt == fifo_req_endprb);

  always_ff @(posedge clk_eth_xran) begin
    if (!out_stall) begin
      last_d1 <= rd_last;
      last_d2 <= last_d1;
    end
  end

  // Output

  assign s0_axis_tdata = {
    rd_data_c[55:48],  //  Q1[7:0]
    rd_data_c[63:56],  //  Q1[15:8]
    rd_data_c[39:32],  //  I1[7:0]
    rd_data_c[47:40],  //  I1[15:8]
    rd_data_c[23:16],  //  Q0[7:0]
    rd_data_c[31:24],  //  Q0[15:8]
    rd_data_c[7:0],  //  I0[7:0]
    rd_data_c[15:8]  //  I0[15:8]
  };

  // The readout implements backpressure by freezing the whole read pipeline
  // instead of buffering into a deep FIFO. ram_out_v is the write strobe
  // aligned with rd_data_c, 2 cycles after the RAM output register enable.
  // Note: backpressure longer than ~2 symbol boundaries lets the write side
  // overwrite the bank still being read (KNOWN_ISSUES.md, section 5).
  assign out_stall = (out_cnt >= 5'(OutFifoAlmostFull));

  assign out_wren = ram_out_v;
  assign out_rden = ~out_empty && s1_axis_tready;

  always_ff @(posedge clk_eth_xran) begin
    if (rst_eth_xran) begin
      ram_out_v <= 1'b0;
    end else begin
      ram_out_v <= (|rd_pipe_en) && ~out_stall;
    end
  end

  always_ff @(posedge clk_eth_xran) begin
    if (rst_eth_xran) begin
      out_cnt <= '0;
    end else begin
      out_cnt <= out_cnt + 5'(out_wren) - 5'(out_rden);
    end
  end

  fifo_srl #(
      .FIFO_DEPTH(OutFifoDepth),
      .DATA_WIDTH(65)
  ) u_out_fifo (
      .clk  (clk_eth_xran),
      .rst  (rst_eth_xran),
      // Write interface
      .wren (out_wren),
      .din  ({last_d2, s0_axis_tdata}),
      .full (out_full),
      // Read interface
      .rden (out_rden),
      .dout (out_dout),
      .empty(out_empty)
  );

  wire unused_out_fifo = &{1'b0, out_full};

  assign {s1_axis_tlast, s1_axis_tdata} = out_dout;
  assign s1_axis_tkeep = 8'hFF;
  assign s1_axis_tvalid = ~out_empty;

  // Add axis_reg to improve timing
  axis_reg #(
      .DATA_WIDTH(64),
      .USER_WIDTH(1)
  ) u_axis_reg (
      .aclk         (clk_eth_xran),
      .aresetn      (~rst_eth_xran),
      //
      .s_axis_tdata (s1_axis_tdata),
      .s_axis_tkeep (s1_axis_tkeep),
      .s_axis_tlast (s1_axis_tlast),
      .s_axis_tuser (1'b0),
      .s_axis_tvalid(s1_axis_tvalid),
      .s_axis_tready(s1_axis_tready),
      //
      .m_axis_tdata (m_axis_tdata),
      .m_axis_tkeep (m_axis_tkeep),
      .m_axis_tlast (m_axis_tlast),
      .m_axis_tuser (reg_m_axis_tuser),
      .m_axis_tvalid(m_axis_tvalid),
      .m_axis_tready(m_axis_tready)
  );

endmodule

`default_nettype wire
