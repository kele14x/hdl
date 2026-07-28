`timescale 1 ns / 1 ps
//
`default_nettype none

module cmult #(
    parameter int A_WIDTH  = 16,
    parameter int B_WIDTH  = 16,
    parameter int P_WIDTH  = 16,
    parameter int SHIFT    = 15,
    parameter bit ROUND    = 1'b0,
    parameter bit SATURATE = 1'b0
) (
    input  wire                       clk,
    input  wire                       rst,
    //
    input  wire signed [A_WIDTH-1:0]  ar,
    input  wire signed [A_WIDTH-1:0]  ai,
    //
    input  wire signed [B_WIDTH-1:0]  br,
    input  wire signed [B_WIDTH-1:0]  bi,
    //
    output wire signed [P_WIDTH-1:0]  pr,
    output wire signed [P_WIDTH-1:0]  pi,
    //
    output wire                       ovf
);

  cmult4 #(
      .A_WIDTH (A_WIDTH),
      .B_WIDTH (B_WIDTH),
      .P_WIDTH (P_WIDTH),
      .SHIFT   (SHIFT),
      .ROUND   (ROUND),
      .SATURATE(SATURATE)
  ) u_cmult4 (
      .clk(clk),
      .rst(rst),
      //
      .ar (ar),
      .ai (ai),
      //
      .br (br),
      .bi (bi),
      //
      .pr (pr),
      .pi (pi),
      //
      .ovf(ovf)
  );

endmodule

`default_nettype wire
