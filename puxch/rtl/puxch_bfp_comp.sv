`timescale 1 ns / 1 ps
//
`default_nettype none

// Merge per-RE BFP9 values from puxch_buffer into one shared-exponent BFP9
// block per PRB. The input carries two REs per beat:
//   [43:40] exp1, [39:36] exp0, [35:27] Q1, [26:18] I1,
//   [17:9] Q0, [8:0] I0.
// Output compression is mandatory; the legacy method and IQ-width controls
// remain in the interface only for register-map compatibility.
module puxch_bfp_comp #(
    parameter int BYTE_REVERSE = 1,
    parameter int USER_WIDTH   = 32
) (
    input var                   clk,
    input var                   rst,
    //
    input var  [          63:0] s_axis_tdata,
    input var  [           7:0] s_axis_tkeep,
    input var                   s_axis_tvalid,
    input var                   s_axis_tlast,
    input var  [USER_WIDTH-1:0] s_axis_tuser,
    //
    output var [          63:0] m_axis_tdata,
    output var [           7:0] m_axis_tkeep,
    output var                  m_axis_tvalid,
    output var                  m_axis_tlast,
    output var [USER_WIDTH-1:0] m_axis_tuser,
    // Control
    input var  [           3:0] ctrl_ud_comp_meth,
    input var  [           3:0] ctrl_ud_iq_width,
    input var  [           3:0] ctrl_fs_offset
);

  logic [3:0] ctrl_fs_offset_s;

  logic [2:0] input_state;
  logic [3:0] input_max_exp;
  logic [35:0] iq_cache[6];
  logic [7:0] exp_cache[6];
  logic [USER_WIDTH-1:0] input_user;

  logic replay_active;
  logic [2:0] replay_state;
  logic [3:0] replay_exp;
  logic [USER_WIDTH-1:0] replay_user;
  logic replay_last;

  logic [35:0] t5_data_b;
  logic [2:0] t5_state;
  logic [3:0] t5_exp;
  logic [USER_WIDTH-1:0] t5_user;
  logic t5_sop;
  logic t5_valid;
  logic t5_eop;

  logic [3:0] t6_cnt;
  logic [63:0] t6_data;
  logic [63:0] t6_data_f;
  logic [7:0] t6_keep;
  logic [USER_WIDTH-1:0] t6_user;
  logic t6_valid;
  logic t6_eop;
  logic t6_eop_ext;
  logic [63:0] t6_eop_data;
  logic [USER_WIDTH-1:0] t6_eop_user;
  logic t6_eop_ext_out;

  wire [3:0] input_pair_exp = (s_axis_tdata[39:36] >= s_axis_tdata[43:40]) ?
      s_axis_tdata[39:36] : s_axis_tdata[43:40];
  wire [3:0] completed_exp = (input_state == 0 || input_pair_exp >= input_max_exp) ?
      input_pair_exp : input_max_exp;
  wire input_prb_complete = s_axis_tvalid && (input_state == 5);
  wire [35:0] unused_legacy_control = {
    s_axis_tdata[63:44], s_axis_tkeep, ctrl_ud_comp_meth, ctrl_ud_iq_width
  };

  initial begin : drc_check
    assert (USER_WIDTH >= 1)
    else $error("[%m]: USER_WIDTH (%0d) must be at least 1.", USER_WIDTH);
  end

  assert property (@(posedge clk) disable iff (rst)
                   s_axis_tvalid |->
                   (s_axis_tdata[39:36] >= 4'd8 && s_axis_tdata[43:40] >= 4'd8))
  else $error("[%m]: input exponent is outside the internal BFP9 range.");

  assert property (@(posedge clk) disable iff (rst)
                   !(s_axis_tvalid && s_axis_tlast) || (input_state == 5))
  else $error("[%m]: input packet must end on a complete PRB.");

  function automatic logic [63:0] byte_reverse(input logic [63:0] din);
    for (int i = 0; i < 8; i++) begin
      byte_reverse[63-8*i-:8] = din[8*i+7-:8];
    end
  endfunction

  // Align a stored per-RE mantissa to the largest exponent in the PRB. This
  // is bit-exact with decompressing to 16 bits and applying BFP9 again, but
  // avoids both wide operations. Stored exponents differ by at most 7.
  function automatic logic [8:0] align_mantissa(
      input logic [8:0] mantissa, input logic [3:0] source_exp, input logic [3:0] target_exp);
    logic [3:0] shift;
    logic signed [10:0] value;

    shift = target_exp - source_exp;
    value = {{2{mantissa[8]}}, mantissa};
    if (shift != 0) begin
      value = value + (11'sd1 <<< (shift - 1'b1));
      value = value >>> shift;
    end
    align_mantissa = value[8:0];
  endfunction

  function automatic logic [35:0] align_pair(input logic [35:0] iq, input logic [7:0] exp,
                                             input logic [3:0] target_exp);
    align_pair = {
      align_mantissa(iq[8:0], exp[3:0], target_exp),
      align_mantissa(iq[17:9], exp[3:0], target_exp),
      align_mantissa(iq[26:18], exp[7:4], target_exp),
      align_mantissa(iq[35:27], exp[7:4], target_exp)
    };
  endfunction

  function automatic logic [3:0] apply_fs_offset(input logic [3:0] exp,
                                                 input logic [3:0] fs_offset);
    apply_fs_offset = (exp >= fs_offset) ? exp - fs_offset : 4'd0;
  endfunction

  cdc_array_single #(
      .DEST_SYNC_FF (2),
      .INIT_SYNC_FF (0),
      .SRC_INPUT_REG(0),
      .WIDTH        (4)
  ) i_cdc_fs_offset (
      .src_clk (1'b1),
      .src_in  (ctrl_fs_offset),
      .dest_clk(clk),
      .dest_out(ctrl_fs_offset_s)
  );

  // Cache one PRB while the preceding PRB is replayed. On a continuous
  // stream, the read and write indices are identical; nonblocking assignment
  // semantics preserve the old PRB for replay on that edge.
  always_ff @(posedge clk) begin
    if (s_axis_tvalid) begin
      iq_cache[input_state]  <= s_axis_tdata[35:0];
      exp_cache[input_state] <= s_axis_tdata[43:36];

      if (input_state == 0) begin
        input_max_exp <= input_pair_exp;
        input_user <= s_axis_tuser;
      end else if (input_pair_exp > input_max_exp) begin
        input_max_exp <= input_pair_exp;
      end
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      input_state <= '0;
    end else if (s_axis_tvalid) begin
      input_state <= (input_state == 5 || s_axis_tlast) ? '0 : input_state + 1'b1;
    end
  end

  // Replay scheduler and direct exponent merge.
  always_ff @(posedge clk) begin
    if (rst) begin
      replay_active <= 1'b0;
      replay_state  <= '0;
      replay_exp    <= '0;
      replay_user   <= '0;
      replay_last   <= 1'b0;
      t5_data_b     <= '0;
      t5_state      <= '0;
      t5_exp        <= '0;
      t5_user       <= '0;
      t5_sop        <= 1'b0;
      t5_valid      <= 1'b0;
      t5_eop        <= 1'b0;
    end else begin
      t5_valid <= replay_active;
      t5_eop   <= replay_active && replay_last && (replay_state == 5);
      t5_sop   <= replay_active && (replay_state == 0);

      if (replay_active) begin
        t5_data_b <= align_pair(iq_cache[replay_state], exp_cache[replay_state], replay_exp);
        t5_state <= replay_state;
        t5_exp <= apply_fs_offset(replay_exp, ctrl_fs_offset_s);
        t5_user <= replay_user;
      end

      if (replay_active && (replay_state != 5)) begin
        replay_state <= replay_state + 1'b1;
      end else if (input_prb_complete) begin
        replay_active <= 1'b1;
        replay_state  <= '0;
        replay_exp    <= completed_exp;
        replay_user   <= input_user;
        replay_last   <= s_axis_tlast;
      end else if (replay_active) begin
        replay_active <= 1'b0;
        replay_state  <= '0;
      end
    end
  end

  // 36-bit mantissa payload plus a 4-bit exponent is packed into the eCPRI
  // byte stream. Two PRBs occupy seven 64-bit words; an odd final PRB emits a
  // four-byte tail.
  always_ff @(posedge clk) begin
    if (rst) begin
      t6_cnt <= '0;
    end else if (t5_valid && t5_eop) begin
      t6_cnt <= '0;
    end else if (t5_valid) begin
      t6_cnt <= (t6_cnt == 11) ? '0 : t6_cnt + 1'b1;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      t6_user <= '0;
    end else if (t5_valid && t5_sop && (t5_state == 0)) begin
      t6_user <= t5_user;
    end
  end

  always_ff @(posedge clk) begin
    t6_eop_ext <= t5_valid && t5_eop && (t6_cnt == 5);
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      t6_eop_data    <= '0;
      t6_eop_user    <= '0;
      t6_eop_ext_out <= 1'b0;
    end else begin
      t6_eop_ext_out <= t6_eop_ext;
      if (t6_eop_ext) begin
        t6_eop_data <= {t6_data_f[63:32], 32'b0};
        t6_eop_user <= t6_user;
      end
    end
  end

  always_ff @(posedge clk) begin
    if (t5_valid) begin
      case (t6_cnt)
        0:       t6_data[63:20] <= {4'b0, t5_exp, t5_data_b};
        1:       t6_data[19:0] <= t5_data_b[35:16];
        2:       t6_data[63:12] <= {t6_data_f[63:48], t5_data_b};
        3:       t6_data[11:0] <= t5_data_b[35:24];
        4:       t6_data[63:4] <= {t6_data_f[63:40], t5_data_b};
        5:       t6_data[3:0] <= t5_data_b[35:32];
        6:       t6_data <= {t6_data_f[63:32], 4'b0, t5_exp, t5_data_b[35:12]};
        7:       t6_data[63:16] <= {t6_data_f[63:52], t5_data_b};
        8:       t6_data[15:0] <= t5_data_b[35:20];
        9:       t6_data[63:8] <= {t6_data_f[63:44], t5_data_b};
        10:      t6_data[7:0] <= t5_data_b[35:28];
        11:      t6_data <= {t6_data_f[63:36], t5_data_b};
        default: t6_data <= t6_data;
      endcase
    end
  end

  always_ff @(posedge clk) begin
    if (t5_valid) begin
      case (t6_cnt)
        1:       t6_data_f[63:48] <= t5_data_b[15:0];
        3:       t6_data_f[63:40] <= t5_data_b[23:0];
        5:       t6_data_f[63:32] <= t5_data_b[31:0];
        6:       t6_data_f[63:52] <= t5_data_b[11:0];
        8:       t6_data_f[63:44] <= t5_data_b[19:0];
        10:      t6_data_f[63:36] <= t5_data_b[27:0];
        default: t6_data_f <= t6_data_f;
      endcase
    end
  end

  always_ff @(posedge clk) begin
    t6_keep <= t6_eop_ext ? 8'h0F : 8'hFF;
    t6_valid <= (t5_valid && t5_eop && (t6_cnt != 5)) ||
        (t5_valid && (t6_cnt == 1 || t6_cnt == 3 || t6_cnt == 5 || t6_cnt == 6 ||
                     t6_cnt == 8 || t6_cnt == 10 || t6_cnt == 11));
    t6_eop <= t5_valid && t5_eop && (t6_cnt != 5);
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      m_axis_tdata  <= '0;
      m_axis_tkeep  <= '0;
      m_axis_tlast  <= 1'b0;
      m_axis_tuser  <= '0;
      m_axis_tvalid <= 1'b0;
    end else if (t6_eop_ext_out) begin
      m_axis_tdata  <= (BYTE_REVERSE != 0) ? byte_reverse(t6_eop_data) : t6_eop_data;
      m_axis_tkeep  <= 8'h0F;
      m_axis_tlast  <= 1'b1;
      m_axis_tuser  <= t6_eop_user;
      m_axis_tvalid <= 1'b1;
    end else if (t6_valid) begin
      m_axis_tdata  <= (BYTE_REVERSE != 0) ? byte_reverse(t6_data) : t6_data;
      m_axis_tkeep  <= t6_keep;
      m_axis_tlast  <= t6_eop;
      m_axis_tuser  <= t6_user;
      m_axis_tvalid <= 1'b1;
    end else begin
      m_axis_tvalid <= 1'b0;
    end
  end

  wire unused_ok = &{1'b0, unused_legacy_control};

endmodule

`default_nettype wire
