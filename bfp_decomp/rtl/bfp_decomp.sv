`timescale 1 ns / 1 ps
//
`default_nettype none

module bfp_decomp #(
    parameter bit BYTE_REVERSE = 1,
    parameter int USER_WIDTH   = 91
) (
    input  wire                  clk,
    input  wire                  rst,
    //
    input  wire [          63:0] s_axis_tdata,
    input  wire [           7:0] s_axis_tkeep,
    input  wire                  s_axis_tlast,
    input  wire [USER_WIDTH-1:0] s_axis_tuser,
    input  wire                  s_axis_tvalid,
    output wire                  s_axis_tready,
    //
    output wire [         127:0] m_axis_tdata,
    output wire [          15:0] m_axis_tkeep,
    output wire                  m_axis_tlast,
    output wire [USER_WIDTH-1:0] m_axis_tuser,
    output wire                  m_axis_tvalid,
    // CSR
    input  wire [           3:0] ctrl_ud_comp_meth,
    input  wire [           3:0] ctrl_ud_iq_width,
    input  wire [           3:0] ctrl_fs_offset,
    //
    output wire                  err_unexpected_tlast
);

  // Parameters
  //===========

  localparam int NumIq = 8;
  localparam int Latency = 6;

  // Signals
  //========

  logic [  3:0] ud_iq_width;

  logic [  1:0] state;
  logic [  1:0] state_next;

  // sync_n       -> t0_*  -> t1_*  -> t2_*  -> output
  // state
  // byte_remain

  logic [ 63:0] s_axis_tdata_s;

  logic         extend_eop;
  logic         extend_eop_next;

  logic [  4:0] byte_remain;  // 0 ~ 15
  logic [  4:0] byte_remain_next;

  logic [  4:0] byte_shift_next;

  logic [  4:0] byte_required;  // 1 ~ 16

  logic [ 63:0] t0_data1;
  logic [ 63:0] t0_data2;
  logic [ 63:0] t0_data3;

  logic [191:0] t0_data;

  logic [  3:0] t0_shift;
  logic         t0_valid;
  logic         t0_eop;

  logic [  4:0] t0_exp_shift;
  logic         t0_exp_valid;

  logic [127:0] t1_data;
  logic         t1_valid;
  logic         t1_eop;

  logic [  3:0] t1_exp;

  logic [ 15:0] t2_data                  [NumIq];
  logic [  3:0] t2_exp;
  logic         t2_valid;
  logic         t2_eop;

  logic [ 30:0] t3_data                  [NumIq];
  logic         t3_valid;
  logic         t3_eop;

  logic [ 15:0] t4_data                  [NumIq];
  logic         t4_valid;
  logic         t4_eop;

  logic [127:0] m_axis_tdata_s;

  logic         unexpected_tlast;

  // Helpers
  //========

  //
  // This function does byte reverse for 64-bit stream data signal
  //
  function automatic logic [63:0] byte_reverse64(input logic [63:0] din);
    for (int i = 0; i < 8; i++) begin
      byte_reverse64[63-8*i-:8] = din[8*i+7-:8];
    end
  endfunction

  //
  // This function does byte reverse for 128-bit stream data signal
  //
  function automatic logic [127:0] byte_reverse128(input logic [127:0] din);
    for (int i = 0; i < 16; i++) begin
      byte_reverse128[127-8*i-:8] = din[8*i+7-:8];
    end
  endfunction

  //
  // This function get bit_mask by bit width
  //
  function automatic logic [15:0] bit_mask(input logic [3:0] width);
    case (width)
      4'd1:    bit_mask = 16'h0001;
      4'd2:    bit_mask = 16'h0003;
      4'd3:    bit_mask = 16'h0007;
      4'd4:    bit_mask = 16'h000F;
      4'd5:    bit_mask = 16'h001F;
      4'd6:    bit_mask = 16'h003F;
      4'd7:    bit_mask = 16'h007F;
      4'd8:    bit_mask = 16'h00FF;
      4'd9:    bit_mask = 16'h01FF;
      4'd10:   bit_mask = 16'h03FF;
      4'd11:   bit_mask = 16'h07FF;
      4'd12:   bit_mask = 16'h0FFF;
      4'd13:   bit_mask = 16'h1FFF;
      4'd14:   bit_mask = 16'h3FFF;
      4'd15:   bit_mask = 16'h7FFF;
      default: bit_mask = 16'hFFFF;
    endcase
  endfunction

  //
  // Bit extract by shifting and masking
  //
  function automatic logic [15:0] bit_extract(input int i, input logic [3:0] width,
                                              input logic [127:0] din);
    if (width == 0) begin
      bit_extract = 16'(din >> i * 16);
    end else begin
      bit_extract = 16'(din >> i * width);
    end
    bit_extract = bit_extract & bit_mask(width);
  endfunction

  //
  // Decompress, always align MSB at bit-30
  //
  function automatic logic [30:0] decompress(input logic [15:0] data, input logic [3:0] width,
                                             input logic [3:0] exp);
    int shift;
    case (width)
      4'd1:    decompress = {data[0], 30'b0};
      4'd2:    decompress = {data[1:0], 29'b0};
      4'd3:    decompress = {data[2:0], 28'b0};
      4'd4:    decompress = {data[3:0], 27'b0};
      4'd5:    decompress = {data[4:0], 26'b0};
      4'd6:    decompress = {data[5:0], 25'b0};
      4'd7:    decompress = {data[6:0], 24'b0};
      4'd8:    decompress = {data[7:0], 23'b0};
      4'd9:    decompress = {data[8:0], 22'b0};
      4'd10:   decompress = {data[9:0], 21'b0};
      4'd11:   decompress = {data[10:0], 20'b0};
      4'd12:   decompress = {data[11:0], 19'b0};
      4'd13:   decompress = {data[12:0], 18'b0};
      4'd14:   decompress = {data[13:0], 17'b0};
      4'd15:   decompress = {data[14:0], 16'b0};
      default: decompress = {data, 15'b0};
    endcase
    shift = width == 0 ? 0 : 15 - int'(exp);
    decompress = $signed(decompress) >>> shift;
  endfunction

  //
  // This function saturate signed 31-bit to 16-bit. When fs_offset is 0, output
  // is 16-bit MSB of input. fs_offset "shift" the full position by using lower
  // bits as output.
  //  - If FS_OFFSET is 0, where will be no overflow or underflow so saturate
  //    is not needed.
  //  - IF FS_OFFSET is larger than 0, there maybe overflow or underflow if not
  //    proper configured.
  //
  function automatic logic [15:0] saturate(input logic [30:0] din, input logic [3:0] fs_offset);
    logic sign;
    logic [16:0] temp;
    // Full position, with 1 extra bit for rounding
    temp = din[30-fs_offset-:17];
    // Check sign bit for saturate
    sign = din[30];
    for (int i = 0; i < fs_offset; i++) begin
      if (sign ^ din[29-fs_offset]) begin
        temp = sign ? 17'h10000 : 17'h0FFFF;
      end
    end
    // Rounding
    temp = temp == 17'h0FFFF ? temp : temp + 1'b1;
    saturate = temp[16:1];
  endfunction


  // Main
  //=====

  always_ff @(posedge clk) begin
    ud_iq_width <= ctrl_ud_comp_meth == 4'h1 ? ctrl_ud_iq_width : '0;
  end

  // Read input
  //-----------
  // State registers: state, extend_eop, byte_remain
  // Inputs: din_valid, avst_sink_startofpacket, avst_sink_endofpacket, ud_iq_width

  // IQ extract FSM
  // Since we extract 4 IQ pairs (4 REs) at same tick, for 1 RB we need 3 state
  // The state counter tries to go from 0 to 2 then rollover, unless we does not
  // receive enough data

  always_ff @(posedge clk) begin
    if (rst) begin
      state <= '0;
    end else begin
      state <= state_next;
    end
  end

  always_comb begin
    if (s_axis_tvalid && (8 + byte_remain >= byte_required)) begin
      state_next = state == 2 ? 0 : state + 1'b1;
    end else if (byte_remain >= byte_required) begin
      state_next = state == 2 ? 0 : state + 1'b1;
    end else if (extend_eop) begin
      state_next = 0;
    end else begin
      state_next = state;
    end
  end

  // Extend EOP
  // Sometimes we need to extend the EOP signal for some clock ticks, this
  // happens when we receive the last 2 REs at the same tick with previous REs

  always_ff @(posedge clk) begin
    if (rst) begin
      extend_eop <= 1'b0;
    end else begin
      extend_eop <= extend_eop_next;
    end
  end

  always_comb begin
    if (state == 2) begin
      // Enough data for this RB
      extend_eop_next = 1'b0;
    end else if (byte_remain > byte_required) begin
      // Not enough data for this RB
      extend_eop_next = 1'b0;
    end else if (s_axis_tvalid && s_axis_tlast && state == 2) begin
      // Last word received
      extend_eop_next = 1'b0;
    end else if (s_axis_tvalid && s_axis_tlast) begin
      extend_eop_next = 1'b1;
    end else if (s_axis_tvalid) begin
      extend_eop_next = 1'b0;
    end else begin
      extend_eop_next = 1'b0;
    end
  end

  // Required number of bytes

  always_comb begin
    if (state == 0) begin
      byte_required = ud_iq_width == 0 ? 5'd16 : {1'b0, ud_iq_width} + 5'd1;
    end else begin
      byte_required = ud_iq_width == 0 ? 5'd16 : {1'b0, ud_iq_width};
    end
  end

  // Remained number of bytes

  always_ff @(posedge clk) begin
    if (rst) begin
      byte_remain <= '0;
    end else begin
      byte_remain <= byte_remain_next;
    end
  end

  always_comb begin
    byte_remain_next = byte_remain;

    // TODO: logic to clear remained bytes when EOP
    if (s_axis_tvalid && s_axis_tlast) begin
      byte_remain_next = 0;
    end

    if (s_axis_tvalid && ~s_axis_tlast) begin
      byte_remain_next = byte_remain_next + 8;
    end

    if (byte_remain_next >= byte_required) begin
      byte_remain_next = byte_remain_next - byte_required;
    end
  end

  // Similar with with byte_remain_next, but does not reset to 0 on EOP
  always_comb begin
    byte_shift_next = byte_remain;

    if (s_axis_tvalid) begin
      byte_shift_next = byte_shift_next + 8;
    end

    if (byte_shift_next >= byte_required) begin
      byte_shift_next = byte_shift_next - byte_required;
    end
  end

  // Byte reversed inputs?

  always_comb begin
    s_axis_tdata_s = (BYTE_REVERSE ? byte_reverse64(s_axis_tdata) : s_axis_tdata) ^ {64{|s_axis_tkeep & 1'b0}};
  end

  // Report error is EOP is present at wrong position

  always_ff @(posedge clk) begin
    unexpected_tlast <= 1'b0;
    if (extend_eop && ({1'b0, byte_remain} + byte_required >= 16) && state != 2) begin
      unexpected_tlast <= 1'b1;
    end
  end

  assign err_unexpected_tlast = unexpected_tlast;

  // Concatenate block data
  //-----------------------

  // Data buffer and shift

  always_ff @(posedge clk) begin
    if (s_axis_tvalid) begin
      t0_data1 <= s_axis_tdata_s;
      t0_data2 <= t0_data1;
      t0_data3 <= t0_data2;
    end
  end

  assign t0_data = {t0_data3, t0_data2, t0_data1};

  always_ff @(posedge clk) begin
    t0_shift <= byte_shift_next[3:0];
  end

  always_ff @(posedge clk) begin
    t0_valid <= (s_axis_tvalid ? 'd8 : 'd0) + byte_remain >= byte_required;
  end

  always_ff @(posedge clk) begin
    if (s_axis_tvalid && s_axis_tlast && state == 2) begin
      t0_eop <= 1'b1;
    end else if (extend_eop && byte_remain >= byte_required) begin
      t0_eop <= 1'b1;
    end else if (extend_eop && state == 2) begin
      t0_eop <= 1'b1;
    end else begin
      t0_eop <= 1'b0;
    end
  end

  always_ff @(posedge clk) begin
    t0_exp_shift <= byte_shift_next + ud_iq_width;
  end

  always_ff @(posedge clk) begin
    t0_exp_valid <= s_axis_tvalid && (state == 0) && ((8 + byte_remain) >= byte_required);
  end

  // Extract block data
  //-------------------

  always_ff @(posedge clk) begin
    if (t0_valid) begin
      t1_data <= 128'(t0_data >> (t0_shift * 8));
    end
  end

  always_ff @(posedge clk) begin
    t1_valid <= t0_valid;
    t1_eop   <= t0_eop;
  end

  always_ff @(posedge clk) begin
    if (ud_iq_width == 0) begin
      t1_exp <= '0;
    end else if (t0_exp_valid) begin
      t1_exp <= 4'(t0_data >> (t0_exp_shift * 8));
    end
  end

  // Extract IQ data
  //----------------

  generate
    for (genvar i = 0; i < NumIq; i++) begin : g_bit_extract
      always_ff @(posedge clk) begin
        t2_data[NumIq-1-i] <= bit_extract(i, ud_iq_width, t1_data);
      end
    end
  endgenerate

  always_ff @(posedge clk) begin
    t2_exp   <= t1_exp;
    t2_valid <= t1_valid;
    t2_eop   <= t1_eop;
  end

  // Decompress
  //-----------

  generate
    for (genvar i = 0; i < NumIq; i++) begin : g_shift
      // Shift right with sign extend
      always_ff @(posedge clk) begin
        t3_data[i] <= decompress(t2_data[i], ud_iq_width, t2_exp);
      end
    end
  endgenerate

  always_ff @(posedge clk) begin
    t3_valid <= t2_valid;
    t3_eop   <= t2_eop;
  end

  // fs_offset shift

  generate
    for (genvar i = 0; i < NumIq; i++) begin : g_saturate
      // Saturate
      always_ff @(posedge clk) begin
        t4_data[i] <= saturate(t3_data[i], ctrl_fs_offset);
      end
    end
  endgenerate

  always_ff @(posedge clk) begin
    t4_valid <= t3_valid;
    t4_eop   <= t3_eop;
  end

  // Output
  //-------

  assign s_axis_tready = 1'b1;

  assign m_axis_tdata_s = {
    t4_data[0],  // I0
    t4_data[1],  // Q0
    t4_data[2],  // I1
    t4_data[3],  // Q1
    t4_data[4],  // I2
    t4_data[5],  // Q2
    t4_data[6],  // I3
    t4_data[7]  // Q3
  };

  // Intel O-RAN IP data output format
  assign m_axis_tdata = byte_reverse128(m_axis_tdata_s);

  assign m_axis_tkeep = 16'hFFFF;

  assign m_axis_tvalid = t4_valid;

  assign m_axis_tlast = t4_eop;

  delay #(
      .WIDTH(USER_WIDTH),
      .DEPTH(Latency),
      .INIT (1'b0)
  ) u_delay_tuser (
      .clk (clk),
      .rst (1'b0),
      .cen (1'b1),
      //
      .din (s_axis_tuser),
      .dout(m_axis_tuser)
  );

endmodule

`default_nettype wire
