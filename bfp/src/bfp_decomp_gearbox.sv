// File: bfp_decomp_gearbox.sv
// Brief: Bit remap to get exponent and mantissa field from bit stream.
// Latency: 2
`timescale 1 ns / 1 ps
//
`default_nettype none

module bfp_decomp_gearbox (
    input var         clk,
    input var         rst,
    //
    input var  [63:0] s_axis_tdata,
    input var  [ 7:0] s_axis_tkeep,
    input var         s_axis_tvalid,
    input var         s_axis_tlast,
    output var        s_axis_tready,
    //
    output var [63:0] dout_data,
    output var [ 3:0] dout_state,
    output var        dout_sync,
    output var        dout_valid,
    output var        dout_last,
    //
    input var  [ 3:0] ud_iq_width,
    //
    output var        err_unexpected_tlast
);

  import bfp_pkg::*;

  logic         init_n;
  logic         sync_n;

  logic [  3:0] state;
  logic [  3:0] state_next;

  logic         extend_tlast;
  logic         extend_tlast_next;

  logic [  3:0] bit_remain;
  logic [  3:0] bit_remain_next;

  logic [  3:0] bit_required;

  logic [ 63:0] temp_data1;
  logic [ 63:0] temp_data2;
  logic [127:0] temp_data;

  logic [  3:0] temp_shift;
  logic [  3:0] temp_state;
  logic         temp_valid;
  logic         temp_sync;
  logic         temp_last;


  // Read input
  //-----------
  // State registers: init_n, sync_n, state, extend_tlast, bit_remain
  // Inputs: s_axis_tvalid, s_axis_tlast, s_axis_tuser, ud_iq_width

  // Out of reset
  always_ff @(posedge clk) begin
    if (rst) begin
      init_n <= 1'b0;
    end else begin
      init_n <= 1'b1;
    end
  end

  // Sync with input packet. It is used to mark the first tick of data packet.
  always_ff @(posedge clk) begin
    if (rst) begin
      sync_n <= 1'b0;
    end else if (s_axis_tvalid && s_axis_tready && s_axis_tlast) begin
      sync_n <= 1'b0;
    end else if (s_axis_tvalid && s_axis_tready) begin
      sync_n <= 1'b1;
    end else begin
      sync_n <= sync_n;
    end
  end

  // IQ extract FSM
  // Since we extract 2 IQ pairs (2 REs) at same tick, for 1 RB we need 6 state
  // The state counter tries to go from 0 to 5 then rollover, unless we does not
  // receive enough data

  always_ff @(posedge clk) begin
    if (rst) begin
      state <= '0;
    end else begin
      state <= state_next;
    end
  end

  always_comb begin
    state_next = state;
    if (~init_n) begin
      state_next = 0;
    end else if (~s_axis_tready && extend_tlast && ({1'b0, bit_remain} + bit_required >= 16)) begin
      state_next = 0;
    end else if (s_axis_tready && ~s_axis_tvalid) begin
      state_next = state;
    end else begin
      state_next = (state == 5 ? 0 : state + 1);
    end
  end

  // Extend TLAST
  // Sometimes we need to extend the TLAST signal for some clock ticks, this
  // happens when we receive the last 2 REs at the same tick with previous REs

  always_ff @(posedge clk) begin
    if (rst) begin
      extend_tlast <= 1'b0;
    end else begin
      extend_tlast <= extend_tlast_next;
    end
  end

  always_comb begin
    if (~init_n) begin
      extend_tlast_next = 1'b0;
    end else if (~s_axis_tready && state == 5) begin
      // Enough data for this RB
      extend_tlast_next = 1'b0;
    end else if (~s_axis_tready && ({1'b0, bit_remain} + bit_required >= 16)) begin
      // Not enough data for this RB
      extend_tlast_next = 1'b0;
    end else if (~s_axis_tready) begin
      extend_tlast_next = extend_tlast;
    end else if (s_axis_tvalid && s_axis_tlast && state == 5) begin
      // Last word received
      extend_tlast_next = 1'b0;
    end else if (s_axis_tvalid && s_axis_tlast) begin
      extend_tlast_next = 1'b1;
    end else if (s_axis_tvalid) begin
      extend_tlast_next = 1'b0;
    end else begin
      extend_tlast_next = 1'b0;
    end
  end

  // `s_axis_tready` indicates we need input data to process (TREADY)
  assign s_axis_tready = ({1'b0, bit_remain} + bit_required > 16) || (bit_remain == '0) && ~extend_tlast;

  // Required number of bits
  // The register value is real value / 4

  always_comb begin
    if (state == 0) begin
      bit_required = ud_iq_width == 0 ? 16 : ud_iq_width + 2;
    end else begin
      bit_required = ud_iq_width == 0 ? 16 : ud_iq_width;
    end
  end


  // Remained number of bits, the register value is real bits remained / 4

  always_ff @(posedge clk) begin
    if (rst) begin
      bit_remain <= '0;
    end else begin
      bit_remain <= bit_remain_next;
    end
  end

  always_comb begin
    if (~init_n) begin
      bit_remain_next = 0;
    end else if (~s_axis_tready && extend_tlast && state == 5) begin
      bit_remain_next = 0;
    end else if (~s_axis_tready && extend_tlast && ({1'b0, bit_remain} + bit_required >= 16)) begin
      bit_remain_next = 0;
    end else if (~s_axis_tready) begin
      bit_remain_next = (bit_remain + bit_required);  // mod 64 naturally
    end else if (s_axis_tvalid && s_axis_tlast && state == 5) begin
      // we are at state 5, so could safely goes to init state
      bit_remain_next = 0;
    end else if (s_axis_tvalid) begin
      // at other state, we still tries go further
      bit_remain_next = (bit_remain + bit_required);
    end else begin
      bit_remain_next = bit_remain;
    end
  end

  // Report error is TLAST is present at wrong position

  always_ff @(posedge clk) begin
    err_unexpected_tlast <= 1'b0;
    if (extend_tlast && ({1'b0, bit_remain} + bit_required >= 16) && state != 5) begin
      err_unexpected_tlast <= 1'b1;
    end
  end


  // Extract bit
  //------------

  // Data buffer and shift

  always_ff @(posedge clk) begin
    if (s_axis_tvalid && s_axis_tready) begin
      temp_data1 <= byte_reverse(s_axis_tdata);
      temp_data2 <= temp_data1;
    end
  end

  assign temp_data = {temp_data2, temp_data1};

  always_ff @(posedge clk) begin
    temp_shift <= -bit_remain - bit_required;
  end

  always_ff @(posedge clk) begin
    temp_state <= state;
    temp_sync  <= sync_n;
  end

  always_ff @(posedge clk) begin
    temp_valid <= (s_axis_tvalid && s_axis_tready) || (~s_axis_tready && init_n);
  end

  always_ff @(posedge clk) begin
    if (s_axis_tvalid && s_axis_tready && s_axis_tlast && (state == 5)) begin
      temp_last <= 1'b1;
    end else if (extend_tlast && ({1'b0, bit_remain} + bit_required > 16)) begin
      temp_last <= 1'b1;
    end else if (extend_tlast && (state == 5)) begin
      temp_last <= 1'b1;
    end else begin
      temp_last <= 1'b0;
    end
  end


  // Output
  //-------

  always_ff @(posedge clk) begin
    if (temp_valid) begin
      dout_data <= (temp_data >> (temp_shift * 4));
    end
  end

  always_ff @(posedge clk) begin
    dout_state <= temp_state;
    dout_valid <= temp_valid;
    dout_sync  <= temp_sync;
    dout_last  <= temp_last;
  end

endmodule

`default_nettype wire
