`timescale 1 ns / 1 ps
//
`default_nettype none

module pdxch_conv_nco (
    input var         clk,
    input var  [ 6:0] phase,
    output var [15:0] cos,
    output var [15:0] sin
);


  localparam logic [6:0] PhasePi2 = 7'b0100000;

  logic [15:0] cos_lut  [128];

  logic [ 6:0] cos_addr;
  logic [ 6:0] sin_addr;

  logic [15:0] cos_r1;
  logic [15:0] sin_r1;

  logic [15:0] cos_r2;
  logic [15:0] sin_r2;

  // LUT, fi(1, 16, 14)

  initial begin
    for (int i = 0; i < 128; i++) begin
      cos_lut[i] = 16'(int'($cos(3.1415926535 * 2 * i / 128) * 2 ** 14));
    end
  end

  always_ff @(posedge clk) begin
    cos_addr <= phase;
    sin_addr <= phase - PhasePi2;
  end

  always_ff @(posedge clk) begin
    cos_r1 <= cos_lut[cos_addr];
    sin_r1 <= cos_lut[sin_addr];
  end

  always_ff @(posedge clk) begin
    cos_r2 <= cos_r1;
    sin_r2 <= sin_r1;
  end

  assign cos = cos_r2;
  assign sin = sin_r2;

endmodule

`default_nettype wire
