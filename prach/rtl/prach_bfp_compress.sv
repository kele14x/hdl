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
  logic [15:0] rounded_i0;
  logic [15:0] rounded_q0;
  logic [15:0] rounded_i1;
  logic [15:0] rounded_q1;

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
  // This function perform shift and rounding (compress) process
  //
  function automatic logic [15:0] shift_and_round(input logic [15:0] din, input logic [3:0] shift,
                                                  input logic en);
    if (en) begin
      shift_and_round = din << shift;
      shift_and_round = shift_and_round | 16'h003F;
      if (shift_and_round == 16'h7FFF) begin
        shift_and_round = shift_and_round;
      end else begin
        shift_and_round = (shift_and_round + 1'b1);
      end
    end else begin
      shift_and_round = din;
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
    rounded_i0 = shift_and_round(process_i0, process_shift, 1'b1);
    rounded_q0 = shift_and_round(process_q0, process_shift, 1'b1);
    rounded_i1 = shift_and_round(process_i1, process_shift, 1'b1);
    rounded_q1 = shift_and_round(process_q1, process_shift, 1'b1);
  end

  always_comb begin
    wr_we = '0;
    exp_we = '0;
    section_done = '0;
    wr_addr = 9'(process_prb_idx * 6 + process_word_idx);
    wr_data = {rounded_i0[15:7], rounded_q0[15:7], rounded_i1[15:7], rounded_q1[15:7]};
    exp_addr = process_prb_idx;
    exp_wdata = process_exp;

    if (process_valid) begin
      for (int ant = 0; ant < NUM_ANT; ant++) begin
        if (process_ant == 2'(ant)) begin
          wr_we[ant] = 1'b1;
          if (process_word_idx == 0) begin
            exp_we[ant] = 1'b1;
          end
          if ((process_prb_idx == 71) && (process_word_idx == 5)) begin
            section_done[ant] = 1'b1;
          end
        end
      end
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
