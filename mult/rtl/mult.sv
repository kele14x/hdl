`timescale 1 ns / 1 ps
//
`default_nettype none

module mult #(
    parameter int A_WIDTH  = 16,
    parameter int B_WIDTH  = 16,
    parameter int P_WIDTH  = 16,
    parameter int SHIFT    = 15,
    //
    parameter int ROUND    = 1,
    parameter int SATURATE = 1
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

    assert (SHIFT < FullWidth)
    else begin
      $error("[%m]: SHIFT (%0d) must be smaller than the full width (%0d).", SHIFT, FullWidth);
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

  logic signed [  A_WIDTH-1:0] a_d;
  logic signed [  B_WIDTH-1:0] b_d;
  (* USE_DSP = "YES" *)
  logic signed [FullWidth-1:0] m;
  (* USE_DSP = "YES" *)
  logic signed [FullWidth-1:0] p_full;

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
    m <= a_d * b_d;
  end

  always_ff @(posedge clk) begin
    p_full <= m;
  end

  type_case #(
      .IN_WIDTH (FullWidth),
      .OUT_WIDTH(P_WIDTH),
      .TRUNC    (SHIFT),
      .ROUND    (ROUND),
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
