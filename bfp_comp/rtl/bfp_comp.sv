`timescale 1 ns / 1 ps
//
`default_nettype none

module bfp_comp #(
    parameter bit BYTE_REVERSE = 1'b1,
    parameter int USER_WIDTH   = 32
) (
    input  wire                  clk,
    input  wire                  rst,
    //
    input  wire [          63:0] s_axis_tdata,
    input  wire [           7:0] s_axis_tkeep,
    input  wire                  s_axis_tvalid,
    input  wire                  s_axis_tlast,
    input  wire [USER_WIDTH-1:0] s_axis_tuser,
    //
    output reg  [          63:0] m_axis_tdata,
    output reg  [           7:0] m_axis_tkeep,
    output reg                   m_axis_tvalid,
    output reg                   m_axis_tlast,
    output reg  [USER_WIDTH-1:0] m_axis_tuser,
    // Control
    //--------
    input  wire [           3:0] ctrl_ud_comp_meth,
    input  wire [           3:0] ctrl_ud_iq_width,
    input  wire [           3:0] ctrl_fs_offset
);

  // Parameters
  //===========

  localparam int NumIq = 4;

  initial begin : drc_check
    assert (USER_WIDTH >= 1)
    else $error("[%m]: USER_WIDTH (%0d) must be at least 1.", USER_WIDTH);
  end

  // Signals
  //========

  logic [           3:0] ctrl_ud_comp_meth_s;
  logic [           3:0] ctrl_ud_iq_width_s;
  logic [           3:0] ctrl_fs_offset_s;
  logic                  ctrl_en_s;

  logic [          63:0] s_axis_tdata_rev;

  logic [          15:0] t0_data             [  NumIq];
  logic [           2:0] t0_state_pre;
  logic [           2:0] t0_state;
  logic [USER_WIDTH-1:0] t0_user;
  logic                  t0_sop;
  logic                  t0_valid;
  logic                  t0_eop;

  logic [          15:0] t1_data             [  NumIq];
  logic [           2:0] t1_state;
  logic [           3:0] t1_msb              [  NumIq];
  logic [USER_WIDTH-1:0] t1_user;
  logic                  t1_sop;
  logic                  t1_valid;
  logic                  t1_eop;

  logic [          15:0] t2_data             [  NumIq];
  logic [           2:0] t2_state;
  logic [           3:0] t2_msb;
  logic [USER_WIDTH-1:0] t2_user;
  logic                  t2_sop;
  logic                  t2_prb_valid;
  logic                  t2_valid;
  logic                  t2_eop;

  logic [          15:0] t3_data             [NumIq*6];
  logic [           2:0] t3_state;
  logic [           3:0] t3_msb;
  logic [USER_WIDTH-1:0] t3_user;
  logic                  t3_sop_req;
  logic                  t3_sop;
  logic                  t3_valid;
  logic                  t3_eop_req;
  logic                  t3_eop;

  logic [          15:0] t4_data             [  NumIq];
  logic [           2:0] t4_state;
  logic [           3:0] t4_shift;
  logic [           3:0] t4_exp;
  logic [USER_WIDTH-1:0] t4_user;
  logic                  t4_sop;
  logic                  t4_valid;
  logic                  t4_eop;

  logic [          15:0] t5_data             [  NumIq];
  logic [          35:0] t5_data_b;
  logic [           2:0] t5_state;
  logic [           3:0] t5_exp;
  logic [USER_WIDTH-1:0] t5_user;
  logic                  t5_sop;
  logic                  t5_valid;
  logic                  t5_eop;

  logic [           3:0] t6_cnt;

  logic [          63:0] t6_data;
  logic [          63:0] t6_data_f;
  logic [           7:0] t6_keep;
  logic [USER_WIDTH-1:0] t6_user;
  logic                  t6_valid;
  logic                  t6_eop;
  logic                  t6_eop_ext;
  logic [          63:0] t6_eop_data;
  logic [USER_WIDTH-1:0] t6_eop_user;
  logic                  t6_eop_ext_out;

  // Helpers
  //========

  //
  // This function does byte reverse for Stream data signal
  //
  function automatic logic [63:0] byte_reverse(input logic [63:0] din);
    for (int i = 0; i < 8; i++) begin
      byte_reverse[63-8*i-:8] = din[8*i+7-:8];
    end
  endfunction

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
  // This function get the max value out of 5
  //
  function automatic logic [3:0] max_of_5(input logic [3:0] data[5]);
    max_of_5 = 0;
    for (int i = 0; i < 5; i++) begin
      max_of_5 = max_of_5 >= data[i] ? max_of_5 : data[i];
    end
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

  // Main
  //=====

  // CDC for control signals
  //=======================

  cdc_array_single #(
      .DEST_SYNC_FF (2),
      .INIT_SYNC_FF (1'b0),
      .SRC_INPUT_REG(1'b0),
      .WIDTH        (4)
  ) i_cdc_ud_comp_meth (
      .src_clk (1'b1),
      .src_in  (ctrl_ud_comp_meth),
      .dest_clk(clk),
      .dest_out(ctrl_ud_comp_meth_s)
  );

  cdc_array_single #(
      .DEST_SYNC_FF (2),
      .INIT_SYNC_FF (1'b0),
      .SRC_INPUT_REG(1'b0),
      .WIDTH        (4)
  ) i_cdc_ud_iq_width (
      .src_clk (1'b1),
      .src_in  (ctrl_ud_iq_width),
      .dest_clk(clk),
      .dest_out(ctrl_ud_iq_width_s)
  );

  cdc_array_single #(
      .DEST_SYNC_FF (2),
      .INIT_SYNC_FF (1'b0),
      .SRC_INPUT_REG(1'b0),
      .WIDTH        (4)
  ) i_cdc_fs_offset (
      .src_clk (1'b1),
      .src_in  (ctrl_fs_offset),
      .dest_clk(clk),
      .dest_out(ctrl_fs_offset_s)
  );

  // CompMeth = 1 => BFP compression
  assign ctrl_en_s = (ctrl_ud_comp_meth_s == 1) | ((|ctrl_ud_iq_width_s) & 1'b0);

  // r0:
  //----
  // Input register, and counter for 1 RB (6 tick input)

  assign s_axis_tdata_rev = (BYTE_REVERSE ? byte_reverse(s_axis_tdata) : s_axis_tdata) ^ {64{|s_axis_tkeep & 1'b0}};

  always_ff @(posedge clk) begin
    for (int i = 0; i < NumIq; i++) begin
      if (s_axis_tvalid) begin
        t0_data[i] <= s_axis_tdata_rev[63-i*16-:16];  // [0:3] = I0, Q0, I1, Q1
      end
    end
  end

  always_ff @(posedge clk) begin
    if (s_axis_tvalid) begin
      t0_user <= s_axis_tuser;
      t0_sop  <= (t0_state_pre == 0);
    end
  end

  // This state machine has 0/1/2/3/4/5
  always_ff @(posedge clk) begin
    if (rst) begin
      t0_state_pre <= '0;
    end else if (s_axis_tvalid && s_axis_tlast) begin
      t0_state_pre <= '0;
    end else if (s_axis_tvalid) begin
      t0_state_pre <= (t0_state_pre == 5) ? 0 : t0_state_pre + 1'b1;
    end
  end

  always_ff @(posedge clk) begin
    t0_state <= t0_state_pre;
    t0_valid <= s_axis_tvalid;
    t0_eop   <= s_axis_tlast;
  end

  // r1:
  //----
  // Get msb position of each IQ

  always_ff @(posedge clk) begin
    for (int i = 0; i < NumIq; i++) begin
      t1_msb[i] <= msb_position(t0_data[i]);
    end
  end

  always_ff @(posedge clk) begin
    t1_data  <= t0_data;
    t1_state <= t0_state;
    t1_user  <= t0_user;
    t1_sop   <= t0_sop;
    t1_valid <= t0_valid;
    t1_eop   <= t0_eop;
  end

  // r2:
  //----
  // Get max msb position of 6 state (1 RB)

  always_ff @(posedge clk) begin
    if (t1_valid) begin
      if (t1_state == 0) begin
        t2_msb <= max_of_5('{0, t1_msb[0], t1_msb[1], t1_msb[2], t1_msb[3]});
      end else begin
        t2_msb <= max_of_5('{t2_msb, t1_msb[0], t1_msb[1], t1_msb[2], t1_msb[3]});
      end
    end
  end

  assign t2_prb_valid = t2_valid && (t2_state == 5);

  always_ff @(posedge clk) begin
    t2_data  <= t1_data;
    t2_state <= t1_state;
    t2_user  <= t1_user;
    t2_sop   <= t1_sop;
    t2_valid <= t1_valid;
    t2_eop   <= t1_eop;
  end

  // r3:
  //----
  // Cache data incase the data is not continues at previous stage
  // S -> P

  generate
    for (genvar i = 0; i < 6; i++) begin : g_t3_data

      always_ff @(posedge clk) begin
        if (t2_valid && (t2_state == i)) begin
          t3_data[4*i+:4] <= t2_data;
        end
      end

    end
  endgenerate

  always_ff @(posedge clk) begin
    if (rst) begin
      t3_state <= '0;
    end else if (t2_prb_valid) begin
      t3_state <= '0;
    end else if (t3_valid) begin
      t3_state <= (t3_state == 5) ? 0 : (t3_state + 1'b1);
    end
  end

  always_ff @(posedge clk) begin
    if (t2_prb_valid) begin
      t3_msb <= t2_msb;
    end
  end

  always_ff @(posedge clk) begin
    if (t2_valid && t2_sop) begin
      t3_user <= t2_user;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      t3_sop_req <= 1'b0;
    end else if (t2_valid && t2_sop) begin
      t3_sop_req <= 1'b1;
    end else if (t2_prb_valid) begin
      t3_sop_req <= 1'b0;
    end
  end

  always_ff @(posedge clk) begin
    if (t2_prb_valid) begin
      t3_sop <= t3_sop_req;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      t3_valid <= 1'b0;
    end else if (t2_prb_valid) begin
      t3_valid <= 1'b1;
    end else if (t3_state == 5) begin
      t3_valid <= 1'b0;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      t3_eop_req <= 1'b0;
    end else if (t2_valid && t2_eop) begin
      t3_eop_req <= 1'b1;
    end else if (t3_eop) begin
      t3_eop_req <= 1'b0;
    end
  end

  always_ff @(posedge clk) begin
    t3_eop <= t3_eop_req && (t3_state == 4);
  end

  // r4:
  //----
  // Cacl shift and exponent
  // P -> S

  always_ff @(posedge clk) begin
    for (int i = 0; i < 4; i++) begin
      if (t3_state == 0) begin
        t4_data[i] <= t3_data[i];
      end else if (t3_state == 1) begin
        t4_data[i] <= t3_data[4+i];
      end else if (t3_state == 2) begin
        t4_data[i] <= t3_data[8+i];
      end else if (t3_state == 3) begin
        t4_data[i] <= t3_data[12+i];
      end else if (t3_state == 4) begin
        t4_data[i] <= t3_data[16+i];
      end else begin
        t4_data[i] <= t3_data[20+i];
      end
    end
  end

  always_ff @(posedge clk) begin
    // The shift value is based on the data, does not depend on FS Offset
    t4_shift <= get_shift(t3_msb);
  end

  always_ff @(posedge clk) begin
    // However, the reported exponent value has dependence on FS Offset
    t4_exp <= get_exp(t3_msb, ctrl_fs_offset_s);
  end

  always_ff @(posedge clk) begin
    t4_state <= t3_state;
    t4_user  <= t3_user;
    t4_sop   <= t3_sop;
    t4_valid <= t3_valid;
    t4_eop   <= t3_eop;
  end

  // r5:
  //----
  // Shift and rounding

  always_ff @(posedge clk) begin
    for (int i = 0; i < NumIq; i++) begin
      t5_data[i] <= shift_and_round(t4_data[i], t4_shift, ctrl_en_s);
    end
  end

  assign t5_data_b = {t5_data[0][15:7], t5_data[1][15:7], t5_data[2][15:7], t5_data[3][15:7]};

  always_ff @(posedge clk) begin
    t5_state <= t4_state;
    t5_exp   <= t4_exp;
    t5_user  <= t4_user;
    t5_sop   <= t4_sop;
    t5_valid <= t4_valid;
    t5_eop   <= t4_eop;
  end

  // r6: gearbox
  //------------

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
    if (ctrl_en_s) begin
      t6_eop_ext <= t5_valid && t5_eop && (t6_cnt == 5);
    end else begin
      t6_eop_ext <= 1'b0;
    end
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
      if (ctrl_en_s) begin
        case (t6_cnt)
          0:       t6_data[63:20] <= {4'b0, t5_exp, t5_data_b};  // +44b
          1:       t6_data[19:0] <= t5_data_b[35:16];  // +20b
          2:       t6_data[63:12] <= {t6_data_f[63:48], t5_data_b};  // +52b
          3:       t6_data[11:0] <= t5_data_b[35:24];  // +12b
          4:       t6_data[63:4] <= {t6_data_f[63:40], t5_data_b};  // +60b
          5:       t6_data[3:0] <= t5_data_b[35:32];
          6:       t6_data <= {t6_data_f[63:32], 4'b0, t5_exp, t5_data_b[35:12]};  // +64b
          7:       t6_data[63:16] <= {t6_data_f[63:52], t5_data_b};  // +48b
          8:       t6_data[15:0] <= t5_data_b[35:20];  // + 16b
          9:       t6_data[63:8] <= {t6_data_f[63:44], t5_data_b};  // +56b
          10:      t6_data[7:0] <= t5_data_b[35:28];  // +8b
          11:      t6_data <= {t6_data_f[63:36], t5_data_b};  // +64b
          default: t6_data <= t6_data;
        endcase
      end else begin  // comp is disabled
        t6_data <= {t5_data[0], t5_data[1], t5_data[2], t5_data[3]};
      end
    end
  end

  always_ff @(posedge clk) begin
    if (t5_valid) begin
      if (ctrl_en_s) begin
        case (t6_cnt)
          1:       t6_data_f[63:48] <= t5_data_b[15:0];
          3:       t6_data_f[63:40] <= t5_data_b[23:0];
          5:       t6_data_f[63:32] <= t5_data_b[31:0];
          6:       t6_data_f[63:52] <= t5_data_b[11:0];
          8:       t6_data_f[63:44] <= t5_data_b[19:0];
          10:      t6_data_f[63:36] <= t5_data_b[27:0];
          default: t6_data_f <= t6_data_f;
        endcase
      end else begin  // comp is disabled
        t6_data_f <= '0;
      end
    end
  end

  always_ff @(posedge clk) begin
    if (t6_eop_ext) begin
      t6_keep <= 8'h0F;
    end else begin
      t6_keep <= 8'hFF;
    end
  end

  always_ff @(posedge clk) begin
    if (ctrl_en_s) begin
      t6_valid <= (t5_valid && t5_eop && (t6_cnt != 5)) ||
        (t5_valid && (t6_cnt == 1 || t6_cnt == 3 || t6_cnt == 5 || t6_cnt == 6 || t6_cnt == 8 || t6_cnt == 10 || t6_cnt == 11));
    end else begin
      t6_valid <= t5_valid;
    end
  end

  always_ff @(posedge clk) begin
    if (ctrl_en_s) begin
      t6_eop <= t5_valid && t5_eop && (t6_cnt != 5);
    end else begin
      t6_eop <= t5_eop;
    end
  end

  // Byte reversed output?
  always_ff @(posedge clk) begin
    if (rst) begin
      m_axis_tuser <= '0;
      m_axis_tvalid <= 1'b0;
    end else if (t6_eop_ext_out) begin
      // Emit the final half word of an odd-PRB packet directly. This leaves
      // the gearbox free to accept the first word of a following packet.
      m_axis_tdata  <= BYTE_REVERSE ? byte_reverse(t6_eop_data) : t6_eop_data;
      m_axis_tkeep  <= 8'h0F;
      m_axis_tlast  <= 1'b1;
      m_axis_tuser  <= t6_eop_user;
      m_axis_tvalid <= 1'b1;
    end else if (t6_valid) begin
      m_axis_tdata <= BYTE_REVERSE ? byte_reverse(t6_data) : t6_data;
      m_axis_tkeep <= t6_keep;
      m_axis_tlast <= t6_eop;
      m_axis_tuser <= t6_user;
      m_axis_tvalid <= 1'b1;
    end else begin
      m_axis_tvalid <= 1'b0;
    end
  end

endmodule

`default_nettype wire
