`timescale 1 ns / 1 ps
//
`default_nettype none

module prach_conv_nco (
    input var         clk,
    input var         rst,
    // Sync
    input var         sync_in,
    //
    output var [15:0] dout_cos,
    output var [15:0] dout_sin,
    output var [ 7:0] dout_chn,
    output var        sync_out
);

  localparam int Latency = 4;
  // sync_in -> acc -> addr -> r1 -> r2
  //            chn
  localparam int PhaseWidth = 5;

  localparam logic [PhaseWidth-1:0] PhasePi2 = 1 << (PhaseWidth - 2);

  logic [           7:0] chn;

  logic [          15:0] sin_lut      [2**PhaseWidth];

  logic [PhaseWidth-1:0] cos_addr_pre;
  logic [PhaseWidth-1:0] cos_addr;
  logic [PhaseWidth-1:0] sin_addr;

  logic [          15:0] cos_r1;
  logic [          15:0] sin_r1;

  logic [          15:0] cos_r2;
  logic [          15:0] sin_r2;

  logic [PhaseWidth-1:0] acc;

  // Channel counter

  always_ff @(posedge clk) begin
    if (sync_in) begin
      chn <= '0;
    end else begin
      chn <= chn + 1'b1;
    end
  end

  // LUT, fi(1, 16, 14)

  initial begin
    for (int i = 0; i < 2 ** PhaseWidth; i++) begin
      sin_lut[i] = 16'(int'($sin(3.1415926535 * 2 * i / 2 ** PhaseWidth) * 2 ** 14));
    end
  end

  assign cos_addr_pre = acc + PhasePi2;

  always_ff @(posedge clk) begin
    cos_addr <= cos_addr_pre;
    sin_addr <= acc;
  end

  always_ff @(posedge clk) begin
    cos_r1 <= sin_lut[cos_addr];
    sin_r1 <= sin_lut[sin_addr];
  end

  always_ff @(posedge clk) begin
    cos_r2 <= cos_r1;
    sin_r2 <= sin_r1;
  end

  assign dout_cos = cos_r2;
  assign dout_sin = sin_r2;

  // Phase Accumulator

  always_ff @(posedge clk) begin
    if (rst) begin
      acc <= '0;
    end else if (sync_in) begin
      acc <= '0;
    end else if (chn == '1) begin
      acc <= acc + 5'd9;
    end
  end

  delay #(
      .WIDTH(1),
      .DEPTH(Latency),
      .INIT (0)
  ) u_delay_sync (
      .clk (clk),
      .cen (1'b1),
      .rst (1'b0),
      .din (sync_in),
      .dout(sync_out)
  );

  delay #(
      .WIDTH(8),
      .DEPTH(Latency - 1),
      .INIT (0)
  ) u_delay_chn (
      .clk (clk),
      .cen (1'b1),
      .rst (1'b0),
      .din (chn),
      .dout(dout_chn)
  );

endmodule

`default_nettype wire
