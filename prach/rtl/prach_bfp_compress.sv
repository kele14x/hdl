`timescale 1 ns / 1 ps
//
`default_nettype none

module prach_bfp_compress #(
    parameter int NUM_ANT = 4
) (
    input var                clk,
    input var                rst,
    //
    input var  [       15:0] din_dr,
    input var  [       15:0] din_di,
    input var                din_dv,
    input var                din_sy,
    input var  [        1:0] din_chn,
    input var  [        3:0] ctrl_fs_offset,
    //
    output var [NUM_ANT-1:0] wr_we,
    output var [        8:0] wr_addr,
    output var [       35:0] wr_data,
    output var [NUM_ANT-1:0] exp_we,
    output var [        6:0] exp_addr,
    output var [        3:0] exp_wdata,
    output var [NUM_ANT-1:0] section_done
);

  initial begin : drc_check
    assert (1 <= NUM_ANT && NUM_ANT <= 4)
    else $error("[%m]: NUM_ANT (%0d) must be between 1 and 4.", NUM_ANT);
  end

  logic [31:0] capture_data      [2][12];
  logic        capture_active;
  logic        capture_bank;
  logic [ 3:0] capture_re_idx;
  logic [ 6:0] capture_prb_idx;
  logic [ 9:0] capture_count;
  logic [ 3:0] capture_max_msb;
  logic [ 1:0] capture_ant;
  logic        section_started;
  logic        section_done_seen;

  logic        process_valid;
  logic        process_bank;
  logic [ 2:0] process_word_idx;
  logic [ 6:0] process_prb_idx;
  logic [ 3:0] process_msb;
  logic [ 3:0] process_exp;
  logic [ 1:0] process_ant;

  logic [ 3:0] din_msb_i;
  logic [ 3:0] din_msb_q;
  logic [ 3:0] din_max_msb;
  logic [ 3:0] capture_next_msb;
  logic [ 3:0] process_shift;
  logic [15:0] process_i0;
  logic [15:0] process_q0;
  logic [15:0] process_i1;
  logic [15:0] process_q1;
  logic [15:0] shifted_i0_r;
  logic [15:0] shifted_q0_r;
  logic [15:0] shifted_i1_r;
  logic [15:0] shifted_q1_r;
  logic [15:0] rounded_i0;
  logic [15:0] rounded_q0;
  logic [15:0] rounded_i1;
  logic [15:0] rounded_q1;

  logic [NUM_ANT-1:0] wr_we_c;
  logic [        8:0] wr_addr_c;
  logic [NUM_ANT-1:0] exp_we_c;
  logic [        6:0] exp_addr_c;
  logic [        3:0] exp_wdata_c;
  logic [NUM_ANT-1:0] section_done_c;
  logic               process_valid_d;
  logic [        2:0] process_word_idx_d;
  logic [        6:0] process_prb_idx_d;
  logic [        3:0] process_msb_d;
  logic [        3:0] process_exp_d;
  logic [        1:0] process_ant_d;

  //
  // This function get MSB position of input data without the redundant
  // sign bits, for example:
  //   16'b01x_xxxxx -> 15
  //   16'b001_xxxxx -> 14
  //   16'b000000001 ->  1
  //   16'b000000000 ->  0
  //   16'b10_xxxxxx -> 15
  //   16'b110_xxxxx -> 14
  //   16'b1111110_x -> 10
  //   16'b111111110 ->  1
  //   16'b111111111 ->  0
  //
  function automatic logic [3:0] msb_position(input logic [15:0] din);
    for (int i = 15; i > 0; i--) begin
      if (din[i] ^ din[i-1]) return i[3:0];
    end
    return 0;
  endfunction

  //
  // This function get shift value based on the MSB position, since the input
  // data width is 16-bit, we can limit the shift value to [0, 16 - UD_IQ_WIDTH]
  //
  function automatic logic [3:0] get_shift(input logic [3:0] msb);
    get_shift = 15 - msb;
    get_shift = get_shift >= 7 ? 7 : get_shift;
  endfunction

  //
  // This function get the exp value based on the MSB position
  // Be care that FS_OFFSET too large could cause underflow and can't be proper
  // handled. For example, it's safe to set FS_OFFSET to [0 ~ 8] for BFP9, and
  // set it to 9 may cause the exponent underflow
  //
  function automatic logic [3:0] get_exp(input logic [3:0] msb, input logic [3:0] fs_offset);
    get_exp = 15 - get_shift(msb);
    get_exp = get_exp >= fs_offset ? get_exp - fs_offset : 0;
  endfunction

  //
  // This function performs rounding on an already-shifted 16-bit sample:
  // force the six low bits to 1, then add 1, keeping 0x7FFF unchanged so the
  // rounded result does not wrap into the negative range.
  //
  function automatic logic [15:0] round_sample(input logic [15:0] din);
    logic [15:0] rounded;
    rounded = din | 16'h003F;
    if (rounded == 16'h7FFF) begin
      round_sample = rounded;
    end else begin
      round_sample = rounded + 1'b1;
    end
  endfunction

  always_comb begin
    din_msb_i = msb_position(din_dr);
    din_msb_q = msb_position(din_di);
    din_max_msb = din_msb_i >= din_msb_q ? din_msb_i : din_msb_q;
    capture_next_msb = capture_max_msb >= din_max_msb ? capture_max_msb : din_max_msb;
  end

  always_comb begin
    process_shift = get_shift(process_msb);
    process_i0 = capture_data[process_bank][2*process_word_idx][31:16];
    process_q0 = capture_data[process_bank][2*process_word_idx][15:0];
    process_i1 = capture_data[process_bank][2*process_word_idx+1][31:16];
    process_q1 = capture_data[process_bank][2*process_word_idx+1][15:0];
  end

  // Pipeline stage 1: variable barrel shift. The process-control snapshot is
  // registered in lockstep with the shifted samples, so the write address,
  // enables and shifted data all come from the same cycle. This splits the
  // shift+round chain that was the critical timing path to the RAM write port
  // (shift is limited to [0, 7] by get_shift, so no truncation).
  always_ff @(posedge clk) begin
    if (rst) begin
      shifted_i0_r <= '0;
      shifted_q0_r <= '0;
      shifted_i1_r <= '0;
      shifted_q1_r <= '0;
      process_valid_d    <= 1'b0;
      process_word_idx_d <= '0;
      process_prb_idx_d  <= '0;
      process_msb_d      <= '0;
      process_exp_d      <= '0;
      process_ant_d      <= '0;
    end else begin
      shifted_i0_r <= process_i0 << process_shift;
      shifted_q0_r <= process_q0 << process_shift;
      shifted_i1_r <= process_i1 << process_shift;
      shifted_q1_r <= process_q1 << process_shift;
      process_valid_d    <= process_valid;
      process_word_idx_d <= process_word_idx;
      process_prb_idx_d  <= process_prb_idx;
      process_msb_d      <= process_msb;
      process_exp_d      <= process_exp;
      process_ant_d      <= process_ant;
    end
  end

  always_comb begin
    rounded_i0 = round_sample(shifted_i0_r);
    rounded_q0 = round_sample(shifted_q0_r);
    rounded_i1 = round_sample(shifted_i1_r);
    rounded_q1 = round_sample(shifted_q1_r);
  end

  // Pipeline stage 2: register the assembled write word one cycle after the
  // control snapshot, so data reaches the RAM write port with the same
  // alignment as we/addr. The uniform shift keeps RAM contents unchanged.
  always_ff @(posedge clk) begin
    if (rst) begin
      wr_data <= '0;
    end else begin
      wr_data <= {rounded_i0[15:7], rounded_q0[15:7], rounded_i1[15:7], rounded_q1[15:7]};
    end
  end

  always_comb begin
    wr_we_c = '0;
    exp_we_c = '0;
    section_done_c = '0;
    wr_addr_c = 9'(process_prb_idx_d * 6 + process_word_idx_d);
    exp_addr_c = process_prb_idx_d;
    exp_wdata_c = process_exp_d;

    if (process_valid_d) begin
      for (int ant = 0; ant < NUM_ANT; ant++) begin
        if (process_ant_d == 2'(ant)) begin
          wr_we_c[ant] = 1'b1;
          if (process_word_idx_d == 0) begin
            exp_we_c[ant] = 1'b1;
          end
          if ((process_prb_idx_d == 71) && (process_word_idx_d == 5)) begin
            section_done_c[ant] = 1'b1;
          end
        end
      end
    end
  end

  // Pipeline stage 3: register the write interface so the rounding and
  // word-assembly logic feeds a register instead of the RAM write ports. All
  // outputs are taken from the same delayed control snapshot, so the write
  // timing shift applies uniformly and RAM contents stay unchanged.
  always_ff @(posedge clk) begin
    if (rst) begin
      wr_we        <= '0;
      wr_addr      <= '0;
      exp_we       <= '0;
      exp_addr     <= '0;
      exp_wdata    <= '0;
      section_done <= '0;
    end else begin
      wr_we        <= wr_we_c;
      wr_addr      <= wr_addr_c;
      exp_we       <= exp_we_c;
      exp_addr     <= exp_addr_c;
      exp_wdata    <= exp_wdata_c;
      section_done <= section_done_c;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      capture_active    <= 1'b0;
      capture_bank      <= 1'b0;
      capture_re_idx    <= '0;
      capture_prb_idx   <= '0;
      capture_count     <= '0;
      capture_max_msb   <= '0;
      capture_ant       <= '0;
      section_started   <= 1'b0;
      section_done_seen <= 1'b0;
      process_valid     <= 1'b0;
      process_bank      <= 1'b0;
      process_word_idx  <= '0;
      process_prb_idx   <= '0;
      process_msb       <= '0;
      process_exp       <= '0;
      process_ant       <= '0;
    end else begin
      if (process_valid) begin
        if (process_word_idx == 5) begin
          process_valid <= 1'b0;
        end else begin
          process_word_idx <= process_word_idx + 1'b1;
        end
      end

      if (|section_done) begin
        section_done_seen <= 1'b1;
      end

      if (din_sy && din_dv) begin
        capture_data[0][0] <= {din_dr, din_di};
        capture_active     <= 1'b1;
        capture_bank       <= 1'b0;
        capture_re_idx     <= 1;
        capture_prb_idx    <= '0;
        capture_count      <= 1;
        capture_max_msb    <= din_max_msb;
        capture_ant        <= din_chn;
        section_started    <= 1'b1;
        section_done_seen  <= 1'b0;
        process_valid      <= 1'b0;
        process_word_idx   <= '0;
      end else if (capture_active && din_dv) begin
        capture_data[capture_bank][capture_re_idx] <= {din_dr, din_di};
        capture_count <= capture_count + 1'b1;

        if (capture_re_idx == 11) begin
          process_valid    <= 1'b1;
          process_bank     <= capture_bank;
          process_word_idx <= '0;
          process_prb_idx  <= capture_prb_idx;
          process_msb      <= capture_next_msb;
          process_exp      <= get_exp(capture_next_msb, ctrl_fs_offset);
          process_ant      <= capture_ant;

          capture_bank     <= ~capture_bank;
          capture_re_idx   <= '0;
          capture_max_msb  <= '0;
          if (capture_prb_idx == 71) begin
            capture_active <= 1'b0;
          end else begin
            capture_prb_idx <= capture_prb_idx + 1'b1;
          end
        end else begin
          capture_re_idx  <= capture_re_idx + 1'b1;
          capture_max_msb <= capture_next_msb;
        end
      end

`ifndef SYNTHESIS
      if (din_sy && din_dv) begin
        assert (int'(din_chn) < NUM_ANT)
        else $error("[%m]: din_chn %0d is outside NUM_ANT %0d.", din_chn, NUM_ANT);
        if (section_started) begin
          assert (capture_count == 864)
          else $error("[%m]: previous section captured %0d RE instead of 864.", capture_count);
          assert (section_done_seen)
          else $error("[%m]: previous section did not produce section_done.");
        end
      end
      if (capture_active && din_dv && !(din_sy && din_dv)) begin
        assert (din_chn == capture_ant)
        else
          $error("[%m]: din_chn changed from %0d to %0d during a section.", capture_ant, din_chn);
        assert (!(process_valid && (process_bank == capture_bank)))
        else $error("[%m]: capture attempted to overwrite the active process bank.");
        assert (capture_count < 864)
        else $error("[%m]: capture count exceeded 864 RE.");
        if (capture_re_idx == 11) begin
          assert ((capture_count % 12) == 11)
          else $error("[%m]: PRB boundary did not contain exactly 12 RE.");
          assert (!process_valid)
          else $error("[%m]: process engine was still busy at a PRB boundary.");
        end
      end
      if (process_valid) begin
        assert (wr_addr <= 431)
        else $error("[%m]: data RAM address %0d is out of range.", wr_addr);
        assert (exp_addr <= 71)
        else $error("[%m]: exponent RAM address %0d is out of range.", exp_addr);
      end
      if (|section_done) begin
        assert (!section_done_seen)
        else $error("[%m]: section_done occurred more than once in a section.");
        assert (capture_count == 864)
        else $error("[%m]: section_done occurred after capturing %0d RE.", capture_count);
        assert (wr_addr == 431)
        else $error("[%m]: section_done occurred at data address %0d.", wr_addr);
      end
`endif
    end
  end

  wire unused_bfp_compress = &{
    1'b0, rounded_i0[6:0], rounded_q0[6:0], rounded_i1[6:0], rounded_q1[6:0]
  };

endmodule

`default_nettype wire
