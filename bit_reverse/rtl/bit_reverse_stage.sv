`default_nettype none
//
`timescale 1 ns / 1 ps

module bit_reverse_stage #(
    parameter int NUM_INLV     = 4,
    parameter int IDX_STAGE    = 0,
    parameter int LOG_FFT_SIZE = 12,
    parameter int DATA_WIDTH   = 16
) (
    input var                                               clk,
    input var                                               rst,
    // Data input
    input var  [                            DATA_WIDTH-1:0] din_dr,
    input var  [                            DATA_WIDTH-1:0] din_di,
    input var  [(NUM_INLV <= 1 ? 1 : $clog2(NUM_INLV))-1:0] din_id,
    input var                                               din_valid,
    input var                                               din_last,
    // Data output
    output var [                            DATA_WIDTH-1:0] dout_dr,
    output var [                            DATA_WIDTH-1:0] dout_di,
    output var [(NUM_INLV <= 1 ? 1 : $clog2(NUM_INLV))-1:0] dout_id,
    output var                                              dout_valid,
    output var                                              dout_last
);

  // Swap x_j and x_k, where:
  //   j = N - 1 - i
  //   k = i
  localparam int DelayTaps = NUM_INLV * (2 ** (LOG_FFT_SIZE - 1 - IDX_STAGE) - 2 ** IDX_STAGE);

  localparam int IdWidth = NUM_INLV <= 1 ? 1 : $clog2(NUM_INLV);
  localparam logic [31:0] LastIdFull = NUM_INLV - 1;
  localparam logic [IdWidth-1:0] LastId = LastIdFull[IdWidth-1:0];

  // DRC

  initial begin : drc_check
    assert (1 <= DelayTaps && DelayTaps <= 16384)
    else begin
      $error("[%m]: DelayTaps (%0d) must be within the range 1 to 16384.", DelayTaps);
    end
  end

  // Each stage has a local counter, which counts from 0 to FFT_SIZE-1. Counter
  // synchronize with `din_dr`.
  logic [        LOG_FFT_SIZE-1:0] counter;

  logic                            switch;

  logic [2*DATA_WIDTH+IdWidth+1:0] data_m0;
  logic [2*DATA_WIDTH+IdWidth+1:0] data_m1;
  logic [2*DATA_WIDTH+IdWidth+1:0] data_delayed;

  logic [          DATA_WIDTH-1:0] data_dr_s;
  logic [          DATA_WIDTH-1:0] data_di_s;
  logic [             IdWidth-1:0] data_id_s;
  logic                            data_valid_s;
  logic                            data_last_s;

  // Main

  always_ff @(posedge clk) begin
    if (rst) begin
      counter <= 'd0;
    end else if (din_valid && din_last && din_id == LastId) begin
      counter <= 'd0;
    end else if (din_valid && din_id == LastId) begin
      counter <= counter + 1'd1;
    end
  end

  // s = x_j and /x_k ({x_j, x_k} == 2'b10)
  assign switch  = counter[LOG_FFT_SIZE-1-IDX_STAGE] && ~counter[IDX_STAGE];

  assign data_m0 = switch ? data_delayed : {din_last, din_valid, din_id, din_di, din_dr};

  // For smaller delay, choose register based delay for optimized resource
  // and lower latency. For big delay, choose RAMs based implementation
  // (same threshold as fft_bf2).
  generate
    if (DelayTaps <= 128) begin : g_delay
      delay #(
          .WIDTH(2 * DATA_WIDTH + IdWidth + 2),
          .DEPTH(DelayTaps)
      ) i_delay (
          .clk (clk),
          .rst (rst),
          .cen (1'b1),
          .din (data_m0),
          .dout(data_delayed)
      );
    end else begin : g_shift_ram
      shift_ram #(
          .DEPTH(DelayTaps),
          .WIDTH(2 * DATA_WIDTH + IdWidth + 2)
      ) i_delay (
          .clk (clk),
          .rst (rst),
          .cen (1'b1),
          .din (data_m0),
          .dout(data_delayed)
      );
    end
  endgenerate

  assign data_m1 = switch ? {din_last, din_valid, din_id, din_di, din_dr} : data_delayed;

  assign {data_last_s, data_valid_s, data_id_s, data_di_s, data_dr_s} = data_m1;

  // Data output

  always_ff @(posedge clk) begin
    if (data_valid_s) begin
      dout_dr   <= data_dr_s;
      dout_di   <= data_di_s;
      dout_last <= data_last_s;
    end
  end

  always_ff @(posedge clk) begin
    dout_id    <= data_id_s;
    dout_valid <= data_valid_s;
  end

endmodule

`default_nettype wire
