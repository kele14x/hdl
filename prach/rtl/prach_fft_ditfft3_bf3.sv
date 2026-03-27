`timescale 1 ns / 1 ps
//
`default_nettype none

module prach_fft_ditfft3_bf3 #(
    parameter int DATA_WIDTH = 18
) (
    input  wire                         clk,
    input  wire                         rst,
    //
    input  wire signed [DATA_WIDTH-1:0] din_dr,
    input  wire signed [DATA_WIDTH-1:0] din_di,
    input  wire                         din_dv,
    //
    output wire signed [DATA_WIDTH-1:0] dout_dr,
    output wire signed [DATA_WIDTH-1:0] dout_di,
    output wire                         dout_dv,
    //
    output wire                         ovf
);

  // x0, x1, x2 -> x0, x1 + x2, x1 - x2/

  logic        [           1:0] cnt;
  logic                         state;

  logic signed [  DATA_WIDTH:0] x1r_s;
  logic signed [  DATA_WIDTH:0] x1i_s;

  logic signed [DATA_WIDTH-1:0] x1r;
  logic signed [DATA_WIDTH-1:0] x1i;

  logic signed [  DATA_WIDTH:0] x2r_s;
  logic signed [  DATA_WIDTH:0] x2i_s;

  logic signed [DATA_WIDTH-1:0] x2r;
  logic signed [DATA_WIDTH-1:0] x2i;

  logic                         dv;
  logic                         ovf_r;


  always_ff @(posedge clk) begin
    if (rst) begin
      cnt <= 0;
    end else if (din_dv || state) begin
      cnt <= (cnt >= 2) ? '0 : (cnt + 1'b1);
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      state <= 0;
    end else if (cnt >= 2) begin
      state <= 1'b0;
    end else if (din_dv) begin
      state <= 1'b1;
    end
  end

  always_ff @(posedge clk) begin
    dv <= din_dv || state;
  end

  always_comb begin
    if (cnt == 0 || cnt == 1) begin
      // x0, x1 + x2
      x1r_s = din_dr;
      x1i_s = din_di;
    end else begin
      // x1 - x2
      x1r_s = x1r - din_dr;
      x1i_s = x1i - din_di;
    end
  end

  always_ff @(posedge clk) begin
    x1r <= x1r_s[DATA_WIDTH-1:0];
    x1i <= x1i_s[DATA_WIDTH-1:0];
  end

  always_comb begin
    if (cnt == 2) begin
      // x1 + x2
      x2r_s = x1r + din_dr;
      x2i_s = x1i + din_di;
    end else begin
      // x0, x1 - x2
      x2r_s = x1r;
      x2i_s = x1i;
    end
  end

  always_ff @(posedge clk) begin
    x2r = x2r_s[DATA_WIDTH-1:0];
    x2i = x2i_s[DATA_WIDTH-1:0];
  end

  always_ff @(posedge clk) begin
    ovf_r <= ~(x1r_s[DATA_WIDTH-:2] == 2'b00 || x1r_s[DATA_WIDTH-:2] == 2'b11) ||
             ~(x1i_s[DATA_WIDTH-:2] == 2'b00 || x1i_s[DATA_WIDTH-:2] == 2'b11) ||
             ~(x2r_s[DATA_WIDTH-:2] == 2'b00 || x2r_s[DATA_WIDTH-:2] == 2'b11) ||
             ~(x2i_s[DATA_WIDTH-:2] == 2'b00 || x2i_s[DATA_WIDTH-:2] == 2'b11);
  end

  assign dout_dr = x2r;
  assign dout_di = x2i;
  assign ovf     = ovf_r;

  delay #(
      .WIDTH(1),
      .DEPTH(1),
      .INIT (1'b0)
  ) u_delay (
      .clk (clk),
      .rst (1'b0),
      .cen (1'b1),
      .din (dv),
      .dout(dout_dv)
  );

endmodule

`default_nettype wire
