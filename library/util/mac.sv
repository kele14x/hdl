// File: mac.sv
// Brief: MAC is a simple, portable, and efficient implementation of the
//  Multiply Adder Circuit, which is basic component of DSP related stuff.
`timescale 1 ns / 1 ps
//
`default_nettype none

module mac #(
    // Port width
    parameter int A_WIDTH   = 16,  // 1 ~ 25
    parameter int B_WIDTH   = 16,  // 1 ~ 18
    parameter int C_WIDTH   = 33,  // 1 ~ 48
    parameter int D_WIDTH   = 16,  // 1 ~ 25
    parameter int P_WIDTH   = 34,  // 1 ~ 48
    // Pipeline depth
    parameter int A_REG     = 1,   // 0, 1, 2
    parameter int AD_REG    = 1,   // 0, 1
    parameter int B_REG     = 1,   // 0, 1, 2
    parameter int C_REG     = 1,   // 0, 1
    parameter int D_REG     = 1,   // 0, 1
    parameter int M_REG     = 1,   // 0, 1
    parameter int P_REG     = 1,   // 0, 1
    // Feature control
    parameter int USE_DPORT = 1    // 0, 1
) (
    input var                       clk,
    input var  signed [A_WIDTH-1:0] a,
    input var  signed [B_WIDTH-1:0] b,
    input var  signed [C_WIDTH-1:0] c,
    input var  signed [D_WIDTH-1:0] d,
    output var signed [P_WIDTH-1:0] p
);

  // Local parameters
  //=================

  localparam int ADWidth = USE_DPORT ? (A_WIDTH >= D_WIDTH ? A_WIDTH : D_WIDTH) : A_WIDTH;
  localparam int MWidth = ADWidth + B_WIDTH;
  localparam int PFullWidth = MWidth >= C_WIDTH ? MWidth : C_WIDTH;


  // AD path
  logic signed [A_WIDTH-1:0] reg_a1;
  logic signed [A_WIDTH-1:0] reg_a2;

  logic signed [D_WIDTH-1:0] reg_d1;

  // Pre-adder register
  logic signed [ADWidth -1:0] ad;
  logic signed [ADWidth -1:0] reg_ad;

  // B path
  logic signed [B_WIDTH-1:0] reg_b1;
  logic signed [B_WIDTH-1:0] reg_b2;

  // Multiplier
  logic signed [MWidth-1:0] m;
  logic signed [MWidth-1:0] reg_m1;

  // C path
  logic signed [C_WIDTH-1:0] reg_c1;

  // Adder
  logic signed [PFullWidth-1:0] px;
  logic signed [PFullWidth-1:0] reg_p1;


  // Check parameters

  initial begin
    assert (A_REG >= 0 && A_REG <= 2);
    assert (AD_REG >= 0 && AD_REG <= 1);
    assert (B_REG >= 0 && B_REG <= 2);
    assert (C_REG >= 0 && C_REG <= 1);
    assert (D_REG >= 0 && D_REG <= 1);
    assert (M_REG >= 0 && M_REG <= 1);
    assert (P_REG >= 0 && P_REG <= 1);
  end


  // A path

  generate
    if (A_REG == 0) begin : g_no_a1
      assign reg_a1 = a;
    end else begin : g_a1
      always_ff @(posedge clk) begin
        reg_a1 <= a;
      end
    end
  endgenerate

  generate
    if (A_REG < 2) begin : g_no_a2
      assign reg_a2 = reg_a1;
    end else begin : g_a2
      always_ff @(posedge clk) begin
        reg_a2 <= reg_a1;
      end
    end
  endgenerate


  // D path

  generate
    if (D_REG == 0) begin : g_no_d1
      assign reg_d1 = d;
    end else begin : g_d1
      always_ff @(posedge clk) begin
        reg_d1 <= d;
      end
    end
  endgenerate


  // Pre-adder

  assign ad = reg_d1 + reg_a2;

  generate
    if (USE_DPORT == 0) begin : g_no_pre_adder
      assign reg_ad = reg_a2;
    end else if (AD_REG == 0) begin : g_no_ad
      assign reg_ad = ad;
    end else begin : g_ad
      always_ff @(posedge clk) begin
        reg_ad <= ad;
      end
    end
  endgenerate


  // B path

  generate
    if (B_REG == 0) begin : g_no_b1
      assign reg_b1 = b;
    end else begin : g_b1
      always_ff @(posedge clk) begin
        reg_b1 <= b;
      end
    end
  endgenerate

  generate
    if (B_REG < 2) begin : g_no_b2
      assign reg_b2 = reg_b1;
    end else begin : g_b2
      always_ff @(posedge clk) begin
        reg_b2 <= reg_b1;
      end
    end
  endgenerate


  // Multiplier

  assign m = reg_ad * reg_b2;

  generate
    if (M_REG == 0) begin : g_no_m1
      assign reg_m1 = m;
    end else begin : g_m1
      always_ff @(posedge clk) begin
        reg_m1 <= m;
      end
    end
  endgenerate


  // C path

  generate
    if (C_REG == 0) begin : g_no_c1
      assign reg_c1 = c;
    end else begin : g_c1
      always_ff @(posedge clk) begin
        reg_c1 <= c;
      end
    end
  endgenerate


  // Adder

  assign px = reg_m1 + reg_c1;

  generate
    if (P_REG == 0) begin : g_no_p1
      assign reg_p1 = px;
    end else begin : g_p1
      always_ff @(posedge clk) begin
        reg_p1 <= px;
      end
    end
  endgenerate

  assign p = reg_p1;

endmodule

`default_nettype wire
