`timescale 1 ns / 1 ps
//
`default_nettype none

module prach_nco (
    input var         clk,
    input var         rst_n,
    // Sync
    input var         sync_in,
    //
    output var [15:0] dout_cos,
    output var [15:0] dout_sin,
    output var [ 2:0] dout_chn,
    output var        sync_out,
    //---
    input var  [16:0] ctrl_fcw[8]
);

  localparam int Latency = 4;
  // sync_in -> acc -> addr -> r1 -> r2
  //            chn

  localparam logic [16:0] Phase000 = 17'b00000000000000000;
  localparam logic [16:0] PhasePI4 = 17'b00011000000000000;
  localparam logic [16:0] PhasePi2 = 17'b00110000000000000;
  localparam logic [16:0] Phase1Pi = 17'b01100000000000000;
  localparam logic [16:0] Phase2Pi = 17'b11000000000000000;

  logic [ 2:0] chn;

  logic [15:0] sin_lut      [2048];

  logic [16:0] cos_addr_pre;
  logic [10:0] cos_addr;
  logic [10:0] sin_addr;

  logic [15:0] cos_r1;
  logic [15:0] sin_r1;

  logic [15:0] cos_r2;
  logic [15:0] sin_r2;

  logic [16:0] fcw          [   8];
  logic [16:0] acc          [   8];

  function automatic logic [16:0] phase_add(input logic [16:0] a, input logic [16:0] b);
    logic [17:0] phi;
    logic [ 2:0] phi_hi;
    phi = a + b;
    phi_hi = phi[17:15] % 3;
    return {phi_hi[1:0], phi[14:0]};
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

  assign cos_addr_pre = phase_add(acc[chn], PhasePi2);

  always_ff @(posedge clk) begin
    cos_addr <= cos_addr_pre[16:6];
    sin_addr <= acc[chn][16:6];
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

  generate
    for (genvar i = 0; i < 8; i++) begin : g_ch

      always_ff @(posedge clk) begin
        fcw[i] <= ctrl_fcw[i];
      end

      always_ff @(posedge clk) begin
        if (~rst_n) begin
          acc[i] <= '0;
        end else if (sync_in) begin
          acc[i] <= '0;
        end else if (chn == i) begin
          acc[i] <= phase_add(acc[i], fcw[i]);
        end
      end

    end
  endgenerate

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
      .WIDTH(3),
      .DELAY(3)
  ) u_delay_chn (
      .clk  (clk),
      .rst_n(1'b1),
      .din  (chn),
      .dout (dout_chn)
  );

endmodule

`default_nettype wire
