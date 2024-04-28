`timescale 1 ns / 1 ps
//
`default_nettype none

module prach_ditfft3_bf2 (
    input var         clk,
    input var         rst_n,
    //
    input var  [17:0] din_dr,
    input var  [17:0] din_di,
    input var         din_dv,
    input var         sync_in,
    //
    output var [17:0] dout_dr,
    output var [17:0] dout_di,
    output var        dout_dv,
    output var        sync_out
);

  // x0, x1, x2 -> x0 + x1, x0 - 0.5 * x1, 0.8660j * x2

  localparam signed [35:0] RND = 1 << 15;

  logic signed [17:0] din_dr_d;
  logic signed [17:0] din_di_d;
  logic               din_dv_d;
  logic               sync_in_d;

  logic        [ 1:0] cnt;

  logic signed [17:0] x1r;
  logic signed [17:0] x1i;

  logic signed [17:0] ay1;
  logic signed [17:0] ay2;
  logic signed [17:0] ay3;

  logic signed [35:0] amult;

  logic signed [17:0] by1;
  logic signed [17:0] by2;
  logic signed [17:0] by3;

  logic signed [37:0] bmult;

  function automatic logic signed [17:0] op1(input logic signed [17:0] a,
                                             input logic signed [17:0] b);
    logic signed [18:0] t;
    t = a * 2 - b + 1;
    return $signed(t[18:1]);
  endfunction

  // DSP1

  always_ff @(posedge clk) begin
    ay1 <= din_di;
    ay2 <= ay1;
    ay3 <= ay2;
  end

  // coefficient is -0.866025403784439 as fi(1, 18, 16)
  always_ff @(posedge clk) begin
    amult <= ay3 * -18'sd56756 + RND;
  end

  // DSP2

  always_ff @(posedge clk) begin
    by1 <= din_dr;
    by2 <= by1;
    by3 <= by2;
  end

  // coefficient is 0.866025403784439 as fi(1, 18, 16)
  always_ff @(posedge clk) begin
    bmult <= by3 * 18'sd56756 + RND;
  end

  // BF

  always_ff @(posedge clk) begin
    if (~rst_n) begin
      cnt <= 0;
    end else if (sync_in_d) begin
      cnt <= 1;
    end else if (din_dv_d) begin
      cnt <= cnt == 2 ? 0 : cnt + 1;
    end
  end

  always_ff @(posedge clk) begin
    if (cnt == 0) begin
      x1r <= din_dr_d;
      x1i <= din_di_d;
    end else begin
      // x0 - x1 / 2
      x1r <= op1(x1r, din_dr_d);
      x1i <= op1(x1i, din_di_d);
    end
  end

  always_ff @(posedge clk) begin
    if (cnt == 0) begin
      // 0.8660j * x2
      dout_dr <= amult[33:16];
      dout_di <= bmult[33:16];
    end else if (cnt == 1) begin
      // x0 + x1
      dout_dr <= x1r + din_dr_d;
      dout_di <= x1i + din_di_d;
    end else begin
      dout_dr <= x1r;
      dout_di <= x1i;
    end
  end

  delay #(
      .WIDTH(38),
      .DELAY(3)
  ) u_delay (
      .clk  (clk),
      .rst_n(1'b1),
      .din  ({sync_in, din_dv, din_di, din_dr}),
      .dout ({sync_in_d, din_dv_d, din_di_d, din_dr_d})
  );

  delay #(
      .WIDTH(2),
      .DELAY(5)
  ) u_delay_ctrl (
      .clk  (clk),
      .rst_n(1'b1),
      .din  ({sync_in, din_dv}),
      .dout ({sync_out, dout_dv})
  );

endmodule

`default_nettype wire
