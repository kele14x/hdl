`timescale 1 ns / 1 ps
//
`default_nettype none

module prach_reshape #(
    parameter int SIZE = 8
) (
    input var         clk,
    /* verilator lint_off UNUSED */
    input var         rst,
    /* verilator lint_on UNUSED */
    //
    input var  [15:0] din_dp1,
    input var  [15:0] din_dp2,
    input var         din_sf,
    input var         din_sl,
    input var         din_sy,
    input var  [ 7:0] din_chn,
    input var         din_dv,
    input var         din_last,
    //
    output var [15:0] dout_dq1,
    output var [15:0] dout_dq2,
    output var        dout_sf,
    output var        dout_sl,
    output var        dout_sy,
    output var [ 7:0] dout_chn,
    output var        dout_dv,
    output var        dout_last
);

  // x0s0s, x0s1s
  // x1s0s, x1s1s
  // =>
  // x0s0s, x1s0s
  // x0s1s, x1s1s

  localparam int Latency = SIZE / 2 + 1;

  // Delay implementation is chosen by depth, following the policy used by the
  // FFT butterfly (prach_fft_ditfft2_bf.sv): flip-flops for the shortest depths,
  // SRLs for the next range, and single-port LUTRAM beyond that.  The two data
  // delays are 16-bit; the sideband delay carries control information, which
  // never leaves LUT-based storage, so it only chooses between flip-flops and
  // SRLs.  There is deliberately no block-RAM branch: the widest delay here is
  // 16 x 129 bits, far too small to be worth a RAMB tile.
  localparam int DataDepth = SIZE / 2;
  localparam int DataRegMax = 8;
  localparam int DataSrlMax = 32;
  localparam int SyncDepth = Latency;
  localparam int SyncRegMax = 8;

  logic        swap_n;

  logic [15:0] din_dp2_d;

  logic [15:0] delay_in;
  logic [15:0] delay_out;

  assign swap_n = din_chn[$clog2(SIZE/2)];

  generate
    if (DataDepth <= DataSrlMax) begin : g_dq2

      delay #(
          .WIDTH  (16),
          .DEPTH  (DataDepth),
          .USE_REG((DataDepth <= DataRegMax) ? 1 : 0)
      ) u_delay_dq2 (
          .clk (clk),
          .cen (1'b1),
          .rst (1'b0),
          .din (din_dp2),
          .dout(din_dp2_d)
      );

    end else begin : g_dq2_lutram

      delay_lutram #(
          .WIDTH(16),
          .DEPTH(DataDepth)
      ) u_delay_dq2 (
          .clk (clk),
          .cen (1'b1),
          .rst (rst),
          .din (din_dp2),
          .dout(din_dp2_d)
      );

    end

    if (DataDepth <= DataSrlMax) begin : g_dx

      delay #(
          .WIDTH  (16),
          .DEPTH  (DataDepth),
          .USE_REG((DataDepth <= DataRegMax) ? 1 : 0)
      ) u_delay_dx (
          .clk (clk),
          .cen (1'b1),
          .rst (1'b0),
          .din (delay_in),
          .dout(delay_out)
      );

    end else begin : g_dx_lutram

      delay_lutram #(
          .WIDTH(16),
          .DEPTH(DataDepth)
      ) u_delay_dx (
          .clk (clk),
          .cen (1'b1),
          .rst (rst),
          .din (delay_in),
          .dout(delay_out)
      );

    end
  endgenerate

  always_ff @(posedge clk) begin
    dout_dq1 <= delay_out;
  end

  always_ff @(posedge clk) begin
    if (swap_n) begin
      dout_dq2 <= din_dp1;
    end else begin
      dout_dq2 <= din_dp2_d;
    end
  end

  always_comb begin
    if (swap_n) begin
      delay_in = din_dp2_d;
    end else begin
      delay_in = din_dp1;
    end
  end

  delay #(
      .WIDTH  (13),
      .DEPTH  (SyncDepth),
      .USE_REG((SyncDepth <= SyncRegMax) ? 1 : 0)
  ) u_delay_sync (
      .clk (clk),
      .cen (1'b1),
      .rst (1'b0),
      .din ({din_last, din_dv, din_chn, din_sy, din_sl, din_sf}),
      .dout({dout_last, dout_dv, dout_chn, dout_sy, dout_sl, dout_sf})
  );

endmodule

`default_nettype wire
