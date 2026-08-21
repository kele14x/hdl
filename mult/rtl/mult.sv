`timescale 1 ns / 1 ps
//
`default_nettype none

module mult #(
    parameter int A_WIDTH  = 16,
    parameter int B_WIDTH  = 16,
    parameter int P_WIDTH  = 16,
    parameter int SHIFT    = 15,
    //
    parameter int ROUND    = 0,
    parameter int SATURATE = 0
) (
    input var                       clk,
    input var                       rst,
    //
    input var  signed [A_WIDTH-1:0] a,
    input var  signed [B_WIDTH-1:0] b,
    //
    output var signed [P_WIDTH-1:0] p,
    //
    output var                      ovf
);

  /* verilator lint_off UNUSEDPARAM */
  localparam int Latency = 4;
  /* verilator lint_on UNUSEDPARAM */
  localparam int FullWidth = A_WIDTH + B_WIDTH;

  initial begin : drc_check
    assert (A_WIDTH >= 1)
    else begin
      $error("[%m]: A_WIDTH (%0d) is outside of valid range.", A_WIDTH);
    end

    assert (B_WIDTH >= 1)
    else begin
      $error("[%m]: B_WIDTH (%0d) is outside of valid range.", B_WIDTH);
    end

    assert (P_WIDTH >= 1)
    else begin
      $error("[%m]: P_WIDTH (%0d) is outside of valid range.", P_WIDTH);
    end

    assert (SHIFT >= 0)
    else begin
      $error("[%m]: SHIFT (%0d) is outside of valid range.", SHIFT);
    end

    assert (ROUND == 0 || ROUND == 1)
    else begin
      $error("[%m]: ROUND (%0d) value is outside of valid range.", ROUND);
    end

    assert (SATURATE == 0 || SATURATE == 1)
    else begin
      $error("[%m]: SATURATE (%0d) value is outside of valid range.", SATURATE);
    end
  end

  // Symmetric round-to-nearest, with ties away from zero, can be written as
  //   product + (2**(SHIFT-1) - 1) + product_nonnegative.
  // Keeping the sign correction as a one-bit carry-in allows Vivado to pack
  // the multiply, rounding add, and pipeline registers into a DSP48/DSP58.
  localparam signed [FullWidth-1:0] RoundBias =
      ((ROUND != 0) && (SHIFT > 0)) ? ((1 << (SHIFT - 1)) - 1) : 0;

  logic signed [  A_WIDTH-1:0] a_d;
  logic signed [  B_WIDTH-1:0] b_d;
  (* USE_DSP = "YES" *)
  logic signed [FullWidth-1:0] m;
  (* USE_DSP = "YES" *)
  logic signed [FullWidth-1:0] p_full;
  logic                        product_nonnegative;
  logic                        product_nonnegative_d;

  wire signed  [  P_WIDTH-1:0] p_sat;
  logic signed [  P_WIDTH-1:0] p_reg;

  wire                         ovf_s;
  logic                        ovf_r;

  always_ff @(posedge clk) begin
    a_d <= a;
  end

  always_ff @(posedge clk) begin
    b_d <= b;
  end

  always_ff @(posedge clk) begin
    product_nonnegative <= ~(a[A_WIDTH-1] ^ b[B_WIDTH-1]);
  end

  always_ff @(posedge clk) begin
    m <= a_d * b_d;
  end

  always_ff @(posedge clk) begin
    product_nonnegative_d <= product_nonnegative;
  end

  always_ff @(posedge clk) begin
    /* verilator lint_off WIDTHEXPAND */
    p_full <= m + RoundBias + (((ROUND != 0) && (SHIFT > 0)) ? product_nonnegative_d : 1'b0);
    /* verilator lint_on WIDTHEXPAND */
  end

  type_case #(
      .IN_WIDTH (FullWidth),
      .OUT_WIDTH(P_WIDTH),
      .TRUNC    (SHIFT),
      .SATURATE (SATURATE)
  ) i_type_case (
      .din (p_full),
      .dout(p_sat),
      .ovf (ovf_s)
  );

  always_ff @(posedge clk) begin
    if (rst) begin
      p_reg <= 0;
      ovf_r <= 0;
    end else begin
      p_reg <= p_sat;
      ovf_r <= ovf_s;
    end
  end

  assign p   = p_reg;
  assign ovf = ovf_r;

endmodule

`default_nettype wire
