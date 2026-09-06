`timescale 1 ns / 1 ps
//
`default_nettype none

module prach_fft_ditfft3_bf2 #(
    parameter int DATA_WIDTH = 18
) (
    input var                          clk,
    input var                          rst,
    //
    input var  signed [DATA_WIDTH-1:0] din_dr,
    input var  signed [DATA_WIDTH-1:0] din_di,
    input var                          din_dv,
    //
    output var signed [DATA_WIDTH-1:0] dout_dr,
    output var signed [DATA_WIDTH-1:0] dout_di,
    output var                         dout_dv,
    //
    output var                         ovf
);

  // x0, x1, x2 -> x0 + x1, x0 - 0.5 * x1, 0.8660j * x2

  localparam signed [DATA_WIDTH+17:0] RND = 1 << 15;

  logic signed [ DATA_WIDTH-1:0] din_dr_d;
  logic signed [ DATA_WIDTH-1:0] din_di_d;
  logic                          din_dv_d;

  logic        [            1:0] cnt;
  logic                          state;

  logic signed [   DATA_WIDTH:0] x1r_s;
  logic signed [   DATA_WIDTH:0] x1i_s;

  logic signed [ DATA_WIDTH-1:0] x1r;
  logic signed [ DATA_WIDTH-1:0] x1i;

  logic signed [   DATA_WIDTH:0] x2r_s;
  logic signed [   DATA_WIDTH:0] x2i_s;

  logic signed [ DATA_WIDTH-1:0] x2r;
  logic signed [ DATA_WIDTH-1:0] x2i;

  logic                          dv;
  logic                          ovf_r;

  logic signed [ DATA_WIDTH-1:0] ay1;
  logic signed [DATA_WIDTH+17:0] amult;
  /* verilator lint_off UNUSED */
  logic signed [DATA_WIDTH+17:0] aresult;
  /* verilator lint_on UNUSED */

  logic signed [ DATA_WIDTH-1:0] by1;
  logic signed [DATA_WIDTH+17:0] bmult;
  /* verilator lint_off UNUSED */
  logic signed [DATA_WIDTH+17:0] bresult;
  /* verilator lint_on UNUSED */

  function automatic logic signed [DATA_WIDTH:0] op1(input logic signed [DATA_WIDTH-1:0] a,
                                                     input logic signed [DATA_WIDTH-1:0] b);
    logic signed [DATA_WIDTH+1:0] t;
    t = {a[DATA_WIDTH-1], a, 1'b0} - {{2{b[DATA_WIDTH-1]}}, b} + {{(DATA_WIDTH + 1) {1'b0}}, 1'b1};
    t[0] = t[0] & 1'b0;
    return $signed(t[DATA_WIDTH+1:1]);
  endfunction

  // DSP1

  always_ff @(posedge clk) begin
    ay1 <= din_di;
  end

  // coefficient is -0.866025403784439 as fi(1, 18, 16)
  always_ff @(posedge clk) begin
    amult <= ay1 * -36'sd56756;
  end

  always_ff @(posedge clk) begin
    aresult <= amult + RND;
  end

  // DSP2

  always_ff @(posedge clk) begin
    by1 <= din_dr;
  end

  // coefficient is 0.866025403784439 as fi(1, 18, 16)
  always_ff @(posedge clk) begin
    bmult <= by1 * 18'sd56756;
  end

  always_ff @(posedge clk) begin
    bresult <= bmult + RND;
  end

  // BF

  always_ff @(posedge clk) begin
    if (rst) begin
      cnt <= 0;
    end else if (din_dv_d || state) begin
      cnt <= (cnt >= 2) ? '0 : (cnt + 1'b1);
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      state <= 0;
    end else if (cnt >= 2) begin
      state <= 1'b0;
    end else if (din_dv_d) begin
      state <= 1'b1;
    end
  end

  always_ff @(posedge clk) begin
    dv <= din_dv_d || state;
  end

  always_comb begin
    if (cnt == 0) begin
      x1r_s = {din_dr_d[DATA_WIDTH-1], din_dr_d};
      x1i_s = {din_di_d[DATA_WIDTH-1], din_di_d};
    end else begin
      // x0 - x1 / 2
      x1r_s = op1(x1r, din_dr_d);
      x1i_s = op1(x1i, din_di_d);
    end
  end

  always_ff @(posedge clk) begin
    x1r <= x1r_s[DATA_WIDTH-1:0];
    x1i <= x1i_s[DATA_WIDTH-1:0];
  end

  always_comb begin
    if (cnt == 0) begin
      // 0.8660j * x2
      x2r_s = aresult[DATA_WIDTH+16:16];
      x2i_s = bresult[DATA_WIDTH+16:16];
    end else if (cnt == 1) begin
      // x0 + x1
      x2r_s = x1r + din_dr_d;
      x2i_s = x1i + din_di_d;
    end else begin
      // x0
      x2r_s = {x1r[DATA_WIDTH-1], x1r};
      x2i_s = {x1i[DATA_WIDTH-1], x1i};
    end
  end

  always_ff @(posedge clk) begin
    x2r <= x2r_s[DATA_WIDTH-1:0];
    x2i <= x2i_s[DATA_WIDTH-1:0];
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
      .WIDTH  (DATA_WIDTH * 2 + 1),
      .DEPTH  (2),
      .USE_REG(1)
  ) u_delay_data (
      .clk (clk),
      .rst (1'b0),
      .cen (1'b1),
      .din ({din_dv, din_di, din_dr}),
      .dout({din_dv_d, din_di_d, din_dr_d})
  );

  delay #(
      .WIDTH  (1),
      .DEPTH  (1),
      .USE_REG(1)
  ) u_delay_ctrl (
      .clk (clk),
      .rst (1'b0),
      .cen (1'b1),
      .din (dv),
      .dout(dout_dv)
  );

endmodule

`default_nettype wire
