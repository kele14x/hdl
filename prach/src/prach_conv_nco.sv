`timescale 1 ns / 1 ps
//
`default_nettype none

module prach_conv_nco (
    input var         clk,
    input var         rst_n,
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

  localparam logic [10:0] Phase000 = 11'b00000000000;
  localparam logic [10:0] PhasePI4 = 11'b00011000000;
  localparam logic [10:0] PhasePi2 = 11'b00110000000;
  localparam logic [10:0] Phase1Pi = 11'b01100000000;
  localparam logic [10:0] Phase2Pi = 11'b11000000000;

  logic [ 7:0] chn;

  logic [15:0] sin_lut      [2048];

  logic [10:0] cos_addr_pre;
  logic [10:0] cos_addr;
  logic [10:0] sin_addr;

  logic [15:0] cos_r1;
  logic [15:0] sin_r1;

  logic [15:0] cos_r2;
  logic [15:0] sin_r2;

  logic [10:0] acc;

  function automatic logic [10:0] phase_add(input logic [10:0] a, input logic [10:0] b);
    logic [11:0] phi;
    logic [ 2:0] phi_hi;
    phi = a + b;
    phi_hi = phi[11:9] % 3;
    return {phi_hi[1:0], phi[8:0]};
  endfunction

  // Channel counter

  always_ff @(posedge clk) begin
    if (sync_in) begin
      chn <= '0;
    end else begin
      chn <= chn + 1;
    end
  end

  // LUT, fi(1, 16, 14)

  initial begin
    for (int i = 0; i < 2048; i++) begin
      if (i < 1536) begin
        sin_lut[i] = int'($sin(3.1415926535 * 2 * i / 1536) * 2 ** 14);
      end else begin
        sin_lut[i] = '0;
      end
    end
  end

  assign cos_addr_pre = phase_add(acc, PhasePi2);

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
    if (~rst_n) begin
      acc <= '0;
    end else if (sync_in) begin
      acc <= '0;
    end else if (chn == '1) begin
      acc <= phase_add(acc, 432);
    end
  end

  delay #(
      .WIDTH(1),
      .DELAY(Latency)
  ) u_delay_sync (
      .clk  (clk),
      .rst_n(1'b1),
      .din  (sync_in),
      .dout (sync_out)
  );

  delay #(
      .WIDTH(8),
      .DELAY(3)
  ) u_delay_chn (
      .clk  (clk),
      .rst_n(1'b1),
      .din  (chn),
      .dout (dout_chn)
  );

endmodule

`default_nettype wire
